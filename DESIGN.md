---
name: Habits
description: Keep what helps. Trade what does not.
colors:
  powder-sky: "#E1F0FC"
  powder-soft: "#F2FAFF"
  cherry: "#DB293B"
  navy: "#0C1C38"
  pale-border: "#B8D1ED"
  scene-deep-teal: "#17675F"
  scene-mint: "#7BC8A4"
  scene-mint-shadow: "#4FA681"
  character-lilac: "#9C7DCC"
  lamp-cream: "#F4E5BE"
  sun-amber: "#F5B559"
  dusk-aubergine: "#402033"
  clay: "#452923"
  ink: "#17211F"
  web-sun: "#FFF7CF"
  web-leaf: "#78A889"
  web-leaf-soft: "#91B99E"
  web-blush: "#F4D9DD"
  web-navy-light: "#D7E2F3"
  web-cherry-light: "#FF98A7"
  web-sun-glow: "rgba(255, 247, 207, .9)"
  web-window-frame: "rgba(255,255,255,.65)"
  web-window-tint: "rgba(122,173,208,.12)"
  web-deep-shadow: "rgba(0,0,0,.28)"
typography:
  display:
    fontFamily: "SF Pro Rounded, SF Pro Display, sans-serif"
    fontWeight: 650
    lineHeight: 1.02
    letterSpacing: "-0.025em"
  body:
    fontFamily: "SF Pro Text, sans-serif"
    fontWeight: 400
    lineHeight: 1.35
  label:
    fontFamily: "SF Pro Text, sans-serif"
    fontWeight: 600
rounded:
  control: "16pt"
  sheet: "28pt"
  scene-object: "continuous"
  web-scene-detail: "9px"
  web-window-base: "18px"
  web-brand-mobile: "31px"
  web-device-inner: "35px"
  web-brand-compact: "40px"
  web-device: "42px"
  web-phone-hero: "50px"
  web-brand-inner: "52px"
  web-brand-outer: "72px"
  web-window-arch: "150px"
spacing:
  xs: "4pt"
  sm: "8pt"
  md: "16pt"
  lg: "24pt"
  xl: "32pt"
components:
  primary-action:
    backgroundColor: "{colors.cherry}"
    textColor: "#FFFFFF"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "14pt 20pt"
---

# Design System: Habits

> **Retired design reference (2026-08-24).** Anchor carries the onboarding hero,
> 24 pattern illustrations, eight life-direction illustrations, and humane
> language. The remaining scene-room system is historical research, not an
> active product direction.

## Overview

**Creative North Star: “The Room Assembles Around You”**

Habits is a soft-form 3D cartoon world that responds to a person’s choices by
physically composing their life scene. Selecting “watching TV” does not check a
box: the floor settles, a rounded sofa springs into place, a television rises,
and the character lands naturally into a watching pose. Later choices add a
prop, alter posture, or open another pocket of the world. The result is
abstract enough for projection, adult enough for dignity, and tactile enough
to make each choice emotionally legible.

The craft target is deliberately simple: one readable character, one clear
piece of furniture, and one activity prop can carry a beat. Detail, cinematic
realism, and aspirational lifestyle scenery must not outrun the indulgence
interaction itself.

The scene is the dominant interface. Native SwiftUI controls stay quiet and
precise around it. This is not a dashboard, a dollhouse full of tiny detail, or
a photoreal game. It is a small cinematic stage made from smooth, rounded
objects with expressive timing.

**Key Characteristics:**

- Abstract, rounded 3D character and props with matte clay-like materials.
- Sparse compositions on deep color fields; one clear action per beat.
- Objects arrive as consequences of choices, not as decorative rewards.
- Character emotion is carried by silhouette, posture, timing, and prop use.
- Native controls and accessibility behavior remain recognizably iOS.

## Colors

The world uses a committed deep teal field with mint, lilac, and warm cream
forms. Aubergine and clay sit at the atmospheric edges, giving private evening
warmth without turning the stage into a bright wellness product. Color
separates characters and props without turning progress into moral light.

The native interface extends the daylight room rather than placing a second
theme over it. Powder Sky carries secondary controls and page edges, white
material carries readable trays, navy carries type and active navigation, and
Cherry is reserved for selection, the primary action, and one causal accent.
Teal, mint, cream, and practical amber may remain inside older authored scene
objects, but they do not define the surrounding interface.

### Primary

