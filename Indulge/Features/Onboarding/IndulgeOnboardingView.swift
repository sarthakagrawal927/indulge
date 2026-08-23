import SwiftUI
import UIKit

struct IndulgeOnboardingView: View {
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
  @Environment(\.colorSchemeContrast) private var colorSchemeContrast
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @State private var step: PersonalOnboardingStep
  @State private var profile: OnboardingProfile
  @State private var forceReduceMotion: Bool
  @State private var navigationDirection: OnboardingNavigationDirection = .forward
  @State private var selectionFeedbackToken = 0
  @State private var completionFeedbackToken = 0
  @State private var journeyPhase: OnboardingJourneyPhase
  @State private var activitySelectionNotice: String?
  @FocusState private var focusedField: TextEntryField?
  @AccessibilityFocusState private var headingFocused: Bool
  private let initiallyFocusesTextEntry: Bool
  private let automaticallyDemonstratesScene: Bool
  private let isExistingOwnerOrientation: Bool
  private let onCancel: () -> Void
  private let onComplete: (OnboardingProfile) -> Void

  init(
    preset: PersonalOnboardingPreset = .launchArguments,
    isExistingOwnerOrientation: Bool = false,
    onCancel: @escaping () -> Void = {},
    onComplete: @escaping (OnboardingProfile) -> Void = { _ in }
  ) {
    let initialProfile = preset.profile
    _step = State(initialValue: preset.step)
    _profile = State(initialValue: initialProfile)
    _forceReduceMotion = State(initialValue: preset.forcesReduceMotion)
    _journeyPhase = State(
      initialValue: PersonalOnboardingStep.deeperJourney.contains(preset.step)
        && preset.step != .reflection
        ? .deeper
        : .core
    )
    _activitySelectionNotice = State(initialValue: nil)
    initiallyFocusesTextEntry = preset.focusesTextEntry
    automaticallyDemonstratesScene = preset.automaticallyDemonstratesScene
    self.isExistingOwnerOrientation = isExistingOwnerOrientation
    self.onCancel = onCancel
    self.onComplete = onComplete
  }

  private var reduceMotion: Bool { systemReduceMotion || forceReduceMotion }
  private var journeySteps: [PersonalOnboardingStep] {
    journeyPhase == .core
      ? PersonalOnboardingStep.coreJourney : PersonalOnboardingStep.deeperJourney
  }
  private var journeyIndex: Int { journeySteps.firstIndex(of: step) ?? 0 }
  private var textEntryIsFocused: Bool { focusedField != nil }
  private var usesActivityPalette: Bool { true }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.indulgePowderSoft.ignoresSafeArea()

