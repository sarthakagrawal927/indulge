import Foundation
import PersonalSyncKit
import XCTest

@testable import Indulge

final class HabitsPlatformRecordTests: XCTestCase {
  func testSyncCopySeparatesAppleContinuityFromHubScope() {
    XCTAssertTrue(HabitsSyncCopy.appleContinuity.contains("private iCloud database"))
    XCTAssertTrue(HabitsSyncCopy.appleContinuity.contains("separate from Hub"))
    XCTAssertTrue(HabitsSyncCopy.hubScope.contains("sends completed trades"))
    XCTAssertTrue(HabitsSyncCopy.hubScope.contains("receive completed Hub check-ins"))
    XCTAssertTrue(HabitsSyncCopy.hubScope.contains("active trade"))
  }

  func testSyncStatusSurfacesLastSuccessAndPendingCount() throws {
    let completedAt = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-23T08:30:00Z"))
    let status = HabitsHubSyncStatus(
      lastSuccessfulSyncAt: completedAt,
      pendingMutationCount: 2
    )

    XCTAssertTrue(status.summary.contains("Last Hub sync:"))
    XCTAssertTrue(status.summary.contains("2 completed trades are waiting safely on this device"))
    XCTAssertTrue(status.retryNeeded)
    XCTAssertTrue(status.summary.contains("retry automatically"))
  }

  func testSyncStatusSurfacesInProgressAndRetryNeededStates() {
    XCTAssertEqual(
      HabitsHubSyncStatus(isSyncing: true).summary,
      "Syncing completed trades with Hub…"
    )
    XCTAssertEqual(
      HabitsHubSyncStatus(
        pendingMutationCount: 1,
        failure: .networkUnavailable
      ).summary,
      "No network connection. 1 completed trade is waiting safely on this device. Habits will retry when you reconnect."
    )
  }

  @MainActor
  func testSyncStatusRestoresLastSuccessAcrossLaunches() throws {
    let defaults = try XCTUnwrap(UserDefaults(suiteName: #function))
    defaults.removePersistentDomain(forName: #function)
    let completedAt = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-23T08:30:00Z"))
    defaults.set(completedAt, forKey: "habits-hub-last-successful-sync")

    let platform = HabitsPlatformSync(enabled: false, defaults: defaults)

    XCTAssertEqual(platform.status.lastSuccessfulSyncAt, completedAt)
    defaults.removePersistentDomain(forName: #function)
  }

  func testSyncFailureClassificationDistinguishesAuthNetworkAndService() {
    XCTAssertEqual(
      HabitsHubSyncFailure.classify(
        PersonalSyncError.server(status: 401, message: "expired")
      ),
      .authenticationRequired
    )
    XCTAssertEqual(
      HabitsHubSyncFailure.classify(URLError(.notConnectedToInternet)),
      .networkUnavailable
    )
    XCTAssertEqual(
      HabitsHubSyncFailure.classify(
        PersonalSyncError.server(status: 503, message: "unavailable")
      ),
      .serviceUnavailable
    )
  }

  func testCompletedTradeUsesTheHabitsContract() throws {
    let completedAt = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-21T08:30:00Z"))
    let record = TradeRecord(
      indulgence: .socialFeeds,
      reclaimTarget: .thirty,
      destination: .movement,
      createdAt: completedAt.addingTimeInterval(-1_800),
      startedAt: completedAt.addingTimeInterval(-1_800),
      completedAt: completedAt,
      outcome: .madeRoom
    )

    guard case .object(let payload) = HabitsPlatformRecord.encode(record) else {
      return XCTFail("Expected an object record")
    }
    XCTAssertEqual(
      payload["habitId"],
      .string("trade|socialFeeds|movement|30|madeRoom")
    )
    XCTAssertEqual(payload["occurredOn"], .string("2026-08-21T08:30:00Z"))
    XCTAssertEqual(payload["status"], .string("completed"))
  }

  func testPlatformRecordRecreatesTheTradeAndStableIdentity() throws {
    let change = try decodeChange(
      id: "pace-trade",
      record: """
        {"habitId":"trade|shortVideo|creativity|45|anotherDay","name":"A trade","occurredOn":"2026-08-21T09:00:00Z","status":"skipped"}
        """
    )

    let first = try XCTUnwrap(HabitsPlatformRecord.decode(change))
    let second = try XCTUnwrap(HabitsPlatformRecord.decode(change))
    XCTAssertEqual(first.id, second.id)
    XCTAssertEqual(first.indulgence, .shortVideo)
    XCTAssertEqual(first.destination, .creativity)
    XCTAssertEqual(first.reclaimTarget, .fortyFive)
    XCTAssertEqual(first.outcome, .anotherDay)
  }

  func testGenericCheckInFallsBackToAUsefulHistoryRecord() throws {
    let change = try decodeChange(
      id: "generic-check-in",
      record: """
        {"habitId":"walk","name":"Walk","occurredOn":"2026-08-21T10:00:00Z","status":"completed"}
        """
    )
    let record = try XCTUnwrap(HabitsPlatformRecord.decode(change))
    XCTAssertEqual(record.indulgence, .television)
    XCTAssertEqual(record.destination, .presence)
    XCTAssertEqual(record.outcome, .madeRoom)
  }

  private func decodeChange(id: String, record: String) throws -> SyncChange {
    let payload = """
      {"cursor":1,"changeId":"change-1","domain":"habits","id":"\(id)","operation":"upsert","version":1,"occurredAt":"2026-08-21T10:00:00Z","recordedAt":"2026-08-21T10:00:01Z","originDeviceId":"pace","record":\(record)}
      """
    return try JSONDecoder().decode(SyncChange.self, from: Data(payload.utf8))
  }
}
