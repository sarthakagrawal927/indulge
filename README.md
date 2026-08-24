# Habits / Indulge — retired predecessor

> **Retired on 2026-08-24.** Anchor is now the sole maintained product for day
> planning, focus timing, interruption evidence, and non-moralizing pattern
> replacement. Continue product work in
> [`Significant-Hobbies/anchor`](https://github.com/Significant-Hobbies/anchor).
> This repository is preserved as recoverable source and data-compatibility
> history; it has no active roadmap.

**Keep what helps. Trade what does not.**

Habits is a native iPhone and iPad experience for keeping the indulgence someone
chooses, trading the time they do not, and watching a fuller life assemble
around one persistent animated character and room.

The current build is a complete local-first Life → Trade → History loop. A
12-beat onboarding identifies where time is being pulled, one deliberate trade
can be created and completed, and real outcomes persist into History. The
customer-facing scene uses bundled original soft-3D plates with native,
Reduce-Motion-aware presentation; the repository also retains the RealityKit
scene engine used to prove the modular 24-indulgence system.

## Historical local development

Requirements:

- Xcode 16 or newer
- XcodeGen 2.46 or newer
- iOS 18.0 or newer (`RealityView` is the minimum-version constraint)

```bash
./scripts/build.sh
INDULGE_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' ./scripts/test.sh
```

The deployment target is iOS 18.0. Local runtime verification uses the oldest
matching runtime installed on the development Mac (currently iOS 26.4) plus the
newest installed runtime. The app does not call RealityKit APIs newer than the
iOS 18 availability boundary.

Historical planning and issues remain for provenance only. Do not start new
product work here.

The native app has no third-party runtime, web view, analytics SDK, remote-model
call, or Cloudflare dependency. SwiftData is authoritative. Properly entitled
signed builds may attempt the configured private CloudKit container and fall
back to local-only storage; cross-device sync is not claimed until it is tested
on two signed devices. The existing Indulge target, bundle ID, CloudKit container,
and SwiftData schema names remain unchanged so current data survives the rename.
Image Playground is the only generative Apple surface in
the current product, and the authored fallback remains complete without it.

## Compatibility surfaces

The Habits and Indulge landings are maintained by the shared `ios-landings`
factory as compatibility surfaces that point to Anchor. The App Store record,
bundle identifier, SwiftData schema, CloudKit container, and Hub `habits`
contracts remain intact until a separately approved migration or deletion.

```bash
pnpm install
pnpm check
pnpm build
pnpm dev
```

Fleet-facing quality scripts live in the root `package.json`: `format:check`,
`lint`, `typecheck`, `test`, `test:coverage`, `knip`, and the `quality:*`
wrappers. Landing types stay on `astro check`. Native tests and coverage stay
on `./scripts/test.sh` / XCTest.

When a verified public TestFlight URL exists, set `PUBLIC_TESTFLIGHT_URL` only
in the build environment. Without it, the site deliberately shows the honest
invite-only beta state.
