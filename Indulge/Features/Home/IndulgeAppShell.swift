import AuthenticationServices
import PersonalSyncKit
import SwiftData
import SwiftUI
import UIKit

enum IndulgeAppTab: String, CaseIterable, Equatable, Sendable {
  case life
  case trade
  case history

  var title: String {
    switch self {
    case .life: "Life"
    case .trade: "Trade"
    case .history: "History"
    }
  }

  var icon: String {
    switch self {
    case .life: "house.fill"
    case .trade: "arrow.left.arrow.right"
    case .history: "clock.fill"
    }
  }
}

struct IndulgeAppShell: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \TradeRecord.updatedAt, order: .reverse) private var tradeRecords: [TradeRecord]
  let platform: HabitsPlatformSync
  let profile: OnboardingProfile
  private let startsWithActiveTrade: Bool
  private let startsWithCompletedTrade: Bool
  @State private var selectedTab: IndulgeAppTab
  @State private var didPrepareStore = false

  init(
    platform: HabitsPlatformSync = HabitsPlatformSync(enabled: false),
    profile: OnboardingProfile, initialTab: IndulgeAppTab = .life,
    startsWithActiveTrade: Bool = false,
    startsWithCompletedTrade: Bool = false
  ) {
    self.platform = platform
    self.profile = profile
    self.startsWithActiveTrade = startsWithActiveTrade
    self.startsWithCompletedTrade = startsWithCompletedTrade
    _selectedTab = State(initialValue: initialTab)
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      LifeHomeView(platform: platform, profile: profile, activeTrade: activeTrade) {
        selectedTab = .trade
      }
      .tag(IndulgeAppTab.life)
      .tabItem { Label(IndulgeAppTab.life.title, systemImage: IndulgeAppTab.life.icon) }

      TradeHomeView(platform: platform, profile: profile, activeRecord: activeRecord)
        .tag(IndulgeAppTab.trade)
        .tabItem { Label(IndulgeAppTab.trade.title, systemImage: IndulgeAppTab.trade.icon) }

      HistoryHomeView(
        profile: profile,
        activeTrade: activeTrade,
        completedRecords: completedRecords
      ) {
        selectedTab = .trade
      }
      .tag(IndulgeAppTab.history)
      .tabItem { Label(IndulgeAppTab.history.title, systemImage: IndulgeAppTab.history.icon) }
    }
    .tint(Color.indulgeCherry)
    .toolbarBackground(.visible, for: .tabBar)
    .toolbarBackground(Color.indulgeSurface, for: .tabBar)
    .task {
      guard !didPrepareStore else { return }
      didPrepareStore = true
      do {
        let repository = TradeRepository(context: modelContext)
        let retained = try repository.active()
        if retained == nil,
          startsWithActiveTrade,
          let suggested = Self.makeSuggestedTrade(for: profile)
        {
          try repository.create(
            indulgence: suggested.indulgence,
            reclaimTarget: suggested.reclaimTarget,
            destination: suggested.destination,
            at: suggested.createdAt
          )
        }
        if startsWithCompletedTrade, try repository.completed().isEmpty,
          let suggested = Self.makeSuggestedTrade(for: profile)
        {
          let record = try repository.create(
            indulgence: suggested.indulgence,
            reclaimTarget: suggested.reclaimTarget,
            destination: suggested.destination,
            replacingActive: retained != nil,
            at: suggested.createdAt
          )
          try repository.begin(record, at: suggested.createdAt.addingTimeInterval(1))
          try repository.complete(
            record,
            outcome: .madeRoom,
            at: suggested.createdAt.addingTimeInterval(2)
          )
        }
      } catch {
        // The visible product remains usable; Trade surfaces any subsequent write error.
      }
    }
  }

  private var activeRecord: TradeRecord? {
    tradeRecords.first(where: \.isActive)
  }

  private var activeTrade: ActiveTrade? {
    activeRecord?.activeValue
  }

  private var completedRecords: [TradeRecord] {
    tradeRecords
      .filter { $0.completedAt != nil && $0.supersededAt == nil }
      .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
  }

  static func makeSuggestedTrade(for profile: OnboardingProfile) -> ActiveTrade? {
    guard let indulgence = profile.primaryIndulgence else { return nil }
    let destination =
      LifeDirection.allCases.first(where: profile.lifeDirections.contains) ?? .presence
    return ActiveTrade(
      id: UUID(),
      indulgence: indulgence,
      reclaimTarget: .suggested(for: profile.dailyTime),
      destination: destination,
      createdAt: .now,
      startedAt: nil
    )
  }
}

