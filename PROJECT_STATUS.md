# Habits — Project Status

Last updated: 2026-08-24

## Why / What

**Status: retired / superseded by Anchor.** This repository is historical and
has no active product roadmap. Anchor now owns day planning, recurring routines,
focus timing, interruption evidence, schedule review, and non-moralizing pattern
replacement. Existing Apple identities, local/private stores, Hub contracts,
and public domains remain compatibility resources; no deletion or migration was
performed.

## Dependencies

- SwiftUI for app structure, controls, navigation, and accessibility.
- RealityKit for the persistent modular 3D character and world.
- XcodeGen for deterministic local project generation; it is a development
  tool, not an app runtime dependency.
- Astro for a portable, provider-neutral static public product and trust
  surface. It is not part of the native app runtime.
- Apple Screen Time frameworks are planned after the visual proof and are not
  active dependencies yet.
- `PersonalSyncKit` supplies optional Sign in with Apple, a durable local
  mutation outbox, and Personal Platform synchronization. SwiftData remains
  the immediate store; private CloudKit remains a temporary rollback path.

## Timeline

- **2026-08-24:** Retired Habits/Indulge as a separate product after its useful
  onboarding hero, 24 pattern illustrations, eight life-direction
  illustrations, and behavior-change framing were made self-contained in
  Anchor. The separate Life → Trade → History shell, scene-room system, future
  life card, privacy lock, and duplicate focus journal remain historical source.
  Fleet, Hub, and shared landing sources now identify Anchor as the maintained
  successor. The repository, bundle ID, SwiftData schema, CloudKit container,
  App Store/TestFlight record, domains, and Personal Platform `habits` records
  were preserved for compatibility.

- **2026-08-23:** Prepared Habits 0.1.0 (7) for internal TestFlight with the
  truthful Significant Hobbies Hub scope, waiting-write count, freshness, and
  actionable sync recovery from #38. Upload and Apple processing remain
  separate release gates.

- **2026-08-23:** Separated Apple-private iCloud device continuity from
  Significant Hobbies Hub visibility in Habits settings. Hub sync now states
  its completed-trade/check-in scope, reports actual durable outbox work and
  the last successful sync, and distinguishes session, network, and service
  failures without blocking local use.

- **2026-08-22:** Apple completed processing 0.1.0 (6) and confirmed it
  available to internal TestFlight testers on personal team `8F7LXHTJZR`.
  App Store Connect retains the legacy `Indulge by Significant Hobbies` record;
  the installed application displays the current `Habits` name.

- **2026-08-21:** Habits 0.1.0 (5) completed internal-only TestFlight
  processing on personal team `8F7LXHTJZR`. This build connects completed trades to the
  Cloudflare Personal Platform without adding an account wall or moving the
  immediate SwiftData write. The app can restore an Apple-backed session,
  retry a durable outbox, pull Pace-created check-ins into History, and report
  manual sync state; focused contract tests, the signed distribution package,
  and a stable Xcode 26.6 archive passed.

- **2026-08-21:** Uploaded Habits 0.1.0 (4) from current `main` to internal-only
  TestFlight on personal team `8F7LXHTJZR`. Xcode 26.6 initially exposed a
  Swift 6.3.3 compiler crash for a direct SwiftUI `Binding` setter reference;
  the equivalent explicit closure shipped through PR #26. All 68 unit tests
  passed, all five UI tests executed with only the two hardware-only checks
  skipped, and the inspected distribution IPA used production entitlements,
  `get-task-allow=false`, and no embedded frameworks. Apple processing remains
  the final availability gate.
- **2026-08-21:** Evolved the visible product identity from Indulge to Habits
  while preserving the existing bundle ID, SwiftData schema, CloudKit
  container, target names, and stored directory. The existing Life → Trade →
  History loop remains the first Habits release; no data migration, deployment,
  or TestFlight upload was performed.
- **2026-08-17:** Landing gained a real-screenshot filmstrip, App Store-safe
  structured data, and an honest split between the iPhone app (no analytics)
  and this website (anonymous page views).
- **2026-08-16:** Completed the customer Life → Trade → History loop with a
  versioned SwiftData trade record, deliberate replacement, start and finish,
  three non-judgmental outcomes, relaunch persistence, honest totals, and
  all-data deletion. Shared authored-scene motion now carries onboarding, Life,
  Trade, completion, and History with a crossfade-only Reduce Motion plan.
- **2026-08-16:** Final current-source simulator verification passed 68 unit
  tests and three full UI journeys independently on iOS 26.4, iOS 27.0, and an
  iPad Pro 11-inch simulator; each run skipped only two explicitly
  hardware-only checks. A post-fix physical iPhone run had previously passed
  66 unit tests. Current evidence covers standard, Dark Mode, increased
  contrast, Accessibility XL, Reduce Motion, empty History, completed History,
  iPad safe areas, and simulator relaunch persistence.