        mainLayout(for: proxy)
          .ignoresSafeArea(edges: .top)
      }
    }
    .preferredColorScheme(.light)
    .animation(
      reduceMotion ? .easeInOut(duration: 0.16) : .spring(duration: 0.62, bounce: 0.12),
      value: profile.visualState
    )
    .animation(
      reduceMotion ? .easeInOut(duration: 0.16) : .spring(duration: 0.62, bounce: 0.10),
      value: profile.hasExplicitCharacterPresentation
    )
    .sensoryFeedback(.selection, trigger: selectionFeedbackToken)
    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.56), trigger: step)
    .sensoryFeedback(.success, trigger: completionFeedbackToken)
    .simultaneousGesture(edgeBackGesture)
    .task {
      guard automaticallyDemonstratesScene else { return }
      try? await Task.sleep(for: .milliseconds(700))
      guard !Task.isCancelled else { return }
      profile.toggleActivity(.television)
      try? await Task.sleep(for: .milliseconds(2_050))
      guard !Task.isCancelled else { return }
      profile.toggleActivity(.shortVideo)
      try? await Task.sleep(for: .milliseconds(1_150))
      guard !Task.isCancelled else { return }
      profile.toggleActivity(.alcohol)
    }
  }

  @ViewBuilder
  private func mainLayout(for proxy: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      ZStack(alignment: .top) {
        if step == .name {
          Color.white
          Image("HabitsOnboarding")
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 18)
            .padding(.top, proxy.safeAreaInsets.top + 48)
            .padding(.bottom, 12)
            .accessibilityLabel("A hand-drawn figure trades lost phone time for chosen time spent walking and growing.")
        } else {
          PersonalOnboardingStage(
            state: profile.visualState,
            presentation: profile.characterPresentation,
            concealsIdentity: !profile.hasExplicitCharacterPresentation,
            reduceMotion: reduceMotion,
            showsCaption: false,
            compact: usesCompactPersistentStage || textEntryIsFocused
          )
        }

        Color.white
          .opacity(textEntryIsFocused ? 0.08 : 0)
          .allowsHitTesting(false)

        topBar
          .padding(.horizontal, 18)
          .padding(.top, proxy.safeAreaInsets.top + 8)
      }
      .frame(height: stageHeight(for: proxy.size))
      .clipped()

      promptTray
    }
    .animation(
      reduceMotion ? .easeInOut(duration: 0.16) : .spring(duration: 0.42, bounce: 0.08),
      value: textEntryIsFocused)
  }

  private var promptTray: some View {
    VStack(spacing: 0) {
      ScrollView(showsIndicators: true) {
        promptContent
          .frame(maxWidth: 600)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 22)
          .padding(.top, 24)
          .padding(.bottom, 18)
      }
      .scrollBounceBehavior(.basedOnSize)
      .scrollDismissesKeyboard(.interactively)

      Divider()
        .overlay(Color.indulgePaleBorder.opacity(0.7))

      bottomActions
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
    .background(Color.white)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: IndulgeTheme.panelCornerRadius,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: IndulgeTheme.panelCornerRadius,
        style: .continuous
      )
    )
    .shadow(color: Color.indulgeNavy.opacity(0.10), radius: 28, y: -8)
  }

  private func stageHeight(for size: CGSize) -> CGFloat {
    if textEntryIsFocused { return dynamicTypeSize.isAccessibilitySize ? 88 : 112 }
    if size.width > 700 {
      return usesCompactPersistentStage
        ? min(size.height * 0.32, 420) : min(size.height * 0.50, 760)
    }
    if dynamicTypeSize.isAccessibilitySize {
      return usesCompactPersistentStage ? 156 : min(size.height * 0.26, 210)
    }
    if usesCompactPersistentStage {
      return min(max(size.height * 0.24, 176), 230)
    }
    let fraction: CGFloat =
      switch step {
      case .activities: 0.34
      case .gender, .lifeDirection, .reflection: 0.36
      default: 0.44
      }
    return min(max(size.height * fraction, 250), 410)
  }

  private var usesCompactPersistentStage: Bool {
    switch step {
    case .gender, .primaryIndulgence, .timeSpent, .commonMoment, .startingPattern,
      .underlyingNeed, .intentionality, .lifeDirection, .changePace:
      true
    case .name, .activities, .reflection:
      false
    }
  }

  private var topBar: some View {
    HStack(spacing: 10) {
      if step != .name {
        Button(action: goBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 17, weight: .bold))
            .frame(width: 44, height: 44)
            .indulgeGlassControl(in: Circle())
        }
        .buttonStyle(IndulgePressableButtonStyle())
        .accessibilityLabel("Back")
      } else {
        Color.clear.frame(width: 44, height: 44)
      }

      Group {
        if step == .name || step == .activities {
          Color.clear
        } else {
          Text(progressText)
            .font(.indulgeCaption)
            .foregroundStyle(Color.indulgeNavy.opacity(0.58))
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Color.white.opacity(0.86), in: Capsule())
            .accessibilityLabel(progressAccessibilityLabel)
        }
      }
      .frame(height: 44)
      .frame(maxWidth: .infinity)

      if isExistingOwnerOrientation {
        Button("Close", action: onCancel)
          .font(.indulgeLabel)
          .foregroundStyle(step == .name ? Color.indulgeNavy : .white.opacity(0.9))
          .frame(minWidth: 52, minHeight: 44)
          .buttonStyle(IndulgePressableButtonStyle())
          .accessibilityHint("Returns without changing your Habits profile")
      } else if step.showsSkipAction {
        Button("Skip", action: skipOptionalStep)
          .font(.indulgeLabel)
          .foregroundStyle(.white.opacity(0.82))
          .frame(minWidth: 52, minHeight: 44)
          .dynamicTypeSize(.xSmall ... .xxxLarge)
          .buttonStyle(IndulgePressableButtonStyle())
      } else {
        Color.clear.frame(width: 52, height: 44)
      }
    }
    .foregroundStyle(Color.indulgeNavy)
  }

  private var promptContent: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 8) {
        if step == .reflection {
          chapterLabel
        }

        Text(step.title(for: profile))
          .font(step == .reflection ? .indulgeDisplay : .indulgeQuestion)
          .tracking(-0.5)
          .foregroundStyle(Color.indulgeNavy)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
          .accessibilityFocused($headingFocused)

        let body = step.body(for: profile)
        if !body.isEmpty {
          Text(body)
            .font(.indulgeBody)
            .foregroundStyle(
              Color.indulgeNavy.opacity(colorSchemeContrast == .increased ? 0.90 : 0.66)
            )
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      stepControls
    }
    .frame(maxWidth: 600, alignment: .leading)
    .id(step)
    .transition(promptTransition)
  }

  private var chapterLabel: some View {
    HStack(spacing: 9) {
      Image(systemName: step == .reflection ? "sparkles" : "circle.fill")
        .font(.system(size: step == .reflection ? 14 : 9, weight: .bold))
        .frame(width: 16, height: 16)
      Text(step.chapterTitle)
        .font(.indulgeLabel)
    }
    .foregroundStyle(Color.indulgeCherry)
    .dynamicTypeSize(.xSmall ... .xxxLarge)
    .accessibilityElement(children: .combine)
  }

  private var progressText: String {
    if journeyPhase == .deeper, step != .reflection {
      return "Optional \(journeyIndex + 1) of \(journeySteps.count - 1)"
    }
    if journeyPhase == .deeper { return "Your reflection" }
    return "\(journeyIndex + 1) of \(journeySteps.count)"
  }

  private var progressAccessibilityLabel: String {
    if journeyPhase == .deeper, step != .reflection {
      return "Optional personalization, question \(journeyIndex + 1) of \(journeySteps.count - 1)"
    }
    if journeyPhase == .deeper { return "Updated reflection" }
    return "Onboarding, step \(journeyIndex + 1) of \(journeySteps.count)"
  }

  @ViewBuilder
  private var stepControls: some View {
    switch step {
    case .name:
      nameEntry
    case .gender:
      genderChoices
    case .activities:
      activityChoices
    case .primaryIndulgence:
      primaryIndulgenceChoices
    case .timeSpent:
      verticalChoices(DailyTime.allCases, selection: profile.dailyTime, title: \.title) {
        profile.dailyTime = $0
      }
    case .commonMoment:
      commonMomentChoices
    case .startingPattern:
      verticalChoices(StartingPattern.allCases, selection: profile.startingPattern, title: \.title)
      { profile.startingPattern = $0 }
    case .underlyingNeed:
      gridChoices(IndulgenceNeed.allCases, selection: profile.need, title: \.title, icon: \.icon) {
        profile.need = $0
      }
    case .intentionality:
      verticalChoices(
        IntentionalityChoice.allCases, selection: profile.intentionality, title: \.title
      ) { profile.intentionality = $0 }
    case .lifeDirection:
      lifeDirectionChoices
    case .changePace:
      paceChoices
    case .reflection:
      reflectionSummary
    }
  }

  private var nameEntry: some View {
    VStack(alignment: .leading, spacing: 10) {
      TextField("Your name", text: $profile.preferredName)
        .focused($focusedField, equals: .name)
        .task {
          guard initiallyFocusesTextEntry else { return }
          try? await Task.sleep(for: .milliseconds(350))
          focusedField = .name
        }
        .tint(Color.indulgeCherry)
        .textContentType(.name)
        .submitLabel(.continue)
        .onSubmit(advance)
        .font(.indulgeTitle)
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
        .foregroundStyle(Color.indulgeNavy)
        .background(
          Color.indulgePowderSoft,
          in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
        )
        .overlay(
          RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius).stroke(
            focusedField == .name ? Color.indulgeCherry : Color.indulgePaleBorder, lineWidth: 1.5))
    }
  }

  private var genderChoices: some View {
    VStack(spacing: 10) {
      ForEach(GenderIdentity.allCases, id: \.self) { gender in
        selectionRow(title: gender.title, selected: profile.gender == gender) {
          profile.gender = gender
          if gender != .selfDescribe { profile.customGender = "" }
        }
      }

      if profile.gender == .selfDescribe {
        TextField("How you describe it", text: $profile.customGender)
          .focused($focusedField, equals: .gender)
          .submitLabel(.continue)
          .onSubmit(advance)
          .font(.indulgeControl)
          .padding(.horizontal, 16)
          .frame(minHeight: 56)
          .foregroundStyle(Color.indulgeNavy)
          .background(
            Color.indulgePowderSoft,
            in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
          )
          .overlay(
            RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius).stroke(
              Color.indulgeCherry.opacity(0.8), lineWidth: 1.5)
          )
          .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
      }
    }
  }

  private var activityChoices: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 4) {
        Text("\(profile.activities.count) of 5 selected")
          .font(.indulgeLabel)
          .foregroundStyle(Color.indulgeNavy.opacity(0.72))

        Text(activitySelectionNotice ?? "Choose up to five.")
          .font(.indulgeCaption)
          .foregroundStyle(
            activitySelectionNotice == nil ? Color.indulgeNavy.opacity(0.58) : Color.indulgeCherry
          )
          .fixedSize(horizontal: false, vertical: true)
      }

      ForEach(OnboardingActivityFamily.allCases, id: \.self) { family in
        VStack(alignment: .leading, spacing: 9) {
          Text(family.title)
            .font(.indulgeTitle)
            .foregroundStyle(Color.indulgeNavy)

          LazyVGrid(
            columns: Array(
              repeating: GridItem(.flexible(), spacing: 8),
              count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
            ),
            spacing: 8
          ) {
            ForEach(family.activities, id: \.self) { activity in
              activityChoice(activity)
            }
          }
        }
      }
    }
  }

  private func activityChoice(_ activity: IndulgenceChoice) -> some View {
    let selected = profile.activities.contains(activity)
    return Button {
      withAnimation(
        reduceMotion ? .easeInOut(duration: 0.16) : .spring(duration: 0.46, bounce: 0.18)
      ) {
        if profile.toggleActivity(activity) {
          activitySelectionNotice = nil
        } else {
          activitySelectionNotice =
            "You can build one scene with up to five choices. Remove one to add another."
        }
      }
      selectionHaptic()
    } label: {
      HStack(spacing: 9) {
        IndulgenceArtworkView(assetName: activity.selectorAssetName)
          .frame(
            width: dynamicTypeSize.isAccessibilitySize ? 72 : 46,
            height: dynamicTypeSize.isAccessibilitySize ? 72 : 46
          )
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

        Text(activity.title)
          .font(.indulgeLabel)
          .foregroundStyle(Color.indulgeNavy)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(8)
      .frame(
        maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 88 : 60,
        alignment: .leading
      )
      .background(selected ? Color.indulgeCherry.opacity(0.08) : Color.indulgePowderSoft)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(
            selected ? Color.indulgeCherry : Color.indulgePaleBorder.opacity(0.78),
            lineWidth: selected ? 2 : 1)
      )
      .overlay(alignment: .topTrailing) {
        if selected {
          Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 23, height: 23)
            .background(Color.indulgeCherry, in: Circle())
            .padding(7)
            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        }
      }
    }
    .buttonStyle(IndulgePressableButtonStyle())
    .accessibilityAddTraits(selected ? .isSelected : [])
    .accessibilityHint("Select up to five. Compatible choices appear together in the scene.")
  }

  private var primaryIndulgenceChoices: some View {
    VStack(spacing: 10) {
      ForEach(profile.activities.sorted { $0.title < $1.title }, id: \.self) { activity in
        selectionRow(
          title: activity.title, icon: activity.icon,
          selected: profile.primaryIndulgence == activity
        ) {
          profile.primaryIndulgence = activity
        }
      }
    }
  }

  private var lifeDirectionChoices: some View {
    VStack(alignment: .leading, spacing: 10) {
      LazyVGrid(columns: gridColumns, spacing: 10) {
        ForEach(LifeDirection.allCases, id: \.self) { direction in
          gridChoice(
            title: direction.title, icon: direction.icon,
            selected: profile.lifeDirections.contains(direction)
          ) {
            if profile.lifeDirections.contains(direction) {
              profile.lifeDirections.remove(direction)
            } else if profile.lifeDirections.count < 3 {
              profile.lifeDirections.insert(direction)
            }
          }
        }
      }

      Text("\(profile.lifeDirections.count) selected · Choose up to three")
        .font(.indulgeCaption)
        .foregroundStyle(Color.indulgeNavy.opacity(0.58))
        .accessibilityLabel("\(profile.lifeDirections.count) of 3 life directions selected")
    }
  }

  private var commonMomentChoices: some View {
    VStack(alignment: .leading, spacing: 10) {
      LazyVGrid(columns: gridColumns, spacing: 10) {
        ForEach(CommonMoment.allCases, id: \.self) { moment in
          gridChoice(
            title: moment.title,
            icon: moment.icon,
            selected: profile.commonMoments.contains(moment)
          ) {
            if profile.commonMoments.contains(moment) {
              profile.commonMoments.remove(moment)
            } else {
              profile.commonMoments.insert(moment)
            }
          }
        }
      }

      Text("\(profile.commonMoments.count) selected · Choose all that apply")
        .font(.indulgeCaption)
        .foregroundStyle(Color.indulgeNavy.opacity(0.58))
        .accessibilityLabel(
          "\(profile.commonMoments.count) common moments selected. Choose all that apply.")
    }
  }

  private var paceChoices: some View {
    VStack(spacing: 10) {
      ForEach(ChangePace.allCases, id: \.self) { pace in
        Button {
          profile.pace = pace
          selectionHaptic()
        } label: {
          HStack(spacing: 13) {
            selectionMark(selected: profile.pace == pace)
            VStack(alignment: .leading, spacing: 4) {
              Text(pace.title)
                .font(.indulgeControl)
              Text(pace.detail)
                .font(.indulgeCaption)
                .foregroundStyle(Color.indulgeNavy.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
          }
          .multilineTextAlignment(.leading)
          .padding(14)
          .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
          .background(
            profile.pace == pace ? Color.indulgeCherry.opacity(0.08) : Color.indulgePowderSoft,
            in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
          )
          .overlay(
            RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius).stroke(
              profile.pace == pace ? Color.indulgeCherry : Color.indulgePaleBorder))
        }
        .foregroundStyle(Color.indulgeNavy)
        .buttonStyle(IndulgePressableButtonStyle())
        .accessibilityAddTraits(profile.pace == pace ? .isSelected : [])
      }
    }
  }

  private var reflectionSummary: some View {
    VStack(alignment: .leading, spacing: 10) {
      reflectionChip(
        icon: profile.primaryIndulgence?.icon ?? "sparkles",
        text: profile.primaryIndulgence?.title ?? "Your pleasure")
      if let dailyTime = profile.dailyTime {
        reflectionChip(icon: "clock.fill", text: dailyTime.title)
      }
      if !profile.commonMoments.isEmpty {
        reflectionChip(icon: "clock.fill", text: "Often \(profile.commonMomentSummary)")
      }
      if let need = profile.need {
        reflectionChip(icon: need.icon, text: "Looking for \(need.title.lowercased())")
      }
      if let pace = profile.pace {
        reflectionChip(icon: "hand.raised.fill", text: pace.title)
      }

    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Your reflection summary")
  }

  private func reflectionChip(icon: String, text: String) -> some View {
    Label(text, systemImage: icon)
      .font(.indulgeLabel)
      .foregroundStyle(Color.indulgeNavy.opacity(0.86))
      .padding(.horizontal, 14)
      .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
      .background(
        Color.indulgePowderSoft,
        in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius).stroke(Color.indulgePaleBorder))
  }

  private var bottomActions: some View {
    VStack(spacing: 10) {
      primaryButton

      if step == .reflection, journeyPhase == .core {
        Button("Personalize this reflection", action: beginDeeperPersonalization)
          .font(.indulgeLabel)
          .foregroundStyle(Color.indulgeNavy)
          .frame(maxWidth: .infinity, minHeight: 44)
          .accessibilityHint("Opens four optional questions, then returns to this reflection")
      }
    }
  }

  private var primaryButton: some View {
    Button(action: advance) {
      HStack {
        Text(step.actionTitle)
        Spacer()
        Image(systemName: step == .reflection ? "heart.fill" : "arrow.right")
      }
      .font(.indulgeControl)
      .padding(.horizontal, 18)
      .frame(maxWidth: .infinity, minHeight: 56)
      .background(
        Color.indulgeCherry,
        in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
      )
      .foregroundStyle(Color.white)
    }
    .buttonStyle(IndulgePressableButtonStyle())
    .disabled(!profile.canAdvance(from: step))
    .opacity(profile.canAdvance(from: step) ? 1 : 0.42)
    .accessibilityHint(
      step == .reflection ? "Finishes this private reflection" : "Continues to the next question")
  }

  private func verticalChoices<Item: Hashable>(
    _ items: [Item],
    selection: Item?,
    title: KeyPath<Item, String>,
    action: @escaping (Item) -> Void
  ) -> some View {
    VStack(spacing: 10) {
      ForEach(items, id: \.self) { item in
        selectionRow(title: item[keyPath: title], selected: selection == item) { action(item) }
      }
    }
  }

  private func gridChoices<Item: Hashable>(
    _ items: [Item],
    selection: Item?,
    title: KeyPath<Item, String>,
    icon: KeyPath<Item, String>,
    action: @escaping (Item) -> Void
  ) -> some View {
    LazyVGrid(columns: gridColumns, spacing: 10) {
      ForEach(items, id: \.self) { item in
        gridChoice(
          title: item[keyPath: title], icon: item[keyPath: icon], selected: selection == item
        ) { action(item) }
      }
    }
  }

  private func selectionRow(
    title: String, icon: String? = nil, selected: Bool, action: @escaping () -> Void
  ) -> some View {
    Button {
      action()
      selectionHaptic()
    } label: {
      HStack(spacing: 12) {
        if let icon {
          Image(systemName: icon)
            .font(.system(size: 17, weight: .semibold))
            .frame(width: 24)
        }
        Text(title)
          .font(.indulgeControl)
        Spacer(minLength: 0)
        selectionMark(selected: selected)
      }
      .padding(.horizontal, 15)
      .frame(maxWidth: .infinity, minHeight: 56)
      .background(
        selected ? Color.indulgeCherry.opacity(0.08) : Color.indulgePowderSoft,
        in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius).stroke(
          selected ? Color.indulgeCherry : Color.indulgePaleBorder))
    }
    .foregroundStyle(Color.indulgeNavy)
    .buttonStyle(IndulgePressableButtonStyle())
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func gridChoice(title: String, icon: String, selected: Bool, action: @escaping () -> Void)
    -> some View
  {
    Button {
      action()
      selectionHaptic()
    } label: {
      VStack(spacing: 8) {
        Image(systemName: differentiateWithoutColor && selected ? "checkmark.circle.fill" : icon)
          .font(.system(size: 20, weight: .semibold))
          .symbolEffect(.bounce, value: selected)
        Text(title)
          .font(.indulgeCaption)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.horizontal, 7)
      .frame(maxWidth: .infinity, minHeight: 78)
      .background(
        selected ? Color.indulgeCherry.opacity(0.08) : Color.indulgePowderSoft,
        in: RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: IndulgeTheme.cornerRadius).stroke(
          selected ? Color.indulgeCherry : Color.indulgePaleBorder)
      )
      .overlay(alignment: .topTrailing) {
        if selected {
          Image(systemName: "checkmark")
            .font(.system(size: 9, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 21, height: 21)
            .background(Color.indulgeCherry, in: Circle())
            .padding(7)
            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        }
      }
    }
    .foregroundStyle(Color.indulgeNavy)
    .buttonStyle(IndulgePressableButtonStyle())
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func selectionMark(selected: Bool) -> some View {
    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
      .font(.system(size: 20, weight: .semibold))
      .foregroundStyle(selected ? Color.indulgeCherry : Color.indulgeNavy.opacity(0.28))
      .contentTransition(.symbolEffect(.replace))
      .accessibilityHidden(true)
  }

  private var gridColumns: [GridItem] {
    if dynamicTypeSize.isAccessibilitySize {
      [GridItem(.flexible(), spacing: 10)]
    } else {
      [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }
  }

  private func advance() {
    guard profile.canAdvance(from: step) else { return }
    focusedField = nil
    if step == .reflection {
      completionFeedbackToken += 1
      onComplete(profile)
      return
    }
    navigationDirection = .forward
    moveForward()
  }

  private func goBack() {
    focusedField = nil
    navigationDirection = .backward
    if journeyIndex > 0 {
      move(to: journeySteps[journeyIndex - 1])
    } else if journeyPhase == .deeper {
      journeyPhase = .core
      move(to: .reflection)
    } else {
      return
    }
    selectionHaptic()
  }

  private func skipOptionalStep() {
    profile.clearAnswer(for: step)
    focusedField = nil
    navigationDirection = .forward
    moveForward()
  }

  private func moveForward() {
    guard journeyIndex + 1 < journeySteps.count else { return }
    move(to: journeySteps[journeyIndex + 1])
  }

  private func beginDeeperPersonalization() {
    focusedField = nil
    navigationDirection = .forward
    journeyPhase = .deeper
    move(to: PersonalOnboardingStep.deeperJourney[0])
    selectionHaptic()
  }

  private func move(to destination: PersonalOnboardingStep) {
    headingFocused = false
    withAnimation(reduceMotion ? .easeInOut(duration: 0.16) : .spring(duration: 0.56, bounce: 0.12))
    {
      step = destination
    }
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 420))
      headingFocused = true
    }
  }

  private var edgeBackGesture: some Gesture {
    DragGesture(minimumDistance: 24, coordinateSpace: .local)
      .onEnded { value in
        guard step != .name else { return }
        guard value.startLocation.x <= 28 else { return }
        guard value.translation.width >= 72 else { return }
        guard abs(value.translation.height) < 52 else { return }
        goBack()
      }
  }

  private var promptTransition: AnyTransition {
    guard !reduceMotion else { return .opacity }
    let edge: Edge = navigationDirection == .forward ? .trailing : .leading
    return .asymmetric(
      insertion: .move(edge: edge).combined(with: .opacity),
      removal: .opacity
    )
  }

  private func selectionHaptic() { selectionFeedbackToken += 1 }
}