private struct LifeHomeView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  let platform: HabitsPlatformSync
  let profile: OnboardingProfile
  let activeTrade: ActiveTrade?
  let openTrade: () -> Void
  @State private var showsAbout = false

  var body: some View {
    GeometryReader { viewport in
      NavigationStack {
        ScrollView {
          VStack(spacing: 0) {
            Button(action: openTrade) {
              ZStack(alignment: .bottomTrailing) {
                IndulgeSceneHeader(profile: profile, title: greeting, height: sceneHeaderHeight)

                LinearGradient(
                  colors: [.clear, Color.indulgeNavy.opacity(0.58)],
                  startPoint: .top,
                  endPoint: .bottom
                )
                .frame(height: 112)
                .allowsHitTesting(false)

                Label("Tap the room when it starts", systemImage: "hand.tap.fill")
                  .font(.indulgeLabel)
                  .foregroundStyle(.white)
                  .shadow(color: Color.indulgeNavy.opacity(0.55), radius: 8, y: 3)
                  .padding(.horizontal, 20)
                  .padding(.bottom, 38)
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(InteractiveSceneButtonStyle())
            .accessibilityLabel("Shape this indulgence")
            .accessibilityHint(
              "Opens a trade for \(profile.primaryIndulgence?.title.lowercased() ?? "your selected indulgence")"
            )

            VStack(alignment: .leading, spacing: 24) {
              VStack(alignment: .leading, spacing: 8) {
                Text("Your life, taking shape.")
                  .font(dynamicTypeSize.isAccessibilitySize ? .indulgeTitle : .indulgeDisplay)
                  .foregroundStyle(Color.indulgeText)
                  .fixedSize(horizontal: false, vertical: true)

                Text(patternSentence)
                  .font(.indulgeBody)
                  .foregroundStyle(Color.indulgeText.opacity(0.68))
                  .fixedSize(horizontal: false, vertical: true)
              }

              if let activeTrade {
                activeTradeSummary(activeTrade)
              } else {
                firstTradeInvitation
              }

              if !profile.lifeDirections.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                  Text("Making room for")
                    .font(.indulgeLabel)
                    .foregroundStyle(Color.indulgeText.opacity(0.58))

                  FlowingDirectionRow(directions: profile.lifeDirections)
                }
              }

              if #available(iOS 18.1, *) {
                FutureLifeCardSection(profile: profile)
              }

            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
            .padding(.bottom, 112)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
            .background(Color.indulgeSurface)
            .clipShape(
              UnevenRoundedRectangle(
                topLeadingRadius: 30, bottomLeadingRadius: 0, bottomTrailingRadius: 0,
                topTrailingRadius: 30, style: .continuous)
            )
            .offset(y: -22)
          }
          .frame(width: viewport.size.width)
        }
        .background(Color.indulgePowderSoft)
        .ignoresSafeArea(edges: horizontalSizeClass == .compact ? .top : [])
        .scrollIndicators(.visible)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              showsAbout = true
            } label: {
              Image(systemName: "gearshape.circle")
                .font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(Color.indulgeText)
            .accessibilityLabel("Privacy and data settings")
          }
        }
        .sheet(isPresented: $showsAbout) {
          IndulgeAboutView(platform: platform)
        }
      }
    }
  }

  private var greeting: String {
    profile.displayName == "you" ? "Your room" : "\(profile.displayName)’s room"
  }

  private var sceneHeaderHeight: CGFloat {
    dynamicTypeSize.isAccessibilitySize ? 280 : 380
  }

  private var patternSentence: String {
    let indulgence = profile.primaryIndulgence?.title ?? "Your chosen indulgence"
    if let time = profile.dailyTime {
      return
        "\(indulgence) can hold \(time.reflectionText) of an ordinary day. Nothing here asks you to give it all up."
    }
    return "\(indulgence) is the first pattern you chose to understand."
  }

  private var firstTradeInvitation: some View {
    VStack(alignment: .leading, spacing: 15) {
      HStack(alignment: .top, spacing: 14) {
        Image(systemName: "arrow.left.arrow.right")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(Color.indulgeCherry)
          .frame(width: 42, height: 42)
          .background(Color.indulgeCherry.opacity(0.09), in: Circle())

        VStack(alignment: .leading, spacing: 4) {
          Text("Make your first trade")
            .font(.indulgeTitle)
            .foregroundStyle(Color.indulgeText)
          Text("Keep the pleasure. Choose one small pocket of time to take back.")
            .font(.indulgeBody)
            .foregroundStyle(Color.indulgeText.opacity(0.64))
        }
      }

      Button("Create my first trade", action: openTrade)
        .buttonStyle(IndulgePrimaryLightButtonStyle())
    }
    .padding(18)
    .background(Color.indulgePowderSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.indulgePaleBorder))
  }

  private func activeTradeSummary(_ trade: ActiveTrade) -> some View {
    HStack(spacing: 14) {
      TradeArtworkImage(assetName: trade.destination.artworkAssetName)
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

      VStack(alignment: .leading, spacing: 3) {
        Text("Your first trade is ready")
          .font(.indulgeTitle)
          .foregroundStyle(Color.indulgeText)
        Text(
          "Keep \(trade.indulgence.title.lowercased()); guide \(trade.reclaimTarget.title.lowercased()) toward \(trade.destination.title.lowercased()) when it starts running on its own."
        )
        .font(.indulgeBody)
        .foregroundStyle(Color.indulgeText.opacity(0.64))
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Color.indulgeCherry.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(
        Color.indulgeCherry.opacity(0.36)))
  }
}

