---
title: Indulge — iOS visual PRD (external experiment)
description: A digital-wellbeing iOS app concept with a living diorama. Preserved as a research document for potential cross-pollulation with the Significant Hobbies mortality frame and replacement-activity system.
date: 2026-08-06
status: reference-only
---

# Indulge — iOS Design & Animation PRD

> **Why this is here.** Indulge is a separate product concept — a
> digital-wellbeing iOS app, not a Significant Hobbies feature. This PRD is
> preserved in `docs/research/` because the two products share a
> philosophical core: help people spend less time on automatic habits and
> more time on intentional, meaningful activities. The mortality frame
> (life grid) and the Significant Hobbies hobby-discovery corpus could
> eventually feed Indulge's replacement-activity system, and Indulge's
> "trade, never moralize" stance is a useful counterpoint to
> Significant Hobbies' aspirational tone. No code from this PRD has been
> merged into the Significant Hobbies codebase.

## Status

V1 build brief. Native iOS.

Working tagline: **Enjoy on purpose.**

Product promise: Keep the indulgence you choose, trade the time you lose,
and see a fuller life take shape.

## 1. Product

Indulge is an iOS app for people who repeatedly lose more time than intended
to scrolling, streaming, gaming, or browsing.

It does **not** ask users to quit. It helps them:

1. Notice one automatic digital escape.
2. Choose how much of it they genuinely want to keep.
3. Trade a small amount of unchosen time for satisfying alternatives.
4. See those alternatives become a beautiful animated representation of the
   life they are building.
5. Outgrow the intervention once the new rhythm feels natural.

The product must feel like an intimate animated film, not a habit tracker
with illustrations added afterward.

> The animation is the product's emotional proof that the user is gaining a
> life, not merely losing screen time.

## 2. V1 decisions

| Area | V1 decision |
|---|---|
| Platform | Native iPhone app built with SwiftUI |
| Core behavior | Trade and limit; never ban by default |
| Active plans | One active trade at a time |
| Initial indulgences | User-selected apps and websites through Apple Screen Time APIs |
| Replacements | A small context-aware library connected to Significant Hobbies |
| Primary interface | One persistent animated life scene |
| Progress | Activities, objects, spaces, and memories added to the scene |
| Failure | No streak loss, scene decay, guilt, or sad character |
| Account | No account required |
| Storage | Local-first |
| Graduation | Intervention stops; Life and History remain |

### Out of scope

- Alcohol, weed, nicotine, gambling, or clinical addiction support
- Android
- Social feeds, leaderboards, accountability partners, or competitive gamification
- AI chatbot or life coach
- Large avatar creator
- Multiple simultaneous trade plans
- Complex analytics dashboards

## 3. Design north star

Indulge should be the prettiest digital-wellbeing app on iOS.

The user opens into a softly animated **2.5D living diorama** of their life.
At first, the room is comfortable but visually compressed around the
selected indulgence: screen glow dominates, the character repeats a passive
loop, and other parts of life remain empty or underused.

As the user completes replacements:

- A guitar, book, plant, sketchbook, running shoes, project artifact,
  photograph, or cooking object appears.
- The character begins using those objects.
- The room opens into new zones.
- The window, exterior, desk, shelves, and social spaces become more alive.
- Memories accumulate.
- The phone, couch, console, or television remain; they simply stop
  occupying the whole composition.

Progress is expressed as **more life**, not a brighter "good" room replacing
a dark "bad" room.

### Visual tone

- Adult editorial illustration
- Cinematic and intimate
- Soft 2.5D depth
- Rounded, tactile geometry
- Diffuse light and subtle texture
- Calm ambient motion
- Restrained UI layered over the world
- No generic SaaS illustration
- No childish mascot
- No hyper-real game avatar
- No neon productivity gradients

## 4. Character direction

The character is the emotional anchor of the product. It must feel human
enough to create recognition, but abstract enough for users to project
themselves onto it.

### Character rules

- Stylized adult proportions
- Minimal facial detail; emotion comes mainly from posture and movement
- Inclusive silhouettes, skin tones, hair, and clothing
- The same character appears throughout the journey
- No body transformation, glow-up, weight loss, or beauty reward
- The initial character is not pathetic; they are comfortable, tired,
  absorbed, or drifting
- Growth is shown through action, environment, and presence

### Required character sketch pack before production

Create these sketches before building the final Rive rig:

1. Three visual directions for the character and room style.
2. Twenty thumbnail silhouettes exploring proportions and posture.
3. Turnaround sheet: front, three-quarter, side, and seated views.
4. Core passive poses: scrolling, watching, gaming, browsing, lying down.
5. Core active poses: walking, stretching, reading, creating, cooking,
   calling, focused work, intentional rest.
6. Posture/emotion sheet: drained, restless, comforted, absorbed, curious,
   engaged, calm, connected.
7. Hair, skin-tone, clothing, and accessibility variants.
8. Room composition sketches showing present life, possible life, mature
   life, and graduated life.
