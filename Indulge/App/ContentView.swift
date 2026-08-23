import Foundation
import SwiftData
import SwiftUI

struct ContentView: View {
  private let platform: HabitsPlatformSync
  private let route: IndulgeLaunchRoute
  private let profileStore: OnboardingProfileStore
  private let authenticationService: any DeviceOwnerAuthenticating
  private let resetsTestingData: Bool
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage(PrivacyLockSettingsStore.enabledKey) private var privacyLockEnabled = false
  @AppStorage(PrivacyLockSettingsStore.relockAfterKey) private var privacyRelockAfter =
    PrivacyLockSettingsStore.defaultRelockAfter
  @Query(sort: \OnboardingProfileRecord.updatedAt, order: .reverse)
  private var profileRecords: [OnboardingProfileRecord]
  @State private var completedProfile: OnboardingProfile?
  @State private var isExistingOwnerOrientation: Bool
  @State private var privacyLifecycle: PrivacyLockLifecycle
  @State private var isAuthenticating = false
  @State private var privacyMessage: String?

  init(
    platform: HabitsPlatformSync = HabitsPlatformSync(enabled: false),
    route: IndulgeLaunchRoute = .launchArguments,
    profileStore: OnboardingProfileStore = OnboardingProfileStore(),
    authenticationService: any DeviceOwnerAuthenticating =
      LocalDeviceOwnerAuthenticationService(),
    resetsTestingData: Bool = ProcessInfo.processInfo.arguments.contains("--reset-testing-data")
  ) {
    self.platform = platform
    self.route = route
    self.profileStore = profileStore
    self.authenticationService = authenticationService
    self.resetsTestingData = resetsTestingData
    let restoredProfile = route == .automatic ? profileStore.load() : nil
    _isExistingOwnerOrientation = State(
      initialValue: route == .automatic
        && restoredProfile != nil
        && !profileStore.hasSeenIllustratedOnboarding
    )
    _completedProfile = State(
      initialValue: route.opensApplication ? .appPreview : restoredProfile
    )
    _privacyLifecycle = State(
      initialValue: PrivacyLockLifecycle(
        enabledAtLaunch: route == .automatic && PrivacyLockSettingsStore().isEnabled
      ))
  }

  var body: some View {
    ZStack {
      Group {
        if route == .review {
          IndulgeReviewView()
        } else if let displayedProfile {
          IndulgeAppShell(
            platform: platform,
            profile: displayedProfile,
            initialTab: initialTab,
            startsWithActiveTrade: route.startsWithActiveTrade,
            startsWithCompletedTrade: route.startsWithCompletedTrade
          )
        } else {
          IndulgeOnboardingView(
            isExistingOwnerOrientation: isExistingOwnerOrientation,
            onCancel: finishExistingOwnerOrientation
          ) { profile in
            if !isExistingOwnerOrientation {
              profileStore.save(profile)
              try? OnboardingProfileRepository(context: modelContext).save(profile)
            }
            profileStore.markIllustratedOnboardingSeen()
            withAnimation(.smooth(duration: 0.55)) {
              if !isExistingOwnerOrientation { completedProfile = profile }
              isExistingOwnerOrientation = false
            }
          }
        }
      }
      .blur(radius: protectsContent ? 24 : 0)
      .allowsHitTesting(!protectsContent)
      .accessibilityHidden(protectsContent)

      if protectsContent {
        PrivacyLockGate(
          isAuthenticating: isAuthenticating,
          message: privacyMessage,
          unlock: unlockProtectedContent
        )
      }
    }
    .task {
      if resetsTestingData {
        try? AllIndulgeDataRepository(
          context: modelContext,
          cardAssets: FutureLifeCardAssetStore()
        ).deleteAll()
        profileStore.delete()
        privacyLockEnabled = false
        privacyLifecycle.privacyLockWasDisabled()
        completedProfile = nil
      }
      if route == .automatic,
        !profileStore.hasSeenIllustratedOnboarding,
        completedProfile != nil || !profileRecords.isEmpty
      {
        isExistingOwnerOrientation = true
      }
      guard route == .automatic, profileRecords.isEmpty, let completedProfile else { return }
      try? OnboardingProfileRepository(context: modelContext).save(completedProfile)
    }
    .task {
      guard route == .automatic else { return }
      await platform.restoreAndSync(context: modelContext)
    }
    .onChange(of: privacyLockEnabled) { _, enabled in
      if enabled {
        privacyLifecycle.privacyLockWasEnabledAfterAuthentication()
      } else {
        privacyLifecycle.privacyLockWasDisabled()
      }
    }
    .onChange(of: scenePhase) { _, phase in
      privacyLifecycle.transition(
        to: phase.privacyLifecyclePhase,
        now: .now,
        enabled: privacyLockEnabled && route == .automatic,
        relockAfter: privacyRelockAfter
      )
      if phase == .active, route == .automatic {
        Task { await platform.synchronize(context: modelContext) }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .indulgeAllDataDeleted)) { _ in
      profileStore.delete()
      completedProfile = nil
      privacyLockEnabled = false
      privacyLifecycle.privacyLockWasDisabled()
    }
  }

  private var protectsContent: Bool {
    route == .automatic && privacyLockEnabled && privacyLifecycle.isObscured
  }