private struct IndulgeAboutView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  let platform: HabitsPlatformSync
  @AppStorage(PrivacyLockSettingsStore.enabledKey) private var privacyLockEnabled = false
  @AppStorage(PrivacyLockSettingsStore.relockAfterKey) private var privacyRelockAfter =
    PrivacyLockSettingsStore.defaultRelockAfter
  @State private var isUpdatingPrivacyLock = false
  @State private var privacyMessage: String?
  @State private var confirmsDataDeletion = false
  private let authenticationService: any DeviceOwnerAuthenticating =
    LocalDeviceOwnerAuthenticationService()

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Keep the pleasure. Reclaim the time.")
              .font(.indulgeTitle)
              .foregroundStyle(Color.indulgeText)
            Text(
              "Your profile, trades, and reflections are local-first. Habits stays usable without an account or network connection."
            )
            .font(.indulgeBody)
            .foregroundStyle(Color.indulgeText.opacity(0.68))
          }
          .padding(.vertical, 6)
        }

        Section("About") {
          Button {
            dismiss()
            NotificationCenter.default.post(name: .indulgeReplayOnboarding, object: nil)
          } label: {
            Label("Replay onboarding", systemImage: "sparkles")
          }
          Link(
            "Privacy",
            destination: URL(string: "https://habits.significanthobbies.com/privacy/")!)
          Link(
            "Support",
            destination: URL(string: "https://habits.significanthobbies.com/support/")!)
        }

        Section("Your data") {
          Button("Delete all Habits data", role: .destructive) {
            confirmsDataDeletion = true
          }
          Text(
            "Deletes your profile, trades, reflections, and generated card. This cannot be undone."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }

        Section("Apple device continuity") {
          Text(HabitsSyncCopy.appleContinuity)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        if let account = platform.account {
          Section("Significant Hobbies Hub") {
            if account.isSignedIn {
              Label(
                account.session?.email ?? "Hub connected",
                systemImage: "person.crop.circle.badge.checkmark"
              )
              Button(platform.isSyncing ? "Syncing…" : "Sync now") {
                Task { await platform.synchronize(context: modelContext, announcing: true) }
              }
              .disabled(platform.isSyncing)
              Button("Sign out", role: .destructive) {
                Task { await account.signOut() }
              }
            } else {
              SignInWithAppleButton(.continue) { request in
                account.prepareApple(request)
              } onCompletion: { result in
                Task {
                  await account.completeApple(result)
                  if account.isSignedIn {
                    await platform.synchronize(context: modelContext, announcing: true)
                  }
                }
              }
              .signInWithAppleButtonStyle(.black)
              .frame(minHeight: 46)
              .disabled(account.isConnecting)

              Button("Continue with Google") {
                Task {
                  await account.connect()
                  await platform.synchronize(context: modelContext, announcing: true)
                }
              }
              .buttonStyle(.borderedProminent)
              .frame(maxWidth: .infinity)
              .disabled(account.isConnecting)
            }

            Text(HabitsSyncCopy.hubScope)
              .font(.footnote)
              .foregroundStyle(.secondary)

            Text(
              account.isSignedIn
                ? platform.status.summary
                : account.errorMessage
                  ?? "Connect to make completed trades privately visible in Hub."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("hub-sync-status")
          }
        }

        Section("Privacy Lock") {
          Toggle(
            "Require device authentication",
            isOn: Binding(
              get: { privacyLockEnabled },
              set: { requested in updatePrivacyLock(requested) }
            )
          )
          .disabled(
            isUpdatingPrivacyLock
              || (!privacyLockEnabled && authenticationService.availability == .unavailable)
          )

          if privacyLockEnabled {
            Picker("Lock after leaving", selection: $privacyRelockAfter) {
              Text("Immediately").tag(TimeInterval(0))
              Text("1 minute").tag(TimeInterval(60))
              Text("5 minutes").tag(TimeInterval(300))
            }
          }

          Text(
            authenticationService.availability == .available
              ? "Uses Face ID, Touch ID, or your device passcode. Habits stores no biometric data."
              : "Set up a device passcode or biometric authentication to use Privacy Lock."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Habits")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .presentationDetents([.large])
    .tint(Color.indulgeCherry)
    .alert("Privacy Lock", isPresented: privacyMessageBinding) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(privacyMessage ?? "Please try again.")
    }
    .confirmationDialog(
      "Delete all Habits data?",
      isPresented: $confirmsDataDeletion,
      titleVisibility: .visible
    ) {
      Button("Delete all data", role: .destructive, action: deleteAllData)
      Button("Keep my data", role: .cancel) {}
    } message: {
      Text(
        "This removes local records and asks configured iCloud continuity and connected Hub sync to remove synchronized copies. Hub deletion applies to completed trades only."
      )
    }
  }

  private func updatePrivacyLock(_ requested: Bool) {
    guard !isUpdatingPrivacyLock else { return }
    isUpdatingPrivacyLock = true
    Task { @MainActor in
      let outcome = await PrivacyLockSettingsController(
        authentication: authenticationService,
        store: PrivacyLockSettingsStore()
      ).setEnabled(requested)
      privacyLockEnabled = PrivacyLockSettingsStore().isEnabled
      isUpdatingPrivacyLock = false

      if requested, outcome != .authenticated {
        privacyMessage =
          authenticationService.availability == .unavailable
          ? "Device authentication is unavailable, so Privacy Lock was not enabled."
          : "Privacy Lock was not enabled. Your app remains available as before."
      }
    }
  }

  private var privacyMessageBinding: Binding<Bool> {
    Binding(
      get: { privacyMessage != nil },
      set: { if !$0 { privacyMessage = nil } }
    )
  }

  private func deleteAllData() {
    do {
      let cloudRecordIDs = try modelContext.fetch(FetchDescriptor<TradeRecord>()).map(\.id)
      try AllIndulgeDataRepository(
        context: modelContext,
        cardAssets: FutureLifeCardAssetStore()
      ).deleteAll()
      OnboardingProfileStore().delete()
      privacyLockEnabled = false
      privacyRelockAfter = PrivacyLockSettingsStore.defaultRelockAfter
      NotificationCenter.default.post(name: .indulgeAllDataDeleted, object: nil)
      platform.delete(recordIDs: cloudRecordIDs)
      dismiss()
    } catch {
      privacyMessage = "Your data could not be completely deleted. Please try again."
    }
  }
}

private struct TradeHomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  let platform: HabitsPlatformSync
  let profile: OnboardingProfile
  let activeRecord: TradeRecord?
  @State private var target: ReclaimTarget
  @State private var destination: LifeDirection
  @State private var destinationFeedbackToken = 0
  @State private var isEditingReplacement = false
  @State private var confirmsCompletion = false
  @State private var isSaving = false
  @State private var persistenceMessage: String?
  @State private var completionMoment: CompletionMoment?

  init(
    platform: HabitsPlatformSync = HabitsPlatformSync(enabled: false),
    profile: OnboardingProfile,
    activeRecord: TradeRecord?
  ) {
    self.platform = platform
    self.profile = profile
    self.activeRecord = activeRecord
    _target = State(
      initialValue: activeRecord?.reclaimTarget ?? .suggested(for: profile.dailyTime))
    let firstDirection =
      LifeDirection.allCases.first(where: profile.lifeDirections.contains) ?? .presence
    _destination = State(initialValue: activeRecord?.destination ?? firstDirection)
  }

  var body: some View {
    GeometryReader { viewport in
      NavigationStack {
        ScrollView {
          VStack(spacing: 0) {
            IndulgeSceneHeader(
              profile: profile, title: activeTrade == nil ? "Your first trade" : "Trade active",
              height: 220)

            VStack(alignment: .leading, spacing: 20) {
              VStack(alignment: .leading, spacing: 8) {
                Text(
                  activeTrade == nil
                    ? "Trade a little drift for something you want."
                    : "Your time has somewhere to go."
                )
                .font(.indulgeDisplay)
                .foregroundStyle(Color.indulgeText)
                .fixedSize(horizontal: false, vertical: true)
                Text(
                  activeTrade == nil
                    ? "Keep the part you enjoy. Redirect only the time that stops feeling chosen."
                    : "Nothing is watched or blocked. Habits remembers the exchange you chose."
                )
                .font(.indulgeBody)
                .foregroundStyle(Color.indulgeText.opacity(0.66))
              }

              VisualTradeExchange(
                indulgence: profile.primaryIndulgence,
                destination: activeTrade?.destination ?? destination,
                reclaimTarget: activeTrade?.reclaimTarget ?? target
              )

              if activeTrade == nil || isEditingReplacement {
                tradeEditor
              } else if let activeTrade, let activeRecord {
                activeTradeControls(activeTrade, record: activeRecord)
              }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 120)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
            .background(Color.indulgeSurface)
            .clipShape(
              UnevenRoundedRectangle(
                topLeadingRadius: 30, bottomLeadingRadius: 0, bottomTrailingRadius: 0,
                topTrailingRadius: 30, style: .continuous)
            )
            .offset(y: -22)
          }
          .frame(width: viewport.size.width)
        }
        .background(Color.indulgePowderSoft)
        .ignoresSafeArea(edges: horizontalSizeClass == .compact ? .top : [])
        .scrollIndicators(.visible)
      }
    }
    .sensoryFeedback(.selection, trigger: destinationFeedbackToken)
    .confirmationDialog(
      "How did this trade go?",
      isPresented: $confirmsCompletion,
      titleVisibility: .visible
    ) {
      ForEach(TradeOutcome.allCases, id: \.self) { outcome in
        Button(outcome.title) { completeTrade(outcome) }
      }
      Button("Keep it active", role: .cancel) {}
    } message: {
      Text("Every answer belongs in your history. There is no failure state here.")
    }
    .alert("Trade not saved", isPresented: persistenceMessageBinding) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(persistenceMessage ?? "Please try again.")
    }
    .fullScreenCover(item: $completionMoment) { moment in
      TradeCompletionMomentView(moment: moment) {
        completionMoment = nil
      }
    }
  }

  private var activeTrade: ActiveTrade? {
    activeRecord?.activeValue
  }

  private var tradeEditor: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 12) {
        Text("What should that time become?")
          .font(.indulgeTitle)
          .foregroundStyle(Color.indulgeText)

        LazyVGrid(
          columns: [GridItem(.adaptive(minimum: 132), spacing: 10)],
          spacing: 10
        ) {
          ForEach(availableDestinations, id: \.self) { option in
            destinationChoice(option)
          }
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        Text("How much starts there?")
          .font(.indulgeTitle)
          .foregroundStyle(Color.indulgeText)

        HStack(spacing: 9) {
          ForEach(ReclaimTarget.allCases, id: \.rawValue) { option in
            Button {
              target = option
            } label: {
              Text(option.title)
                .font(.indulgeLabel)
                .foregroundStyle(target == option ? .white : Color.indulgeText)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                  target == option ? Color.indulgeNavy : Color.indulgePowder,
                  in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(IndulgePressableButtonStyle())
            .accessibilityAddTraits(target == option ? .isSelected : [])
          }
        }
      }

      Button(isEditingReplacement ? "Replace active trade" : "Create this trade") {
        saveTrade(replacingActive: isEditingReplacement)
      }
      .buttonStyle(IndulgePrimaryLightButtonStyle())
      .disabled(profile.primaryIndulgence == nil || isSaving)

      if isEditingReplacement {
        Button("Keep my current trade") {
          isEditingReplacement = false
        }
        .buttonStyle(.bordered)
        .tint(Color.indulgeNavy)
        .frame(maxWidth: .infinity)
      }
    }
  }

  private func activeTradeControls(_ trade: ActiveTrade, record: TradeRecord) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(
        trade.hasStarted
          ? "This trade is in motion. Finish it whenever the moment has passed."
          : "Guide \(trade.reclaimTarget.title) toward \(trade.destination.title.lowercased()) when the time stops feeling chosen.",
        systemImage: trade.hasStarted ? "hourglass.circle.fill" : "checkmark.circle.fill"
      )
      .font(.indulgeControl)
      .foregroundStyle(Color.indulgeText)
      .padding(17)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        Color.indulgeCherry.opacity(0.08),
        in: RoundedRectangle(cornerRadius: 18, style: .continuous))

      Button(trade.hasStarted ? "Finish this trade" : "Begin this trade") {
        if trade.hasStarted {
          confirmsCompletion = true
        } else {
          beginTrade(record)
        }
      }
      .buttonStyle(IndulgePrimaryLightButtonStyle())
      .disabled(isSaving)

      Button("Choose a different trade") {
        target = trade.reclaimTarget
        destination = trade.destination
        isEditingReplacement = true
      }
      .font(.indulgeControl)
      .foregroundStyle(Color.indulgeText.opacity(0.72))
      .frame(maxWidth: .infinity, minHeight: 48)
      .disabled(isSaving)
    }
  }

  private func saveTrade(replacingActive: Bool) {
    guard !isSaving, let indulgence = profile.primaryIndulgence else { return }
    isSaving = true
    do {
      try TradeRepository(context: modelContext).create(
        indulgence: indulgence,
        reclaimTarget: target,
        destination: destination,
        replacingActive: replacingActive
      )
      withAnimation(.smooth(duration: 0.42)) {
        isEditingReplacement = false
      }
    } catch {
      persistenceMessage = "Your trade is still visible, but the new choice could not be saved."
    }
    isSaving = false
  }

  private func beginTrade(_ record: TradeRecord) {
    guard !isSaving else { return }
    isSaving = true
    do {
      try TradeRepository(context: modelContext).begin(record)
    } catch {
      persistenceMessage = "This trade could not be started. Nothing was removed."
    }
    isSaving = false
  }

  private func completeTrade(_ outcome: TradeOutcome) {
    guard !isSaving, let record = activeRecord, let trade = record.activeValue else { return }
    isSaving = true
    do {
      try TradeRepository(context: modelContext).complete(record, outcome: outcome)
      platform.enqueue(record)
      completionMoment = CompletionMoment(trade: trade, outcome: outcome)
    } catch {
      persistenceMessage = "This result could not be saved. Your trade remains available to finish."
    }
    isSaving = false
  }

  private var persistenceMessageBinding: Binding<Bool> {
    Binding(
      get: { persistenceMessage != nil },
      set: { if !$0 { persistenceMessage = nil } }
    )
  }

  private var availableDestinations: [LifeDirection] {
    let selected = LifeDirection.allCases.filter(profile.lifeDirections.contains)
    return selected.isEmpty ? LifeDirection.allCases : selected
  }

  private func destinationChoice(_ option: LifeDirection) -> some View {
    let selected = destination == option
    return Button {
      withAnimation(
        reduceMotion ? .easeInOut(duration: 0.16) : .spring(duration: 0.48, bounce: 0.14)
      ) {
        destination = option
      }
      destinationFeedbackToken += 1
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        TradeArtworkImage(assetName: option.artworkAssetName)
          .frame(width: 100, height: 74)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay(alignment: .topTrailing) {
            if selected {
              Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.indulgeCherry, in: Circle())
                .padding(7)
            }
          }

        Text(option.title)
          .font(.indulgeCaption)
          .foregroundStyle(Color.indulgeText)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(8)
      .background(
        selected ? Color.indulgeCherry.opacity(0.08) : Color.indulgePowderSoft,
        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(
          selected ? Color.indulgeCherry : Color.indulgePaleBorder))
    }
    .buttonStyle(IndulgePressableButtonStyle())
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