9. Onboarding storyboard covering every major camera and character
   transition.
10. Three color and lighting studies: day, dusk, and night.

Do not start by drawing dozens of hobby-specific characters. One shared rig
should support all V1 actions through reusable poses, props, and scene
modules.

## 5. Onboarding — the hero experience

Onboarding is the most important part of V1. It must create recognition,
emotional tension, hope, and trust before asking for Screen Time permission.

### Screen 1 — Opening scene

A character sits in a softly animated room, absorbed by a screen.

**Copy:**
**What do you disappear into?**
Not everything you enjoy is a problem. Choose what often lasts longer than
you meant.

### Screen 2 — Choose one indulgence

Present five illustrated archetypes:

- Short-form video
- Social feeds
- Streaming
- Gaming
- Browsing/news

Each selection immediately changes the character's pose, prop, screen light,
and ambient loop.

### Screen 3 — Chosen versus automatic

Ask:

**How much of it still feels chosen?**

The user confirms an approximate daily range and selects whether most, half,
or little of it feels intentional. Avoid red warnings, "years lost," and
shock statistics.

### Screen 4 — Identify the need

Ask:

**What are you usually looking for?**

Options:

- Decompression
- Stimulation
- Comfort
- Connection
- Avoidance
- Quiet
- A sense of progress

The room subtly reacts to the selected need through posture, pacing, light,
and peripheral objects.

### Screen 5 — Choose a character

Offer a small set of beautifully designed character presets. This should
take seconds, not become an avatar editor.

### Screen 6 — Present-life reveal

The camera pulls back and composes the user's current scene from their
indulgence, need, time, and character.

**Copy:**
**This is not a bad life.**
It may simply be taking up more room than you chose.

This frame must be strong enough to serve as an App Store screenshot.

### Screen 7 — Make a trade

A tactile control lets the user decide how much time to keep and how much to
reclaim.

**Copy:**
**Keep what you enjoy. Trade what you do not.**

As the control moves:

- Screen glow contracts slightly.
- The window opens.
- Empty space appears for possible activities.
- The indulgence remains visible.

Default to reclaiming only a modest amount, approximately 15–25% of
unchosen time.

### Screen 8 — Choose replacements

Show a finite deck of activities matched to need, time, energy, and place.

The user chooses three:

- One possible in five minutes
- One possible when drained
- One personally meaningful option

**Copy:**
**Choose what tired-you might actually do.**

### Screen 9 — Future-life preview

The same room transforms using the selected replacements. The user drags a
**Now ↔ Possible** control to scrub between versions.

**Copy:**
**Not less pleasure. More life.**

### Screen 10 — iOS permissions

Only after the future is visible:

1. Explain Screen Time access.
2. Open Apple's activity picker.
3. Request notifications only when the user enables interventions.
4. Create the first trade.

If permission is denied, the app continues in manual mode.

## 6. Core iOS experience

### Life

The default tab opens directly into the animated world — not a dashboard.

The top two-thirds of the screen is the diorama. A restrained bottom tray
contains one contextual action.

Examples:

- **Before the trigger:** "Tonight, one small trade is waiting."
- **At the moment of drift:** "What would help right now?"
- **After a walk:** "You added a 15-minute walk to this week."
- **After intentional continuation:** "You chose 10 more minutes. Enjoy
  them."

Tapping an object opens its history. A book shows reading sessions; shoes
show walks; a photograph shows connection moments.

### Trade

Contains only:

- Selected apps/websites
- Chosen limit and schedule
- Three current replacement options
- Intentional extension duration
- Pause, tune, or graduate

### History

A visual filmstrip of weekly scene snapshots. Scrubbing through time morphs
the room between earlier and current states.

Charts may exist behind a details screen, but they are never the primary
representation.

### Screen Time intervention

When the user reaches the limit they chose:

**You reached the limit you chose.**
Continue deliberately, or leave it here for now.

Actions:

- Close for now
- 10 more intentional minutes

Continuing is not failure. Repeated extensions lead to plan tuning, not
punishment.

### Graduation

Once the user feels stable:

**You built a rhythm that no longer needs supervision.**

Graduation:

- Stops shields and intervention notifications
- Removes Trade from primary navigation
- Leaves only Life and History
- Preserves the scene and transformation timeline
- Offers a quiet "Start a new trade" option in Settings

The app is designed to be **outgrown**, not abandoned in guilt.

## 7. Replacement system

Activities map into eight visual families so one animation system can
represent many hobbies:

| Family | Examples | Scene result |
|---|---|---|
| Move | Stretch, workout, dance | Mat, shoes, open floor |
| Outside | Walk, sunlight, errand | Window/door opens, outdoor path |
| Read | Book, study, long-form reading | Book, lamp, growing shelf |
| Create | Instrument, drawing, writing | Instrument, wall art, sketchbook |
| Make | Cooking, crafts, building | Worktop, tools, finished object |
| Connect | Call, meet, play together | Photo, second figure, shared space |
| Restore | Tea, shower, quiet rest | Soft light, cup, cleared surface |
| Progress | Project, course, practice | Desk, project artifact, notes |