- **Powder Sky** (#E1F0FC) and **Powder Soft** (#F2FAFF): quiet interface
  fields derived from the blue room.
- **Navy** (#0C1C38): high-contrast type, selected family controls, and active
  navigation.
- **Cherry** (#DB293B): the sole action and selection accent; never a decorative
  wash.
- **Scene Deep Teal** (#17675F): the atmospheric world field and the stable
  visual anchor for the earlier procedural scene proof.
- **Scene Mint** (#7BC8A4): primary furniture and life-space objects.
- **Scene Mint Shadow** (#4FA681): form shadow and deeper object planes.

### Secondary

- **Character Lilac** (#9C7DCC): a starting clothing role, not a gender code.
- **Lamp Cream** (#F4E5BE): warm practical light and restrained highlight.
- **Sun Amber** (#F5B559): selected controls, progress, and the practical glow
  that visually connects the interface to the room.
- **Dusk Aubergine** (#402033) and **Clay** (#452923): low-intensity ambient
  edge colors; never primary control fills or status meanings.

### Neutral

- **Ink** (#17211F): high-contrast controls and primary copy on light material.

### Web scene extensions

The public landing surface extends the same room with **Sun** (#FFF7CF),
**Leaf** (#78A889), **Leaf Soft** (#91B99E), **Blush** (#F4D9DD), **Navy
Light** (#D7E2F3), and **Cherry Light** (#FF98A7). Its sun, window, and depth
effects use the documented translucent values in the frontmatter. These colors
belong to scene atmosphere and tinted copy only; Cherry remains the sole action
accent. Device, window, shelf, and brand-preview radii in the frontmatter are
web illustration geometry rather than reusable control radii.

**The No Moral Lighting Rule.** Possible-life scenes gain breadth, activity,
and specificity—not a simplistic dark-to-bright transformation.

## Typography

**Display Font:** SF Pro Rounded with SF Pro Display fallback
**Body Font:** SF Pro Text
**Label Font:** SF Pro Text

System faces keep the app native while the rounded display cut echoes the 3D
forms. Rounded is reserved for the wordmark and emotionally important display
prompts. Explanations, choices, and controls use the default SF Pro Text cut so
the experience feels adult and remains comfortable through a long
conversation. All UI type uses Dynamic Type text styles rather than fixed
sizes.

### Hierarchy

- **Display:** largeTitle, semibold; only for emotionally important prompts.
- **Headline:** title2 or title3, semibold; one idea per screen.
- **Body:** body, regular; short, humane explanations.
- **Label:** callout or subheadline, semibold; direct action language.

## Layout

The animated scene owns roughly the upper two-thirds of an iPhone screen. A
native safe-area-aware tray below it contains the current prompt and one primary
action. Scene composition stays sparse: a character plus one dominant activity
cluster, with later objects forming distinct pockets rather than filling every
gap. iPad and landscape expand the stage; they do not scale up a phone card.

The first-run flow is a personal conversation, not a profile form. It begins
directly with the optional name question—without an editorial welcome
preamble—then moves through one ordered twelve-beat journey: chosen identity,
activities that repeatedly take more time than intended, the primary indulgence,
ordinary duration, every familiar pull moment, trigger, underlying need,
intentionality, desired life direction, preferred pace, and reflection. Timing is
multi-select because the same indulgence can recur across breaks, evenings, and
late nights. None of these questions sits behind an advanced-personalization
fork. Good habits, replacement prescriptions, and Screen Time permission stay
outside this conversation.

Ask one thing per beat. Keep prior answers visible through adaptive language,
preserve them when navigating backward, and end with a humane reflection rather
than a score. Identity questions explain why they are asked, remain optional,
and include self-description and prefer-not-to-say paths.

On phone, the current question and scene must share one bounded viewport. Every
question uses the same Powder Sky room, white tray, navy type, Cherry selection,
and Cherry primary action established by the indulgence catalog. The
stage is cinematic for short visual decisions and compacts into a persistent
scene rail for long questions, long answer lists, and text entry; it never
disappears merely to make room. Answer lists scroll inside the prompt tray while
the primary action stays anchored above the bottom safe area.

## Elevation & Depth

Depth is real scene depth first: rounded volumes, soft contact shadows, shallow
camera parallax, and clear overlaps. SwiftUI surfaces use system materials only
when a control must sit over the world. On iOS 26 and newer, small navigation
controls may use native glass; the prompt tray remains a quiet material surface
and older supported systems receive an equivalent system-material fallback.
Avoid decorative glass and colored halos.

**The Contact Rule.** Every spawned object must visibly settle into the same
world through contact shadow, weight, and character response.

## Shapes

Scene forms are generous, asymmetrically rounded, and slightly inflated. Major
silhouettes must remain readable at thumbnail size. Details are carved by
planes and color changes rather than outlines or surface noise. UI controls use
native continuous corners and never imitate 3D props.

## App Icon

The current icon makes the product promise literal: a Navy circular routine
contains repeated daily action points, while one Cherry action redirects the
path through a horizontal break and into a small sprout. It represents a life
changing through one quietly altered daily decision rather than one dramatic
transformation. The horizontal exit also keeps the compact silhouette distinct
from a gender symbol. The Powder Sky field keeps the mark warm and
recognizable. The App Store icon has no wordmark or baked-in corner mask;
larger brand lockups pair the symbol with the line **break the loop.**

## Components

### Scene Stage

- One RealityKit scene with modular anchors for environment, activity cluster,
  character, hand props, and ambient objects.
- Camera movement is shallow and authored; user controls never require free 3D
  navigation.
- Scene state is data-driven so onboarding, Life, Trade, and History reuse one
  world.
- Until the reusable 3D rig replaces them, production-quality generated scene
  plates ship as real bundle assets with subtle native parallax, breathing-scale
  motion, practical-light drift, and spring crossfades between causal states.
- Equivalent feminine and masculine character plates use the same room,
  framing, materials, and interaction coverage. Explicit profile choices may
  select a presentation; behavior never does.
- **One-person continuity:** standing, seated, and prop-added plates are
  consecutive moments in one room. Character identity, clothing, camera,
  lighting, and fixed architecture must not change when an indulgence is
  selected; only the pose and the objects caused by that choice may change.

### Choice Chips

- Native SwiftUI controls with a 44pt minimum target and semantic selection.
- A choice previews immediately in the stage before confirmation.
- Selected state uses weight, fill, and haptic response—not glow or badges.
- Every visible indulgence uses authored 3D selector artwork from the same
  material and camera system as the scene. SF Symbols remain available for
  navigation and accessibility controls, not as indulgence artwork.
- A catalog item stays hidden until its selector art, scene role, arrival, and
  Reduce Motion settled state are all present.

### Primary Action

- One clear action per tray, with native focus and disabled states.
- Labels describe the action in the user’s language.
- Use a solid Cherry fill with white text; do not use a gradient.

### Daily App Shell

- Life, Trade, and History use native tab navigation with Cherry selected
  state.
- Life begins with the selected room scene, not a metric dashboard. The room is
  a full-width semantic action: a restrained scene-edge cue invites the person
  to tap when the indulgence begins, and the scene hands directly into Trade.
- Pressing the room adds one shallow depth response. Reduce Motion opens Trade
  without spatial travel. No screenshot, metric card, or tracker chrome floats
  over the authored scene.
- Trade is a focused task surface: one indulgence, one reclaim target, one
  primary action.
- History teaches its future value and remains empty until real activity exists;
  it never ships synthetic charts.
- Inside-app headers may crop the room more tightly than onboarding, but never
  crop away the primary prop that explains the indulgence. Portrait-authored
  plates are preferred on iPhone; television combinations without one preserve
  the complete scene over a soft full-bleed extension. Character identity,
  furniture, palette, and the rounded white tray remain continuous.

### Optional Apple-native Layers

- The future-life card is a personal keepsake below the authored room, not a
  replacement hero. Creation is a deliberate button into Apple's system sheet,
  appears functional only when supported, and offers clear replace and
  destructive-confirmation delete actions.
- Privacy Lock lives in the existing About sheet. Its system-authentication
  toggle is off by default, explains passcode fallback, and offers immediate,
  one-minute, and five-minute relock choices. The locked surface hides its
  underlying accessibility tree and provides one prominent retry action.
- Private CloudKit remains infrastructure, not identity UI. Never add an iCloud
  sign-in imitation, Sign in with Apple, passkey enrollment, sync-success badge,
  or account wall to onboarding. Local actions remain available when cloud
  configuration, account state, or network access is unavailable.
- These layers use Dynamic Type, native VoiceOver semantics, and settled states;
  no custom motion is required to understand generation, locking, or retention.

### First Question

- Let “What should we call you?” be the only headline.
- Show no wordmark, chapter label, linear progress bar, or scene caption.
- Keep supporting copy to one local-privacy line.
- Do not show Skip; Continue accepts an empty optional name.
- When the keyboard appears, collapse the full stage to a compact safe-area
  scene rail rather than hiding it, so the image, field, and primary action all
  remain comfortably visible.

### Transformations

- Props arrive in a causal sequence: clear space, spawn primary object, settle
  character, then add the smallest companion detail.
- Scrolling is a finished hand-prop treatment: the phone rises and settles
  directly into the standing character's hand. Never substitute a floating
  scrolling badge or symbol beside the character.
- Companion props attach through named hand, lap, side-table, floor, and ambient
  sockets so 20–30 scene recipes can reuse one small animation vocabulary.
- Pop motion uses a quick anticipation, soft overshoot, and weighty settle.
- Reduce Motion replaces travel, camera moves, and overshoot with crossfades and
  in-place state changes while preserving causality.
- Seven reusable environment families carry the 24 launch indulgences; specific
  object clusters and socketed companions make each item distinct without
  requiring 24 unrelated rooms.

## Do's and Don'ts

### Do:

- **Do** make each choice visibly recompose character, prop, and space.
- **Do** keep only two or three ambient loops active at once.
- **Do** author inclusive character variants on one shared animation rig.
- **Do** preserve native navigation, Dynamic Type, VoiceOver, Dark Mode, and
  increased-contrast behavior.

### Don't:

- **Don't** trace, ship, or imitate the supplied quality-reference asset.
- **Don't** use mascot proportions, hyper-detailed rooms, or photoreal materials.
- **Don't** turn progress into coins, streaks, confetti, badges, or scene decay.
- **Don't** make every selection use the same scale-and-fade animation.
- **Don't** imply that a user-declared alcohol or smoking prop is recommended,
  healthy, rewarded, or clinical treatment; it is neutral scene context only.