private struct CompletionMoment: Identifiable {
  let id = UUID()
  let trade: ActiveTrade
  let outcome: TradeOutcome
}

private struct TradeCompletionMomentView: View {
  let moment: CompletionMoment
  let dismiss: () -> Void

  var body: some View {
    ZStack {
      Color.indulgePowderSoft.ignoresSafeArea()

      ScrollView {
        VStack(spacing: 24) {
          ZStack(alignment: .bottom) {
            AuthoredScenePresenter(
              assetName: moment.trade.destination.artworkAssetName,
              semanticLabel: "A glimpse of \(moment.trade.destination.title.lowercased())"
            )
            .frame(height: 390)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            LinearGradient(
              colors: [.clear, Color.indulgeNavy.opacity(0.82)],
              startPoint: .center,
              endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(spacing: 8) {
              Image(systemName: moment.outcome.systemImage)
                .font(.system(size: 30, weight: .bold))
              Text(moment.outcome.historyTitle)
                .font(.indulgeDisplay)
              Text(completionSentence)
                .font(.indulgeBody)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .padding(26)
          }

          Text("The pleasure stays part of the picture. This simply records what you chose today.")
            .font(.indulgeBody)
            .foregroundStyle(Color.indulgeText.opacity(0.68))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

          Button("Done", action: dismiss)
            .buttonStyle(IndulgePrimaryLightButtonStyle())
        }
        .padding(.horizontal, 22)
        .padding(.top, 56)
        .padding(.bottom, 36)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
      }
    }
    .accessibilityElement(children: .contain)
  }

  private var completionSentence: String {
    switch moment.outcome {
    case .madeRoom:
      "You guided \(moment.trade.reclaimTarget.title) toward \(moment.trade.destination.title.lowercased())."
    case .choseIndulgence:
      "You deliberately chose more time with \(moment.trade.indulgence.title.lowercased())."
    case .anotherDay:
      "You left this trade for another day. That is useful history too."
    }
  }
}

private struct VisualTradeExchange: View {
  let indulgence: IndulgenceChoice?
  let destination: LifeDirection
  let reclaimTarget: ReclaimTarget

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        exchangePanel(
          assetName: indulgence?.selectorAssetName ?? "television",
          label: "Keep",
          title: indulgence?.title ?? "Your pleasure"
        )

        exchangePanel(
          assetName: destination.artworkAssetName,
          label: "Make room for",
          title: destination.title
        )
        .id(destination)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
      }
      .overlay {
        Image(systemName: "arrow.right")
          .font(.system(size: 14, weight: .black))
          .foregroundStyle(.white)
          .frame(width: 38, height: 38)
          .background(Color.indulgeNavy, in: Circle())
          .overlay(Circle().stroke(Color.white, lineWidth: 4))
          .accessibilityHidden(true)
      }

      Text(
        "\(reclaimTarget.title) moves toward \(destination.title.lowercased())—only when the time stops feeling chosen."
      )
      .font(.indulgeCaption)
      .foregroundStyle(Color.indulgeText.opacity(0.64))
      .fixedSize(horizontal: false, vertical: true)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      "Keep \(indulgence?.title ?? "your pleasure"). Move \(reclaimTarget.title) toward \(destination.title.lowercased()) when the time stops feeling chosen."
    )
  }

  private func exchangePanel(assetName: String, label: String, title: String) -> some View {
    ZStack(alignment: .bottomLeading) {
      TradeArtworkImage(assetName: assetName)

      LinearGradient(
        colors: [.clear, Color.indulgeNavy.opacity(0.82)],
        startPoint: .center,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 1) {
        Text(label)
          .font(.indulgeCaption)
          .foregroundStyle(.white.opacity(0.82))
        Text(title)
          .font(.indulgeLabel)
          .foregroundStyle(.white)
          .lineLimit(2)
      }
      .padding(13)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 150)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
  }
}