- **2026-08-16:** Build 2 was archived with personal team `8F7LXHTJZR`. A
  previous exact development archive installed, launched, relaunched, and
  retained its completed profile on the paired iPhone. The corrected archive
  is signed and inspectable, but its final install remains unclaimed while that
  phone is unavailable to CoreDevice; successful Face ID/passcode completion
  also remains unverified. The archive inspector correctly classifies it as
  development-device—not TestFlight-ready—and the upload script refuses it.
- **2026-08-16:** Retired Focus from the native customer experience and made
  the authored Life room the direct entry into a Trade. Legacy interruption
  records remain only for safe SwiftData and private CloudKit compatibility.
- **2026-08-12:** Aligned the universal iPhone/iPad build's private onboarding
  label and durable product documentation, then refreshed the personal-team
  distribution export.
- **2026-08-08:** Product direction, original soft-form 3D visual world, OpenSpec
  visual-proof change, private GitHub repository, and native project scaffold
  established.
- **2026-08-08:** The first simulator proof established the modular watching
  sequence, detachable companions, 24-item recipe catalog, and continuous
  Now-to-Possible world morph on the oldest installed supported runtime.
- **2026-08-08:** The customer-facing proof was narrowed to a five-beat,
  indulgence-first onboarding: activity selection immediately assembles the
  scene, explicit companions alter it, and chosen versus automatic use is
  recorded before any replacement or good-habit flow appears.
- **2026-08-09:** The onboarding proof expanded into a 12-beat personal
  conversation that opens directly on the optional name question and covers
  identity, genuine pleasures, duration,
  context, need, intentionality, desired life direction, and pace, ending in a
  personalized non-judgmental reflection while keeping good habits deferred.
- **2026-08-11:** The first daily app shell and an experimental Focus
  interruption journal passed their native and design gates. Focus was later
  retired from the customer experience; its model types remain only so an old
  local store can migrate without losing data.
- **2026-08-11:** Distribution preparation completed with an opaque Powder
  Sky/navy/cherry App Store icon, reusable favicon exports, honest beta notes,
  draft App Store metadata and screenshot evidence, and a personal-team signed
  archive. The first internal-only transport reached App Store Connect and
  confirmed that the Indulge app record must be created before upload.
- **2026-08-11:** The Life Room landing and its privacy, support, terms,
  accessibility, TestFlight status, Markdown, and agent-indexing surfaces
  passed CI and design review.
- **2026-08-16:** Removed provider-specific deployment tooling and third-party
  site analytics. The static trust surface remains portable and the native app
  remains independent of any web host.
- **2026-08-16:** Reconciled and archived the original hosted-landing plan. The
  main launch-surface contract now requires deterministic provider-neutral
  output and makes no deployment, DNS, or public-availability claim.
- **2026-08-16:** Uploaded Indulge 0.1.0 to internal TestFlight on personal
  team `8F7LXHTJZR`. The inspected IPA is Apple Distribution signed with
  production push and CloudKit entitlements, `get-task-allow=false`, a valid
  privacy manifest, and no embedded third-party frameworks. Internal testers
  only. No App Store submission.

## Products

- **Anchor:** the maintained successor and only active consumer product.
- **Habits/Indulge native source:** retained historical implementation.
- **Habits and Indulge landings:** retained compatibility surfaces in the shared
  iOS landing factory.

## Features (shipped)

- A private, local 12-beat onboarding conversation with optional identity
  context, a 24-item indulgence catalog, and a non-judgmental reflection.
- A native Life, Trade, and History shell that keeps the selected person, room,
  and visual language coherent across the daily product.
- A scene-led daily interaction: tapping the Life room when an indulgence begins
  opens a small Trade without introducing a tracker dashboard or timer.
- One persisted active trade, explicit replacement, start and completion,
  three humane outcomes, a causal completion pocket, and real History totals.
- Offline manual behavior, optional availability-gated Apple Image Playground,
  Reduce Motion, Dynamic Type, VoiceOver, and Light/Dark support.
- Optional Apple sign-in and Significant Hobbies Hub synchronization for
  completed trades/check-ins, with local-first writes, a visible manual
  refresh path, durable pending-work and last-success state, and truthful
  session/network/service retry guidance.
- App Store identity assets plus an inspected distribution package on
  internal TestFlight. External beta testing and App Store review remain
  separate, unauthorized actions.
- A responsive, zero-client-JavaScript static launch artifact with real app
  proof, plain-language privacy and support, truthful beta availability, and
  stable Markdown, `llms.txt`, and `/api/ai` product truth. Hosting is outside
  the completed scope.

## Work queue

No active roadmap. Historical issues remain at
[GitHub Issues](https://github.com/Significant-Hobbies/indulge/issues).
