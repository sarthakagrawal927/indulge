# Product

> **Retired product specification (2026-08-24).** Anchor owns the maintained
> schedule, focus, interruption, and behavior-change experience. This document
> records the predecessor product and must not be treated as an active roadmap.

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

People who repeatedly spend longer than intended scrolling, streaming, gaming,
or browsing and want a kinder way to reclaim some of that time without giving
up the enjoyment they deliberately choose.

The product is used privately on an iPhone, often at the edge of an automatic
digital habit or when reflecting on how time was spent.

## Product Purpose

Habits helps a person notice one automatic digital escape, decide how much of
it they genuinely want to keep, trade a modest amount of unchosen time for a
satisfying alternative, and watch those alternatives become part of a living
representation of their life.

Success is not abstinence. It is more meaningful replacement sessions, fewer
episodes that last longer than intended, and eventual graduation from the
intervention when a new rhythm feels natural.

## Positioning

Habits makes reclaimed time emotionally visible as an expanding life scene.
It never treats intentional indulgence as failure and is designed to be
outgrown rather than retained through guilt, streaks, or competitive pressure.

## Operating Context

- One active manual trade at a time: a selected indulgence, a modest reclaim
  duration, and one desired life direction.
- One persistent life scene across onboarding, daily use, history, and
  graduation.
- First run builds a private local profile through optional identity, activities
  that repeatedly take longer than intended, time, context, need, intentionality, desired life direction, and
  preferred pace. It reflects the pattern back without diagnosis or a score.
- Significant Hobbies is a potential source for the replacement-activity
  library and a possible post-graduation next chapter, not the host app.

## Capabilities and Constraints

- Native SwiftUI iPhone app with local-first persistence and no account wall;
  optional Sign in with Apple connects private Cloudflare synchronization.
- Name and gender are optional onboarding context. Gender supports
  self-description and prefer-not-to-say; neither answer is used to infer
  behavior or prescribe a different intervention.
- One active trade; completion records whether the person made room, chose the
  indulgence intentionally, or left it for another day. None is treated as failure.
- V1 visual coverage targets a curated library of roughly 20–30 indulgence
  scenes assembled from reusable poses, furniture clusters, and companion props.
- Life, Trade, and History are the primary V1 surfaces; graduation removes
  Trade while preserving Life and History.
- The Life scene is an action, not decoration: activating the room moves
  directly into an intentional Trade without introducing a tracker dashboard.
- A future-life card is an optional post-onboarding keepsake presented through
  Apple's system Image Playground sheet. It uses only selected life directions,
  is copied into app-owned storage after success, and can be replaced or deleted.
  Generated imagery never replaces the authored character or room.
- Privacy Lock is off by default. If enabled after successful device-owner
  authentication, it obscures private profile, Trade, and History content whenever
  the app leaves the active state, then requires authentication after the selected
  relock interval. It supports Face ID, Touch ID, or device-passcode fallback.
- Cloudflare Personal Platform is the long-term shared sync path. Private
  CloudKit remains temporarily enabled for rollback while SwiftData stays the
  immediate local store. Simulator, preview, test, signed-out, failed-service,
  and offline paths keep local recording usable.
- Core functionality works offline. The current build does not request Screen
  Time access, monitor application switching, or call a remote model. Completed
  trades sync only after the owner explicitly connects the app.
- The app must support Dynamic Type, VoiceOver, Dark Mode, increased contrast,
  and Reduce Motion.
- User-declared alcohol or smoking context may be mirrored neutrally as a scene
  companion prop. The app does not recommend substance pairings, treat substance
  dependence, score consumption, or present clinical guidance.
- V1 excludes clinical addiction support, gambling intervention, Android,
  social features, competition, AI coaching, automatic app monitoring, complex
  analytics, large avatar creation, and multiple simultaneous trades.

## Brand Commitments

- Name: Habits.
- Working tagline: “Keep what helps. Trade what does not.”
- Product promise: keep the indulgence you choose, trade the time you lose, and
  see a fuller life take shape.
- Voice is intimate, adult, calm, non-moralizing, and free of shame, shock
  statistics, punishment, or forced optimism.
- The primary experience is an emotionally legible animated life scene, not a
  dashboard or a habit tracker decorated with illustrations.

## Evidence on Hand

- The owner-provided V1 visual and animation brief is at
  `/Users/sarthak/Downloads/indulge_ios_visual_prd.md`.
- Significant Hobbies issue #65 records the product boundary and research
  relationship but is reference-only, not Habits’ operational work queue.
- The repository contains authored scene plates, a shipping app icon, and
  prepared App Store screenshots. No reusable production 3D character rig,
  user research, testimonials, benchmarks, or analytics exist yet and none may
  be fabricated as evidence.

## Product Principles

1. Trade and limit; never ban by default.
2. Express progress as more life, never as punishment or scene decay.
3. Make the replacement easier to choose when the user is tired.
4. Let animation prove emotional causality rather than merely decorate state.
5. Preserve dignity and intentional pleasure all the way through graduation.

## Accessibility & Inclusion

The same stylized adult character persists through the journey and supports
inclusive silhouettes, skin tones, hair, clothing, and accessibility variants.
Growth is shown through action, environment, and presence—not body change,
beauty reward, or a “before” character portrayed as pathetic. The full product
must remain understandable and satisfying with Reduce Motion enabled.