private struct TradeArtworkImage: View {
  let assetName: String

  var body: some View {
    Group {
      if let source = UIImage(named: assetName, in: .main, compatibleWith: nil) {
        Image(uiImage: source)
          .resizable()
          .scaledToFill()
      } else {
        Color.indulgePowder
          .overlay {
            Image(systemName: "photo")
              .foregroundStyle(Color.indulgeText.opacity(0.4))
          }
      }
    }
    .clipped()
  }
}

private struct HistoryHomeView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  let profile: OnboardingProfile
  let activeTrade: ActiveTrade?
  let completedRecords: [TradeRecord]
  let openTrade: () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          IndulgeSceneHeader(profile: profile, title: "Your history", height: 310)

          VStack(alignment: .leading, spacing: 20) {
            if completedRecords.isEmpty {
              emptyHistory
            } else {
              VStack(alignment: .leading, spacing: 8) {
                Text("The choices you actually made.")
                  .font(.indulgeDisplay)
                  .foregroundStyle(Color.indulgeText)
                  .fixedSize(horizontal: false, vertical: true)
                Text(historySummary)
                  .font(.indulgeBody)
                  .foregroundStyle(Color.indulgeText.opacity(0.66))
                  .fixedSize(horizontal: false, vertical: true)
              }

              LazyVStack(spacing: 12) {
                ForEach(completedRecords, id: \.id) { record in
                  historyRow(record)
                }
              }
            }
          }
          .padding(.horizontal, 22)
          .padding(.top, 28)
          .padding(.bottom, 120)
          .frame(maxWidth: 680, minHeight: 420, alignment: .topLeading)
          .frame(maxWidth: .infinity)
          .background(Color.indulgeSurface)
          .clipShape(
            UnevenRoundedRectangle(
              topLeadingRadius: 30, bottomLeadingRadius: 0, bottomTrailingRadius: 0,
              topTrailingRadius: 30, style: .continuous)
          )
          .offset(y: -22)
        }
      }
      .background(Color.indulgePowderSoft)
      .ignoresSafeArea(edges: horizontalSizeClass == .compact ? .top : [])
      .scrollIndicators(.visible)
    }
  }

  private var emptyHistory: some View {
    VStack(alignment: .leading, spacing: 18) {
      Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(Color.indulgeCherry)

      Text("Your history starts with a real trade.")
        .font(.indulgeDisplay)
        .foregroundStyle(Color.indulgeText)
        .fixedSize(horizontal: false, vertical: true)

      Text(
        activeTrade == nil
          ? "After your first trade, this is where you’ll see what you chose and what you reclaimed. We won’t invent a chart before there is something true to show."
          : "Your trade is ready. When you finish it, the choice you actually made will appear here."
      )
      .font(.indulgeBody)
      .foregroundStyle(Color.indulgeText.opacity(0.66))
      .fixedSize(horizontal: false, vertical: true)

      if activeTrade == nil {
        Button("Create my first trade", action: openTrade)
          .buttonStyle(IndulgePrimaryLightButtonStyle())
      } else {
        Label("Waiting for your first completed trade", systemImage: "hourglass")
          .font(.indulgeControl)
          .foregroundStyle(Color.indulgeText)
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            Color.indulgePowderSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      }
    }
  }

  private var historySummary: String {
    let madeRoom = completedRecords.filter { $0.outcome == .madeRoom }
    let minutes = madeRoom.reduce(0) { $0 + $1.reclaimMinutes }
    if minutes == 0 {
      return
        "\(completedRecords.count.formatted()) completed \(completedRecords.count == 1 ? "trade" : "trades"). No reclaimed time is assumed."
    }
    return
      "\(completedRecords.count.formatted()) completed \(completedRecords.count == 1 ? "trade" : "trades") · \(minutes.formatted()) minutes you said became room for something else."
  }

  private func historyRow(_ record: TradeRecord) -> some View {
    HStack(spacing: 14) {
      TradeArtworkImage(assetName: record.destination.artworkAssetName)
        .frame(width: 82, height: 82)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

      VStack(alignment: .leading, spacing: 5) {
        Label(
          record.outcome?.historyTitle ?? "Completed",
          systemImage: record.outcome?.systemImage ?? "checkmark"
        )
        .font(.indulgeControl)
        .foregroundStyle(Color.indulgeText)
        Text(
          "\(record.indulgence.title) · \(record.reclaimTarget.title) toward \(record.destination.title.lowercased())"
        )
        .font(.indulgeCaption)
        .foregroundStyle(Color.indulgeText.opacity(0.66))
        .fixedSize(horizontal: false, vertical: true)
        if let completedAt = record.completedAt {
          Text(completedAt.formatted(date: .abbreviated, time: .shortened))
            .font(.caption)
            .foregroundStyle(Color.indulgeText.opacity(0.5))
        }
      }
      Spacer(minLength: 0)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.indulgePowderSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.indulgePaleBorder)
    )
    .accessibilityElement(children: .combine)
  }
}