private enum TextEntryField: Hashable {
  case name
  case gender
}

private enum OnboardingJourneyPhase {
  case core
  case deeper
}

private enum OnboardingNavigationDirection {
  case forward
  case backward
}

private struct IndulgenceArtworkView: View {
  let assetName: String

  var body: some View {
    if let source = UIImage(named: assetName, in: .main, compatibleWith: nil) {
      Image(uiImage: source)
        .resizable()
        .scaledToFill()
    } else {
      Color.indulgePowder
        .overlay(Image(systemName: "photo").foregroundStyle(Color.indulgeNavy.opacity(0.35)))
    }
  }
}

private struct PersonalOnboardingStage: View {
  let state: OnboardingVisualState
  let presentation: CharacterPresentation
  let concealsIdentity: Bool
  let reduceMotion: Bool
  let showsCaption: Bool
  let compact: Bool
  @State private var breathe = false
  @State private var lightDrift = false
  @State private var previousState: OnboardingVisualState
  @State private var renderedState: OnboardingVisualState
  @State private var transition: OnboardingSceneTransition = .none
  @State private var sofaArrival: CGFloat = 1
  @State private var characterArrival: CGFloat = 1
  @State private var televisionArrival: CGFloat = 1
  @State private var companionArrival: CGFloat = 1
  @State private var finalArrival: CGFloat = 1
  @State private var hasAppeared = false