  private func unlockProtectedContent() {
    guard !isAuthenticating else { return }
    guard authenticationService.availability == .available else {
      privacyLockEnabled = false
      privacyLifecycle.privacyLockWasDisabled()
      privacyMessage =
        "Device authentication is unavailable, so Privacy Lock was turned off to prevent a lockout."
      return
    }

    isAuthenticating = true
    privacyMessage = nil
    Task { @MainActor in
      let outcome = await authenticationService.authenticate(
        reason: "Unlock your private Habits profile, trades, and history."
      )
      privacyLifecycle.authenticationCompleted(outcome)
      isAuthenticating = false
      if outcome != .authenticated {
        privacyMessage = "Still locked. Try again when you’re ready."
      }
    }
  }

  private var displayedProfile: OnboardingProfile? {
    if isExistingOwnerOrientation { return nil }
    if route.opensApplication { return completedProfile }
    guard route == .automatic else { return completedProfile }
    return completedProfile ?? profileRecords.first?.profile
  }

  private func finishExistingOwnerOrientation() {
    profileStore.markIllustratedOnboardingSeen()
    isExistingOwnerOrientation = false
  }

  private var initialTab: IndulgeAppTab {
    route.initialTab
  }
}

private struct PrivacyLockGate: View {
  let isAuthenticating: Bool
  let message: String?
  let unlock: () -> Void

  var body: some View {
    VStack(spacing: 18) {
      Image(systemName: "lock.fill")
        .font(.system(size: 34, weight: .semibold))
        .foregroundStyle(Color.indulgeCherry)
      VStack(spacing: 7) {
        Text("Habits is locked")
          .font(.indulgeDisplay)
          .foregroundStyle(Color.indulgeText)
        Text(message ?? "Authenticate with this device to see your private history.")
          .font(.indulgeBody)
          .foregroundStyle(Color.indulgeText.opacity(0.68))
          .multilineTextAlignment(.center)
      }
      Button(isAuthenticating ? "Authenticating…" : "Unlock", action: unlock)
        .buttonStyle(.borderedProminent)
        .tint(Color.indulgeNavy)
        .disabled(isAuthenticating)
    }
    .padding(28)
    .frame(maxWidth: 420)
    .background(Color.indulgeSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.indulgePaleBorder)
    )
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.indulgePowderSoft)
  }
}

extension SwiftUI.ScenePhase {
  fileprivate var privacyLifecyclePhase: PrivacyLifecyclePhase {
    if self == SwiftUI.ScenePhase.active { return .active }
    if self == SwiftUI.ScenePhase.background { return .background }
    return .inactive
  }
}

enum IndulgeLaunchRoute: Equatable, Sendable {
  case automatic
  case onboarding
  case application(tab: IndulgeAppTab, activeTrade: Bool)
  case completedHistory
  case review

  static var launchArguments: Self {
    resolve(arguments: ProcessInfo.processInfo.arguments)
  }

  static func resolve(arguments: [String]) -> Self {
    if arguments.contains("--review") { return .review }
    if arguments.contains(where: { $0.hasPrefix("--app-focus") }) {
      return .application(tab: .life, activeTrade: false)
    }
    if arguments.contains("--app-trade-active") {
      return .application(tab: .trade, activeTrade: true)
    }
    if arguments.contains("--app-trade") { return .application(tab: .trade, activeTrade: false) }
    if arguments.contains("--app-history-complete") { return .completedHistory }
    if arguments.contains("--app-history") {
      return .application(tab: .history, activeTrade: false)
    }
    if arguments.contains("--app-life") { return .application(tab: .life, activeTrade: false) }
    if arguments.contains("--onboarding") { return .onboarding }
    return .automatic
  }

  var opensApplication: Bool {
    if case .application = self { return true }
    if self == .completedHistory { return true }
    return false
  }

  var initialTab: IndulgeAppTab {
    if case .application(let tab, _) = self { return tab }
    if self == .completedHistory { return .history }
    return .life
  }

  var startsWithActiveTrade: Bool {
    if case .application(_, let activeTrade) = self { return activeTrade }
    return false
  }

  var startsWithCompletedTrade: Bool {
    self == .completedHistory
  }
}

struct OnboardingProfileStore {
  private static let key = "completed-onboarding-profile-v1"
  private static let illustratedOnboardingSeenKey = "habits.illustrated-onboarding.seen.v1"
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func load() -> OnboardingProfile? {
    guard let data = defaults.data(forKey: Self.key) else { return nil }
    return try? JSONDecoder().decode(OnboardingProfile.self, from: data)
  }

  func save(_ profile: OnboardingProfile) {
    guard let data = try? JSONEncoder().encode(profile) else { return }
    defaults.set(data, forKey: Self.key)
  }

  func delete() {
    defaults.removeObject(forKey: Self.key)
  }

  var hasSeenIllustratedOnboarding: Bool {
    defaults.bool(forKey: Self.illustratedOnboardingSeenKey)
  }

  func markIllustratedOnboardingSeen() {
    defaults.set(true, forKey: Self.illustratedOnboardingSeenKey)
  }
}

extension Notification.Name {
  static let indulgeAllDataDeleted = Notification.Name("indulge-all-data-deleted")
}

#Preview("Onboarding") {
  ContentView(route: .onboarding)
}

#Preview("Life") {
  ContentView(route: .application(tab: .life, activeTrade: false))
}