private struct IndulgeSceneHeader: View {
  let profile: OnboardingProfile
  let title: String
  let height: CGFloat

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        if portraitSceneExists {
          AuthoredScenePresenter(
            assetName: "\(sceneAssetName)Portrait",
            semanticLabel: accessibilityValue
          )
        } else if isTelevisionScene {
          AuthoredScenePresenter(
            assetName: sceneAssetName,
            semanticLabel: accessibilityValue,
            ambientMotion: false
          )
          .blur(radius: 24)
          .scaleEffect(1.08)

          AuthoredScenePresenter(
            assetName: sceneAssetName,
            contentMode: .fit,
            semanticLabel: accessibilityValue
          )
        } else {
          AuthoredScenePresenter(
            assetName: sceneAssetName,
            semanticLabel: accessibilityValue
          )
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
    }
    .frame(height: height)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(accessibilityValue)
  }

  private var accessibilityValue: String {
    profile.visualState.semanticSummary
  }

  private var portraitSceneExists: Bool {
    UIImage(named: "\(sceneAssetName)Portrait", in: .main, compatibleWith: nil) != nil
  }

  private var sceneAssetName: String {
    profile.visualState.sceneAssetName(for: profile.characterPresentation)
  }

  private var isTelevisionScene: Bool {
    if case .watchingTelevision = profile.visualState { return true }
    return false
  }
}