  init(
    state: OnboardingVisualState,
    presentation: CharacterPresentation,
    concealsIdentity: Bool,
    reduceMotion: Bool,
    showsCaption: Bool,
    compact: Bool
  ) {
    self.state = state
    self.presentation = presentation
    self.concealsIdentity = concealsIdentity
    self.reduceMotion = reduceMotion
    self.showsCaption = showsCaption
    self.compact = compact
    _previousState = State(initialValue: state)
    _renderedState = State(initialValue: state)
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        transitionContent(size: proxy.size)

        if isGeneratedRoom {
          LinearGradient(
            colors: [.clear, .white.opacity(0.18), .clear],
            startPoint: .leading,
            endPoint: .trailing
          )
          .blendMode(.softLight)
          .offset(x: reduceMotion ? 0 : (lightDrift ? proxy.size.width : -proxy.size.width))
          .opacity(reduceMotion ? 0 : 0.52)
          .accessibilityHidden(true)
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Your scene")
      .accessibilityValue(accessibilityValue)
    }
    .task(id: "\(presentation.rawValue)-\(stageKey(for: state))") {
      await animateSceneChange(to: state)
    }
    .task(id: reduceMotion) {
      guard !reduceMotion else {
        breathe = false
        lightDrift = false
        return
      }
      withAnimation(.easeInOut(duration: 4.4).repeatForever(autoreverses: true)) { breathe = true }
      withAnimation(.linear(duration: 7.5).repeatForever(autoreverses: false)) { lightDrift = true }
    }
  }

