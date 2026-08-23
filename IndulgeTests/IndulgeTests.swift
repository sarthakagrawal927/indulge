import Foundation
import RealityKit
import Testing

@testable import Indulge

struct IndulgeTests {
  @Test func completedProfilePersistsForAnAutomaticRelaunch() throws {
    let suiteName = "indulge-profile-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = OnboardingProfileStore(defaults: defaults)
    let profile = OnboardingProfile(
      preferredName: "Maya",
      activities: [.television],
      primaryIndulgence: .television,
      lifeDirections: [.presence]
    )

    store.save(profile)

    #expect(store.load() == profile)
    #expect(IndulgeLaunchRoute.resolve(arguments: ["Indulge"]) == .automatic)
    #expect(IndulgeLaunchRoute.automatic.initialTab == .life)
    #expect(IndulgeAppTab.allCases == [.life, .trade, .history])
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--onboarding"]) == .onboarding
    )
  }

  @Test func illustratedOnboardingMarkerPersistsAfterDismissal() throws {
    let suiteName = "habits-illustrated-onboarding-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = OnboardingProfileStore(defaults: defaults)

    #expect(!store.hasSeenIllustratedOnboarding)
    store.markIllustratedOnboardingSeen()
    #expect(store.hasSeenIllustratedOnboarding)
  }

  @Test func mainJourneyAsksIdentityBeforeShowingACharacter() {
    #expect(PersonalOnboardingStep.allCases.count == 12)
    #expect(
      PersonalOnboardingStep.mainJourney == [
        .name, .gender, .activities, .primaryIndulgence, .timeSpent, .underlyingNeed,
        .lifeDirection, .reflection,
      ])
    #expect(!PersonalOnboardingStep.mainJourney.contains(.commonMoment))
    #expect(!PersonalOnboardingStep.mainJourney.contains(.intentionality))
    #expect(
      PersonalOnboardingStep.deeperJourney == [
        .commonMoment, .startingPattern, .intentionality, .changePace, .reflection,
      ])
  }

  @Test func purposeQuestionNamesTheActionAndAnswersCompleteItsMeaning() {
    for activity in IndulgenceChoice.allCases {
      let profile = OnboardingProfile(activities: [activity], primaryIndulgence: activity)
      let question = PersonalOnboardingStep.underlyingNeed.title(for: profile)

      #expect(question == activity.purposeQuestion)
      #expect(question.contains("what are you looking for?"))
      #expect(!question.contains("feel lately"))
    }

    #expect(IndulgenceNeed.allCases.allSatisfy { $0.title.count > 10 })
    #expect(PersonalOnboardingStep.underlyingNeed.body(for: OnboardingProfile()).isEmpty)
    #expect(
      PersonalOnboardingStep.intentionality.title(for: OnboardingProfile())
        == "How much of that time still feels chosen?")
    #expect(PersonalOnboardingPreset.purpose.step == .underlyingNeed)
    #expect(PersonalOnboardingPreset.purpose.profile.primaryIndulgence == .shortVideo)
    #expect(PersonalOnboardingPreset.purpose.profile.need == nil)
    #expect(!PersonalOnboardingStep.underlyingNeed.isOptional)
    #expect(!PersonalOnboardingStep.underlyingNeed.showsSkipAction)
    #expect(PersonalOnboardingStep.underlyingNeed.actionTitle == "Continue")
  }

  @Test func openingQuestionIsMinimalAndKeyboardEvidenceIsDeterministic() {
    let profile = OnboardingProfile()

    #expect(PersonalOnboardingStep.name.title(for: profile) == "What should we call you?")
    #expect(PersonalOnboardingStep.name.body(for: profile).isEmpty)
    #expect(!PersonalOnboardingStep.name.showsSkipAction)
    #expect(PersonalOnboardingPreset.welcome.focusesTextEntry)
    #expect(PersonalOnboardingPreset.name.focusesTextEntry)
    #expect(PersonalOnboardingPreset.keyboard.step == .name)
    #expect(PersonalOnboardingPreset.keyboard.focusesTextEntry)
    #expect(PersonalOnboardingPreset.keyboard.profile == profile)
  }

  @Test func identityQuestionsAreInclusiveAndExplicit() {
    let empty = OnboardingProfile()
    #expect(empty.canAdvance(from: .name))
    #expect(!empty.canAdvance(from: .gender))
    #expect(!empty.hasExplicitCharacterPresentation)

    var privateProfile = empty
    privateProfile.gender = .preferNotToSay
    #expect(privateProfile.canAdvance(from: .gender))
    #expect(!privateProfile.hasExplicitCharacterPresentation)

    var selfDescribed = empty
    selfDescribed.gender = .selfDescribe
    #expect(!selfDescribed.canAdvance(from: .gender))
    selfDescribed.customGender = "Genderfluid"
    #expect(selfDescribed.canAdvance(from: .gender))

    #expect(OnboardingProfile(gender: .woman).hasExplicitCharacterPresentation)
    #expect(OnboardingProfile(gender: .man).hasExplicitCharacterPresentation)
  }

  @Test func requiredAnswersGateProgressDeterministically() {
    var profile = OnboardingProfile(gender: .preferNotToSay)
    #expect(!profile.canAdvance(from: .activities))
    profile.activities = [.consoleGaming]
    #expect(profile.canAdvance(from: .activities))
    #expect(!profile.canAdvance(from: .primaryIndulgence))
    profile.primaryIndulgence = .consoleGaming
    #expect(profile.canAdvance(from: .primaryIndulgence))
    #expect(!profile.canAdvance(from: .lifeDirection))
    profile.lifeDirections = [.creativity]
    #expect(profile.canAdvance(from: .lifeDirection))
  }

  @Test func skippingAnOptionalBeatRemovesItsPreviousAnswer() {
    var profile = OnboardingProfile(
      preferredName: "Maya",
      gender: .selfDescribe,
      customGender: "Genderfluid",
      dailyTime: .twoHours,
      need: .comfort,
      lifeDirections: [.creativity]
    )

    profile.clearAnswer(for: .name)
    profile.clearAnswer(for: .gender)
    profile.clearAnswer(for: .timeSpent)
    profile.clearAnswer(for: .underlyingNeed)
    profile.clearAnswer(for: .lifeDirection)

    #expect(profile.preferredName.isEmpty)
    #expect(profile.gender == nil)
    #expect(profile.customGender.isEmpty)
    #expect(profile.dailyTime == nil)
    #expect(profile.need == nil)
    #expect(profile.lifeDirections.isEmpty)
  }

  @Test func everyChoiceGetsItsOwnArtworkStateUntilACompatibleSceneCanAssemble() {
    var profile = OnboardingProfile(activities: [.consoleGaming], primaryIndulgence: .consoleGaming)
    #expect(profile.visualState == .gaming)

    profile.activities = [.shortVideo]
    profile.primaryIndulgence = .shortVideo
    #expect(profile.visualState == .scrolling)

    profile.activities.insert(.television)
    profile.primaryIndulgence = .television
    #expect(profile.visualState == .watchingTelevision(phone: true, drink: false))
  }

  @Test func timeDrainQuestionAndScrollingPreviewMatchTheProduct() {
    let profile = PersonalOnboardingPreset.scrolling.profile

    #expect(
      PersonalOnboardingStep.activities.title(for: profile)
        == "What takes more of your time than you want?")
    #expect(PersonalOnboardingStep.activities.chapterTitle == "Where your time goes")
    #expect(PersonalOnboardingPreset.scrolling.step == .activities)
    #expect(profile.activities == [.shortVideo])
    #expect(profile.visualState == .scrolling)
  }

  @Test func choosingAnActivityChangesTheRoomImmediatelyAndDeterministically() {
    var profile = OnboardingProfile()

    profile.toggleActivity(.television)
    #expect(profile.activities == [.television])
    #expect(profile.primaryIndulgence == .television)
    #expect(profile.visualState == .watchingTelevision(phone: false, drink: false))

    profile.toggleActivity(.shortVideo)
    #expect(profile.primaryIndulgence == .shortVideo)
    #expect(profile.visualState == .watchingTelevision(phone: true, drink: false))

    profile.toggleActivity(.alcohol)
    #expect(profile.primaryIndulgence == .alcohol)
    #expect(profile.visualState == .watchingTelevision(phone: true, drink: true))

    profile.toggleActivity(.shortVideo)
    #expect(profile.visualState == .watchingTelevision(phone: false, drink: true))
  }

  @Test func activityEvidencePresetShowsTheImmediateFirstValue() {
    let profile = PersonalOnboardingPreset.activities.profile

    #expect(!profile.activities.isEmpty)
    #expect(profile.primaryIndulgence == .television)
    #expect(profile.visualState == .watchingTelevision(phone: true, drink: true))
  }

  @Test func reflectionPresetRepresentsTheCompletedMainJourney() {
    let profile = PersonalOnboardingPreset.reflection.profile

    #expect(profile.primaryIndulgence == .television)
    #expect(profile.dailyTime == .twoHours)
    #expect(profile.need == .comfort)
    #expect(profile.intentionality == .mixed)
    #expect(!profile.lifeDirections.isEmpty)
    #expect(profile.gender == .woman)
    #expect(profile.commonMoments == [.evening])
    #expect(profile.startingPattern == .autopilot)
    #expect(profile.pace == .gentle)
  }

  @Test func appLaunchRoutesAreDeterministicAndAutomaticRelaunchIsTheDefault() {
    #expect(IndulgeLaunchRoute.resolve(arguments: ["Indulge"]) == .automatic)
    #expect(IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--review"]) == .review)
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--app-life"])
        == .application(tab: .life, activeTrade: false))
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--app-trade"])
        == .application(tab: .trade, activeTrade: false))
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--app-trade-active"])
        == .application(tab: .trade, activeTrade: true))
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--app-history"])
        == .application(tab: .history, activeTrade: false))
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--app-history-complete"])
        == .completedHistory)
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--app-focus"])
        == .application(tab: .life, activeTrade: false))
    #expect(
      IndulgeLaunchRoute.resolve(arguments: ["Indulge", "--app-focus-interrupted"])
        == .application(tab: .life, activeTrade: false))
  }

  @MainActor
  @Test func firstTradeSuggestionStartsModestlyFromSelfReportedTime() {
    #expect(ReclaimTarget.suggested(for: nil) == .fifteen)
    #expect(ReclaimTarget.suggested(for: .underThirty) == .fifteen)
    #expect(ReclaimTarget.suggested(for: .aboutOneHour) == .fifteen)
    #expect(ReclaimTarget.suggested(for: .twoHours) == .thirty)
    #expect(ReclaimTarget.suggested(for: .threePlus) == .fortyFive)

    let trade = IndulgeAppShell.makeSuggestedTrade(for: .appPreview)
    #expect(trade?.indulgence == .television)
    #expect(trade?.reclaimTarget == .thirty)
    #expect(trade?.destination == .presence)
    #expect(trade?.startedAt == nil)

    let sleepFirst = OnboardingProfile(
      activities: [.shortVideo],
      primaryIndulgence: .shortVideo,
      lifeDirections: [.creativity, .sleep]
    )
    #expect(IndulgeAppShell.makeSuggestedTrade(for: sleepFirst)?.destination == .sleep)
  }

  @Test func everyLifeDirectionHasDistinctAuthoredArtwork() throws {
    var payloads = Set<Data>()

    for direction in LifeDirection.allCases {
      #expect(direction.artworkAssetName == direction.rawValue)
      let url = try #require(
        Bundle.main.url(forResource: direction.artworkAssetName, withExtension: "png"))
      let data = try Data(contentsOf: url)
      #expect(data.count > 100_000)
      payloads.insert(data)
    }

    #expect(payloads.count == LifeDirection.allCases.count)
  }

  @Test func onboardingReflectionCanAdvanceIntoTheProductWithoutInventedProgress() {
    let profile = PersonalOnboardingPreset.reflection.profile

    #expect(profile.canAdvance(from: .reflection))
    #expect(PersonalOnboardingStep.reflection.actionTitle == "Start with this")
    #expect(profile.primaryIndulgence != nil)
    #expect(IndulgeLaunchRoute.application(tab: .life, activeTrade: false).opensApplication)
    #expect(IndulgeLaunchRoute.completedHistory.opensApplication)
    #expect(IndulgeLaunchRoute.completedHistory.initialTab == .history)
    #expect(IndulgeLaunchRoute.completedHistory.startsWithCompletedTrade)
    #expect(!IndulgeLaunchRoute.onboarding.startsWithActiveTrade)
  }

  @Test func standingAndTelevisionPlatesCarryBothPresentations() throws {
    for presentation in ["Feminine", "Masculine"] {
      let standingURL = try #require(
        Bundle.main.url(forResource: "SceneStanding\(presentation)", withExtension: "png"))
      let watchingURL = try #require(
        Bundle.main.url(forResource: "SceneTelevision\(presentation)", withExtension: "png"))
      let standing = try Data(contentsOf: standingURL)
      let watching = try Data(contentsOf: watchingURL)

      #expect(standing.count > 10_000)
      #expect(watching.count > 10_000)
      #expect(standing != watching)
    }
  }

  @Test func lifeHeroIncludesAPortraitTelevisionComposition() throws {
    let url = try #require(
      Bundle.main.url(forResource: "SceneStackFemininePortrait", withExtension: "png"))
    #expect(try Data(contentsOf: url).count > 100_000)
  }

  @Test func everyVisibleFamilyChoiceHasARealSceneAndBothPresentations() throws {
    #expect(OnboardingActivityFamily.visibleActivities.count == 24)
    #expect(Set(OnboardingActivityFamily.visibleActivities).count == 24)
    #expect(OnboardingActivityFamily.allCases.count == 8)

    for family in OnboardingActivityFamily.allCases {
      #expect(!family.activities.isEmpty)
    }

    for presentation in ["Feminine", "Masculine"] {
      for scene in [
        "SceneScrolling", "SceneBrowsing", "SceneGaming", "SceneListening", "SceneTaste",
        "SceneRest", "SceneSocial",
      ] {
        let url = try #require(
          Bundle.main.url(forResource: "\(scene)\(presentation)", withExtension: "png"))
        #expect(try Data(contentsOf: url).count > 10_000)
      }
    }

    #expect(
      OnboardingProfile(activities: [.webBrowsing], primaryIndulgence: .webBrowsing).visualState
        == .browsing)
    #expect(
      OnboardingProfile(activities: [.consoleGaming], primaryIndulgence: .consoleGaming).visualState
        == .gaming)
    #expect(
      OnboardingProfile(activities: [.socialFeeds], primaryIndulgence: .socialFeeds).visualState
        == .scrolling)
    #expect(
      OnboardingProfile(activities: [.music], primaryIndulgence: .music).visualState == .listening)
    #expect(
      OnboardingProfile(activities: [.snacking], primaryIndulgence: .snacking).visualState == .taste
    )
    #expect(
      OnboardingProfile(activities: [.napping], primaryIndulgence: .napping).visualState == .rest)
    #expect(
      OnboardingProfile(activities: [.videoCalls], primaryIndulgence: .videoCalls).visualState
        == .social)

    for activity in OnboardingActivityFamily.visibleActivities {
      let state = OnboardingProfile(activities: [activity], primaryIndulgence: activity).visualState
      #expect(state != .standing)
    }
  }

  @Test func everyVisibleIndulgenceHasAuthoredArtwork() throws {
    #expect(IndulgenceChoice.allCases.count == 24)

    for activity in IndulgenceChoice.allCases {
      let url = try #require(
        Bundle.main.url(forResource: activity.selectorAssetName, withExtension: "png"))
      #expect(try Data(contentsOf: url).count > 1_000)
    }
  }

  @Test func feminineAndMasculineSceneStacksHaveEquivalentStates() throws {
    let states = [
      "SceneStanding", "SceneTelevision", "SceneTelevisionPhone", "SceneTelevisionDrink",
      "SceneStack",
    ]
    for state in states {
      let feminine = try #require(
        Bundle.main.url(forResource: "\(state)Feminine", withExtension: "png"))
      let masculine = try #require(
        Bundle.main.url(forResource: "\(state)Masculine", withExtension: "png"))
      #expect(try Data(contentsOf: feminine).count > 10_000)
      #expect(try Data(contentsOf: masculine).count > 10_000)
      #expect(try Data(contentsOf: feminine) != Data(contentsOf: masculine))
    }

    #expect(OnboardingProfile(gender: .woman).characterPresentation == .feminine)
    #expect(OnboardingProfile(gender: .man).characterPresentation == .masculine)
  }

  @Test func reflectionUsesThePersonsOwnPatternWithoutJudgment() {
    let profile = OnboardingProfile(
      preferredName: "Maya",
      gender: .woman,
      activities: [.television],
      primaryIndulgence: .television,
      dailyTime: .twoHours,
      commonMoments: [.evening],
      startingPattern: .autopilot,
      need: .comfort,
      intentionality: .mixed,
      lifeDirections: [.creativity],
      pace: .gentle
    )

    #expect(profile.reflectionTitle.contains("Maya"))
    #expect(profile.reflectionBody.contains("watching tv"))
    #expect(profile.reflectionBody.contains("around two hours"))
    #expect(profile.reflectionBody.contains("comfort"))
    #expect(profile.reflectionBody.contains("creativity"))
    #expect(profile.reflectionBody.contains("run on its own"))
    #expect(profile.reflectionBody.contains("gentle shift"))
  }

  @Test func commonMomentsCanBeCombinedAndRemovedIndependently() {
    var profile = OnboardingProfile(commonMoments: [.morning, .breaks, .lateNight])

    #expect(profile.canAdvance(from: .commonMoment))
    #expect(profile.commonMomentSummary == "in the morning, during breaks, and late at night")

    profile.commonMoments.remove(.breaks)
    #expect(profile.commonMoments == [.morning, .lateNight])
    #expect(profile.commonMomentSummary == "in the morning and late at night")

    profile.commonMoments.removeAll()
    #expect(profile.canAdvance(from: .commonMoment))
  }

  @Test func catalogHasOneRecipePerSupportedIndulgence() {
    #expect((20...30).contains(IndulgenceCatalog.recipes.count))
    #expect(Set(IndulgenceCatalog.recipes.map(\.id)).count == IndulgenceCatalog.recipes.count)
    #expect(Set(IndulgenceCatalog.recipes.map(\.id)) == Set(IndulgenceID.allCases))
  }

  @Test func everyRecipeHasACompleteArrivalAndValidDefaults() {
    for recipe in IndulgenceCatalog.recipes {
      #expect(recipe.arrivalPhases.first == .stage)
      #expect(recipe.arrivalPhases.last == .settle)
      #expect(Set(recipe.arrivalPhases).count == recipe.arrivalPhases.count)
      #expect(SceneCompatibility.socketsByPose[recipe.basePose] != nil)

      for companion in recipe.defaultCompanions {
        #expect(IndulgenceCatalog.companionRecipes[companion] != nil)
        #expect(!companion.explicitOnly)
      }
    }
  }

  @Test func sensitiveCompanionsAreNeverDefaults() {
    #expect(!IndulgenceCatalog.defaultCompanions.contains(.wineGlass))
    #expect(!IndulgenceCatalog.defaultCompanions.contains(.smoking))
    #expect(!IndulgenceCatalog.recipes.flatMap(\.defaultCompanions).contains(.wineGlass))
    #expect(!IndulgenceCatalog.recipes.flatMap(\.defaultCompanions).contains(.smoking))
  }

  @Test func compatibilityUsesStableFallbackAndCanOmitImpossibleProps() throws {
    let standing = try #require(IndulgenceCatalog.byID[.windowShopping])
    let phone = SceneCompatibility.resolve(
      recipe: standing,
      requested: .phone,
      companionRecipes: IndulgenceCatalog.companionRecipes
    )
    #expect(phone.companion == .attached(.phone, .rightHand))

    let headphones = SceneCompatibility.resolve(
      recipe: standing,
      requested: .headphones,
      companionRecipes: IndulgenceCatalog.companionRecipes
    )
    #expect(headphones.companion == .omitted(.headphones))
  }

  @Test func multiCompanionResolutionIsStableAndNeverCollides() throws {
    let television = try #require(IndulgenceCatalog.byID[.television])
    let first = SceneCompatibility.resolve(
      recipe: television,
      requested: [.phone, .wineGlass, .smoking, .snackBowl, .controller],
      companionRecipes: IndulgenceCatalog.companionRecipes
    )
    let second = SceneCompatibility.resolve(
      recipe: television,
      requested: [.controller, .snackBowl, .smoking, .wineGlass, .phone],
      companionRecipes: IndulgenceCatalog.companionRecipes
    )

    #expect(first == second)
    let occupiedSockets = first.companions.compactMap { resolution -> PropSocket? in
      guard case .attached(_, let socket) = resolution else { return nil }
      return socket
    }
    #expect(Set(occupiedSockets).count == occupiedSockets.count)
    #expect(first.companions.contains(.attached(.phone, .rightHand)))
    #expect(first.companions.contains(.attached(.smoking, .leftHand)))
    #expect(first.companions.contains(.attached(.snackBowl, .lap)))
  }

  @Test func onboardingSceneTransitionsPreserveTheCausalGrammar() {
    #expect(
      OnboardingSceneTransition.resolve(
        from: .standing,
        to: .watchingTelevision(phone: false, drink: false)
      ) == .assembleWatching)
    #expect(
      OnboardingSceneTransition.resolve(
        from: .watchingTelevision(phone: false, drink: false),
        to: .watchingTelevision(phone: true, drink: false)
      ) == .addCompanion)
    #expect(
      OnboardingSceneTransition.resolve(
        from: .watchingTelevision(phone: true, drink: true),
        to: .watchingTelevision(phone: false, drink: true)
      ) == .removeCompanion)
    #expect(
      OnboardingSceneTransition.resolve(
        from: .gaming,
        to: .browsing
      ) == .replaceScene)
  }

  @Test func sceneProgressAndWeekAreNormalized() {
    let state = LifeSceneState(possibleProgress: 2.4, historyWeek: -3)
    #expect(state.possibleProgress == 1)
    #expect(state.historyWeek == 1)
  }

  @Test func reducedMotionAlwaysUsesOrderedInPlacePresentation() {
    for transition in HeroTransition.allCases {
      let plan = SceneTransitionCatalog.plan(for: transition, reduceMotion: true)
      #expect(plan.pausesAmbientMotion)
      #expect(!plan.beats.isEmpty)
      #expect(
        plan.beats.allSatisfy { $0.presentation == .inPlaceCrossfade || $0.presentation == .settle }
      )
    }
  }

  @Test func interruptedTransitionInvalidatesItsGeneration() {
    var generation = TransitionGeneration()
    let first = generation.begin()
    #expect(generation.isCurrent(first))
    let second = generation.begin()
    #expect(!generation.isCurrent(first))
    #expect(generation.isCurrent(second))
  }

  @Test func coordinatorMapsHistoryAndGraduationIntoOneWorld() {
    let history = LifeSceneCoordinator.composition(for: .historyWeekFour)
    #expect(history.assembly == .settled)
    #expect(history.possibleProgress >= 0.72)
    #expect(history.semanticSummary.contains("weeks"))

    let graduation = LifeSceneCoordinator.composition(for: .graduated)
    #expect(graduation.possibleProgress == 1)
    #expect(graduation.semanticSummary.contains("steps beyond"))
  }

  @Test @MainActor func proceduralSceneKeepsEveryRequiredRoleAndConnectedJointChain() throws {
    let root = SoftFormScene.makeRoot()
    let loader = SceneAssetRoleLoader(root: root)

    #expect(loader.containsEveryRequiredRole())

    let leftForearm = try #require(loader.entity(for: .leftForearm))
    let rightForearm = try #require(loader.entity(for: .rightForearm))
    let leftHand = try #require(loader.entity(for: .leftHand))
    let rightHand = try #require(loader.entity(for: .rightHand))
    let leftKnee = try #require(loader.entity(for: .leftKnee))
    let rightKnee = try #require(loader.entity(for: .rightKnee))
    let wineGlass = try #require(loader.entity(for: .wineGlass))

    #expect(leftForearm.parent?.name == SoftFormScene.Role.leftArm.rawValue)
    #expect(rightForearm.parent?.name == SoftFormScene.Role.rightArm.rawValue)
    #expect(leftHand.parent === leftForearm)
    #expect(rightHand.parent === rightForearm)
    #expect(leftKnee.parent?.name == SoftFormScene.Role.leftLeg.rawValue)
    #expect(rightKnee.parent?.name == SoftFormScene.Role.rightLeg.rawValue)
    #expect(wineGlass.parent?.name == SoftFormScene.Role.rightHandSocket.rawValue)
  }

  @Test @MainActor func proceduralSceneGroundsObjectsAndUsesLayeredLighting() {
    let root = SoftFormScene.makeRoot()

    for contactShadow in [
      "sofa-contact-shadow",
      "television-contact-shadow",
      "lamp-contact-shadow",
      SoftFormScene.Role.avatarShadow.rawValue,
      "arch-contact-shadow",
      "books-contact-shadow",
      "making-contact-shadow",
      "plant-contact-shadow",
      "connection-contact-shadow",
    ] {
      #expect(root.findEntity(named: contactShadow) != nil)
    }

    for light in ["key-light", "sky-fill", "warm-rim"] {
      #expect(root.findEntity(named: light) != nil)
    }
  }
}