Recommendations use four inputs:

- Need
- Time available
- Energy
- Place

Show exactly three options. Never create an infinite content feed inside an
app intended to reduce drifting.

## 8. Animation system

Use **Rive embedded in SwiftUI** for the persistent character and world.
SwiftUI owns navigation, controls, sheets, typography, accessibility, and
system integrations.

### Hero animations

These deserve the most design and polish:

1. Present-life reveal
2. Trade slider transforming the room
3. Now ↔ Possible scrub
4. Replacement completion adding an object or action
5. Weekly scene morph
6. Graduation reveal

### Ambient animation

Use quiet loops such as:

- Breathing and posture shifts
- Screen glow
- Curtain or plant movement
- Distant outdoor lights
- Character glances and object interaction

Only two or three ambient elements should move at once. The app must feel
alive, not busy.

### Motion principles

- Motion must communicate causality or emotion.
- Interactions should feel tactile and interruptible.
- Major transformations should last roughly 1–2 seconds.
- Utility transitions should be fast and native-feeling.
- Use subtle haptics when a trade is selected or an object settles into the
  scene.
- Support Reduce Motion with crossfades and in-place state changes.
- Maintain smooth performance and reasonable battery use on the oldest
  supported iPhone.

## 9. iOS implementation

### Recommended stack

- SwiftUI
- Rive state machine
- SwiftData/local persistence
- FamilyControls
- DeviceActivity
- ManagedSettings and ManagedSettingsUI
- WidgetKit and App Intents for fast replacement access
- UserNotifications
- App Group storage for extensions

### Required targets

1. Main iOS app
2. Device Activity Monitor extension
3. Device Activity Report extension
4. Shield Configuration extension
5. Shield Action extension
6. Optional widget extension

### Privacy

- No account required
- No raw Screen Time history uploaded
- No selected app names or tokens sent to analytics
- No backend required for V1
- All core functionality works offline

## 10. Build order

### Phase 1 — Visual proof before product plumbing

Build one fake-data flow containing:

- One room
- One character rig
- One scrolling loop
- One walking replacement
- Present-life reveal
- Trade interaction
- Now ↔ Possible preview
- Object-added completion animation
- Weekly morph
- Graduation transition

Do not proceed until this looks exceptional.

### Phase 2 — iOS onboarding prototype

Implement the complete onboarding in SwiftUI with the Rive scene and
polished transitions. Validate that users understand the product without
explanation.

### Phase 3 — Native functionality

Add local data, replacement sessions, Life/Trade/History, widgets, and
accessibility.

### Phase 4 — Screen Time integration

Add authorization, activity picker, thresholds, custom shield, intentional
extensions, and manual fallback.

### Phase 5 — Polish

Animation timing, art refinement, haptics, copy, battery profiling,
reduced-motion mode, App Store screenshots, and preview film.

## 11. V1 success criteria

The V1 is ready only when:

- The onboarding feels like a short interactive film.
- The character is emotionally legible without detailed facial animation.
- The present-life reveal and future preview are App Store-quality.
- The room visibly changes in response to real user actions.
- Completing a replacement feels more rewarding than seeing a statistic
  change.
- The app opens directly into the animated life scene.
- No primary screen resembles a generic habit tracker.
- The user can start a replacement in two taps or fewer.
- Intentional indulgence remains allowed and shame-free.
- The world never decays when the user is inactive.
- Graduation removes intervention while preserving Life and History.
- The complete experience still works with Reduce Motion enabled.

### Primary product metric

**Meaningful replacement sessions completed per active trade.**

Secondary signals:

- Percentage of interventions that become a deliberate close or timed
  continuation
- Replacement satisfaction
- Reduction in "I stayed longer than I meant to" episodes
- Graduation rate

## 12. Final standard

Indulge should not feel like software telling users to become more
disciplined. It should feel like a private, beautiful mirror asking:

> **Is this still what you want to be doing?**

When the answer is yes, it lets them enjoy it deliberately. When the answer
is no, it makes a fitting alternative easy — and lets them watch that
alternative become part of their life.

## Connection to Significant Hobbies

The two products share a philosophical core but solve different problems:

- **Significant Hobbies** helps people discover and commit to meaningful
  activities — aspirational, forward-looking, public.
- **Indulge** helps people reclaim time from automatic digital habits and
  redirect it toward those activities — corrective, intimate, private.

Potential cross-pollination:

- Indulge's replacement-activity library could draw from the Significant
  Hobbies hobby corpus (5,000+ paths).
- The mortality frame (life grid) could appear inside Indulge as a quiet
  reminder that reclaimed time is life time.
- Indulge's "trade, never moralize" stance is a useful design counterpoint
  to Significant Hobbies' aspirational tone — both can learn from each
  other.
- A user who graduates from Indulge could land naturally in Significant
  Hobbies as their next chapter.