  @ViewBuilder
  private func transitionContent(size: CGSize) -> some View {
    switch transition {
    case .assembleWatching:
      stageContent(for: previousState, size: size)
      stageContent(for: renderedState, size: size)
        .mask(SceneAssemblyMask(region: .sofa, progress: sofaArrival))
      stageContent(for: renderedState, size: size)
        .mask(SceneAssemblyMask(region: .character, progress: characterArrival))
      stageContent(for: renderedState, size: size)
        .mask(SceneAssemblyMask(region: .television, progress: televisionArrival))
      stageContent(for: renderedState, size: size)
        .opacity(finalArrival)
    case .addCompanion, .removeCompanion:
      stageContent(for: previousState, size: size)
      stageContent(for: renderedState, size: size)
        .mask(CompanionArrivalMask(progress: companionArrival))
      stageContent(for: renderedState, size: size)
        .opacity(finalArrival)
    case .replaceScene:
      stageContent(for: previousState, size: size)
        .opacity(1 - finalArrival)
        .scaleEffect(1 - (0.012 * finalArrival))
      stageContent(for: renderedState, size: size)
        .opacity(finalArrival)
        .scaleEffect(0.988 + (0.012 * finalArrival))
    case .none:
      stageContent(for: renderedState, size: size)
    }
  }

