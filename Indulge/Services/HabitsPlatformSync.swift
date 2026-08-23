import CryptoKit
import Foundation
import Observation
import PersonalSyncKit
import SwiftData

enum HabitsHubSyncFailure: Equatable {
  case authenticationRequired
  case networkUnavailable
  case serviceUnavailable

  static func classify(_ error: any Error) -> Self {
    if let syncError = error as? PersonalSyncError,
      case .server(let status, _) = syncError,
      status == 401 || status == 403
    {
      return .authenticationRequired
    }

    if let identityError = error as? PersonalIdentityError {
      switch identityError {
      case .missingSession, .keychain:
        return .authenticationRequired
      case .server(let status, _) where status == 401 || status == 403:
        return .authenticationRequired
      case .invalidResponse, .server:
        return .serviceUnavailable
      }
    }

    if let urlError = error as? URLError {
      switch urlError.code {
      case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
        .cannotConnectToHost, .dnsLookupFailed, .internationalRoamingOff, .dataNotAllowed:
        return .networkUnavailable
      default:
        return .serviceUnavailable
      }
    }

    return .serviceUnavailable
  }
}

struct HabitsHubSyncStatus: Equatable {
  var isSyncing = false
  var lastSuccessfulSyncAt: Date?
  var pendingMutationCount = 0
  var failure: HabitsHubSyncFailure?

  var retryNeeded: Bool { pendingMutationCount > 0 || failure != nil }

  var summary: String {
    if isSyncing { return "Syncing completed trades with Hub…" }

    let pendingDescription = switch pendingMutationCount {
    case 0: "No completed trades are waiting to upload."
    case 1: "1 completed trade is waiting safely on this device."
    default: "\(pendingMutationCount) completed trades are waiting safely on this device."
    }

    switch failure {
    case .authenticationRequired:
      return
        "Your Hub session needs attention. Sign out, then reconnect to continue syncing. \(pendingDescription)"
    case .networkUnavailable:
      return "No network connection. \(pendingDescription) Habits will retry when you reconnect."
    case .serviceUnavailable:
      return "Hub could not complete the sync. \(pendingDescription) Try again."
    case nil:
      guard let lastSuccessfulSyncAt else {
        return "Not synced with Hub yet. \(pendingDescription)\(retryGuidance)"
      }
      return
        "Last Hub sync: \(lastSuccessfulSyncAt.formatted(date: .abbreviated, time: .shortened)). \(pendingDescription)\(retryGuidance)"
    }
  }

  private var retryGuidance: String {
    pendingMutationCount > 0 ? " Habits will retry automatically; you can also use Sync now." : ""
  }
}

enum HabitsSyncCopy {
  static let appleContinuity =
    "Supported signed builds may use your private iCloud database for continuity across Apple devices signed into your iCloud account. This is separate from Hub."
  static let hubScope =
    "Habits sends completed trades to your private Hub and can receive completed Hub check-ins into History. Your profile, active trade, reflections, and generated card are not sent to Hub."
}

@MainActor
@Observable
final class HabitsPlatformSync {
  private static let lastSuccessfulSyncKey = "habits-hub-last-successful-sync"

  private let connection: PersonalPlatformConnection?
  private let defaults: UserDefaults
  private let now: () -> Date
  let account: PersonalAccountModel?
  private(set) var status: HabitsHubSyncStatus

  var isSyncing: Bool { status.isSyncing }

  init(
    enabled: Bool,
    defaults: UserDefaults = .standard,
    now: @escaping () -> Date = Date.init
  ) {
    self.defaults = defaults
    self.now = now
    status = HabitsHubSyncStatus(
      lastSuccessfulSyncAt: defaults.object(forKey: Self.lastSuccessfulSyncKey) as? Date
    )

    guard enabled else {
      connection = nil
      account = nil
      return
    }

    let defaults = UserDefaults.standard
    let deviceKey = "personal-platform-device-id"
    let deviceId = defaults.string(forKey: deviceKey) ?? UUID().uuidString.lowercased()
    defaults.set(deviceId, forKey: deviceKey)
    let supportDirectory = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first!
    let connection = try? PersonalPlatformConnection(
      domain: .habits,
      keychainService: "com.significanthobbies.indulge",
      supportDirectory: supportDirectory,
      deviceId: deviceId
    )
    self.connection = connection
    account = connection.map {
      PersonalAccountModel(identity: $0.identity, callbackScheme: "habits")
    }
  }

  func restoreAndSync(context: ModelContext) async {
    await account?.restore()
    await synchronize(context: context)
  }

  func synchronize(context: ModelContext, announcing: Bool = false) async {
    guard let connection, !status.isSyncing else { return }
    guard account?.isSignedIn == true else {
      await refreshPendingCount(using: connection)
      if announcing { status.failure = .authenticationRequired }
      return
    }

    status.isSyncing = true
    status.failure = nil
    defer { status.isSyncing = false }
    do {
      try await enqueueCompletedTrades(context: context, using: connection)
      let changes = try await connection.sync.synchronize()
      try apply(changes, context: context)
      await recordSuccessfulSync(using: connection)
    } catch {
      await recordFailedSync(error, using: connection)
    }
  }