private struct FlowingDirectionRow: View {
  let directions: Set<LifeDirection>

  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 9)], spacing: 9) {
      ForEach(directions.sorted { $0.rawValue < $1.rawValue }, id: \.self) { direction in
        Label(direction.title, systemImage: direction.icon)
          .font(.indulgeLabel)
          .foregroundStyle(Color.indulgeText)
          .padding(.horizontal, 13)
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          .background(
            Color.indulgePowder, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
  }
}

private struct IndulgePrimaryLightButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.indulgeControl)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 56)
      .background(
        Color.indulgeCherry,
        in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
      )
      .opacity(isEnabled ? 1 : 0.42)
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
      .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
  }
}

private struct InteractiveSceneButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? 1.018 : 1)
      .brightness(configuration.isPressed ? 0.035 : 0)
      .animation(
        reduceMotion ? nil : .timingCurve(0.18, 0.82, 0.22, 1, duration: 0.22),
        value: configuration.isPressed
      )
  }
}

extension OnboardingProfile {
  static let appPreview = OnboardingProfile(
    preferredName: "Maya",
    gender: .woman,
    activities: [.television, .shortVideo, .alcohol],
    primaryIndulgence: .television,
    dailyTime: .twoHours,
    commonMoments: [.evening],
    startingPattern: .autopilot,
    need: .comfort,
    intentionality: .mixed,
    lifeDirections: [.presence, .creativity],
    pace: .gentle
  )
}

#Preview("Life app") {
  IndulgeAppShell(profile: .appPreview)
}

#Preview("Trade active") {
  IndulgeAppShell(profile: .appPreview, initialTab: .trade, startsWithActiveTrade: true)
}