  @ViewBuilder
  private func stageContent(for visualState: OnboardingVisualState, size: CGSize) -> some View {
    ZStack(alignment: .bottom) {
      AuthoredScenePresenter(
        assetName: visualState.sceneAssetName(for: presentation),
        alignment: compact && visualState == .standing ? .top : .center,
        semanticLabel: accessibilityValue,
        ambientMotion: false,
        reduceMotionOverride: reduceMotion
      )
      .frame(
        width: size.width,
        height: size.height,
        alignment: compact && visualState == .standing ? .top : .center
      )
      .scaleEffect(concealsIdentity ? 1.80 : (breathe ? 1.016 : 1))
      .offset(x: concealsIdentity ? -size.width * 0.40 : 0)

    }
  }

  private var isGeneratedRoom: Bool { true }

  private func stageKey(for visualState: OnboardingVisualState) -> String {
    visualState.sceneAssetName(for: presentation)
  }

  private var accessibilityValue: String {
    renderedState.semanticSummary
  }

  @MainActor
  private func animateSceneChange(to newState: OnboardingVisualState) async {
    guard hasAppeared else {
      previousState = newState
      renderedState = newState
      hasAppeared = true
      return
    }

    let oldState = renderedState
    guard oldState != newState else { return }
    previousState = oldState
    renderedState = newState
    transition = OnboardingSceneTransition.resolve(from: oldState, to: newState)

    sofaArrival = transition == .assembleWatching ? 0.001 : 1
    characterArrival = transition == .assembleWatching ? 0.001 : 1
    televisionArrival = transition == .assembleWatching ? 0.001 : 1
    companionArrival = (transition == .addCompanion || transition == .removeCompanion) ? 0.001 : 1
    finalArrival = 0

    if reduceMotion {
      withAnimation(.easeInOut(duration: 0.18)) { finalArrival = 1 }
      try? await Task.sleep(for: .milliseconds(190))
      guard !Task.isCancelled else { return }
      transition = .none
      return
    }

    switch transition {
    case .assembleWatching:
      withAnimation(.timingCurve(0.18, 0.84, 0.24, 1, duration: 0.48)) { sofaArrival = 1 }
      try? await Task.sleep(for: .milliseconds(310))
      guard !Task.isCancelled else { return }
      withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.52)) { characterArrival = 1 }
      try? await Task.sleep(for: .milliseconds(390))
      guard !Task.isCancelled else { return }
      withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.46)) { televisionArrival = 1 }
      try? await Task.sleep(for: .milliseconds(390))
    case .addCompanion, .removeCompanion:
      withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.46)) { companionArrival = 1 }
      try? await Task.sleep(for: .milliseconds(380))
    case .replaceScene:
      withAnimation(.easeInOut(duration: 0.38)) { finalArrival = 1 }
      try? await Task.sleep(for: .milliseconds(390))
    case .none:
      break
    }

    guard !Task.isCancelled else { return }
    withAnimation(.easeOut(duration: 0.18)) { finalArrival = 1 }
    try? await Task.sleep(for: .milliseconds(190))
    guard !Task.isCancelled else { return }
    transition = .none
  }

}