  func enqueue(_ record: TradeRecord) {
    guard let connection, let completedAt = record.completedAt else { return }
    let recordId = record.id.uuidString.lowercased()
    let occurredAt = Self.iso(completedAt)
    let payload = HabitsPlatformRecord.encode(record)
    Task {
      do {
        try await connection.sync.enqueue(
          recordId: recordId,
          occurredAt: occurredAt,
          record: payload
        )
        await synchronizeQueuedChanges(using: connection)
      } catch {
        await recordFailedSync(error, using: connection)
      }
    }
  }

  func delete(recordIDs: [UUID]) {
    guard let connection, !recordIDs.isEmpty else { return }
    Task {
      for id in recordIDs {
        try? await connection.sync.enqueue(
          recordId: id.uuidString.lowercased(),
          operation: .delete,
          occurredAt: Self.iso(.now)
        )
      }
      await synchronizeQueuedChanges(using: connection)
    }
  }

  private func synchronizeQueuedChanges(using connection: PersonalPlatformConnection) async {
    await refreshPendingCount(using: connection)
    guard account?.isSignedIn == true, !status.isSyncing else { return }

    status.isSyncing = true
    status.failure = nil
    defer { status.isSyncing = false }
    do {
      _ = try await connection.sync.synchronize()
      await recordSuccessfulSync(using: connection)
    } catch {
      await recordFailedSync(error, using: connection)
    }
  }

  private func recordSuccessfulSync(using connection: PersonalPlatformConnection) async {
    let completedAt = now()
    status.lastSuccessfulSyncAt = completedAt
    status.pendingMutationCount = await connection.sync.pendingMutationCount()
    status.failure = nil
    defaults.set(completedAt, forKey: Self.lastSuccessfulSyncKey)
  }

  private func recordFailedSync(
    _ error: any Error,
    using connection: PersonalPlatformConnection
  ) async {
    status.pendingMutationCount = await connection.sync.pendingMutationCount()
    status.failure = HabitsHubSyncFailure.classify(error)
  }

  private func refreshPendingCount(using connection: PersonalPlatformConnection) async {
    status.pendingMutationCount = await connection.sync.pendingMutationCount()
  }

  private func enqueueCompletedTrades(
    context: ModelContext,
    using connection: PersonalPlatformConnection
  ) async throws {
    for record in try context.fetch(FetchDescriptor<TradeRecord>()) {
      guard let completedAt = record.completedAt else { continue }
      try await connection.sync.enqueue(
        recordId: record.id.uuidString.lowercased(),
        occurredAt: Self.iso(completedAt),
        record: HabitsPlatformRecord.encode(record)
      )
    }
  }

  private func apply(_ changes: [SyncChange], context: ModelContext) throws {
    let existing = try context.fetch(FetchDescriptor<TradeRecord>())
    for change in changes {
      let id = HabitsPlatformRecord.stableUUID(change.id)
      if change.operation == .delete {
        if let record = existing.first(where: { $0.id == id }) { context.delete(record) }
        continue
      }
      guard !existing.contains(where: { $0.id == id }),
        let record = HabitsPlatformRecord.decode(change)
      else { continue }
      context.insert(record)
    }
    if context.hasChanges { try context.save() }
  }

  private static func iso(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }
}

enum HabitsPlatformRecord {
  static func encode(_ record: TradeRecord) -> JSONValue {
    let outcome = record.outcome?.rawValue ?? TradeOutcome.anotherDay.rawValue
    let habitId = [
      "trade",
      record.indulgenceRawValue,
      record.destinationRawValue,
      String(record.reclaimMinutes),
      outcome,
    ].joined(separator: "|")
    return .object([
      "habitId": .string(habitId),
      "name": .string("\(record.indulgence.title) → \(record.destination.title)"),
      "occurredOn": .string(
        ISO8601DateFormatter().string(from: record.completedAt ?? record.updatedAt)),
      "status": .string(record.outcome == .madeRoom ? "completed" : "skipped"),
    ])
  }

  static func decode(_ change: SyncChange) -> TradeRecord? {
    guard case .object(let record) = change.record,
      case .string(let habitId)? = record["habitId"],
      case .string(let occurredOn)? = record["occurredOn"],
      let occurredAt = ISO8601DateFormatter().date(from: occurredOn)
    else { return nil }
    let parts = habitId.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
    let indulgence = parts.count > 1 ? IndulgenceChoice(rawValue: parts[1]) : nil
    let destination = parts.count > 2 ? LifeDirection(rawValue: parts[2]) : nil
    let minutes = parts.count > 3 ? Int(parts[3]) : nil
    let outcome = parts.count > 4 ? TradeOutcome(rawValue: parts[4]) : nil
    return TradeRecord(
      id: stableUUID(change.id),
      indulgence: indulgence ?? .television,
      reclaimTarget: ReclaimTarget(rawValue: minutes ?? 15) ?? .fifteen,
      destination: destination ?? .presence,
      createdAt: occurredAt,
      startedAt: occurredAt,
      completedAt: occurredAt,
      outcome: outcome ?? statusOutcome(record["status"])
    )
  }

  static func stableUUID(_ value: String) -> UUID {
    if let uuid = UUID(uuidString: value) { return uuid }
    let bytes = Array(SHA256.hash(data: Data(value.utf8)).prefix(16))
    return UUID(
      uuid: (
        bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
      ))
  }

  private static func statusOutcome(_ value: JSONValue?) -> TradeOutcome {
    guard case .string(let status)? = value else { return .madeRoom }
    return status == "completed" ? .madeRoom : .anotherDay
  }
}