private enum SceneAssemblyRegion {
  case sofa
  case character
  case television
}

private struct SceneAssemblyMask: View {
  let region: SceneAssemblyRegion
  let progress: CGFloat

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      switch region {
      case .sofa:
        RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
          .frame(width: size.width * 0.72, height: size.height * 0.68)
          .scaleEffect(x: 1, y: progress, anchor: .bottom)
          .position(x: size.width * 0.42, y: size.height * 0.67)
          .blur(radius: 5 * (1 - progress))
      case .character:
        RoundedRectangle(cornerRadius: size.width * 0.1, style: .continuous)
          .frame(width: size.width * 0.48, height: size.height * 0.92)
          .scaleEffect(0.92 + (0.08 * progress), anchor: .center)
          .opacity(progress)
          .position(x: size.width * 0.40, y: size.height * 0.49)
          .blur(radius: 8 * (1 - progress))
      case .television:
        RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
          .frame(width: size.width * 0.36, height: size.height * 0.72)
          .scaleEffect(x: progress, y: 1, anchor: .trailing)
          .opacity(progress)
          .position(x: size.width * 0.86, y: size.height * 0.58)
          .blur(radius: 7 * (1 - progress))
      }
    }
  }
}

private struct CompanionArrivalMask: View {
  let progress: CGFloat

  var body: some View {
    GeometryReader { proxy in
      Ellipse()
        .frame(width: proxy.size.width * 0.78, height: proxy.size.height * 0.88)
        .scaleEffect(0.08 + (0.92 * progress), anchor: .center)
        .opacity(progress)
        .position(x: proxy.size.width * 0.46, y: proxy.size.height * 0.54)
        .blur(radius: 8 * (1 - progress))
    }
  }
}

#Preview("Opening name question") { IndulgeOnboardingView(preset: .welcome) }
#Preview("Name") { IndulgeOnboardingView(preset: .name) }
#Preview("Activities") { IndulgeOnboardingView(preset: .activities) }
#Preview("Reflection") { IndulgeOnboardingView(preset: .reflection) }
