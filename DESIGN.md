# Tender — design system

**The floor:** a user who cannot see the screen, one hand holding a note, a market too loud
to hear a phone, and no earphones. Every rule below follows from it.

## Principles

1. **Nothing requires sight.** VoiceOver and haptics carry every flow. Visuals accompany.
2. **Speak first.** The app says what it sees before it is asked. A blind user should
   never have to find a button to learn what the camera is looking at.
3. **Two channels for every answer.** Spoken *and* felt. A market drowns one; the other
   arrives.
4. **Honest about uncertainty.** Three sentences, two numbers, and *"I don't recognise
   this"* is a good answer.
5. **The whole screen is the control.** There is one thing to do, so there is nowhere to
   miss.

## Colour

Built for low vision, not for the blind — a blind user never sees it, and a low-vision user
needs more contrast than a sighted one, not a prettier palette. **Every text pair is
asserted at 7:1** (WCAG AAA) and every state colour at 4.5:1, in both themes, on every
ground including both gradient stops, by `TenderTests/ContrastTests.swift`. Harvest's floor
is 4.5 and 3; this product's user is the reason it is higher.

**Three surface tones, not one.** Depth on a dark screen comes from stepping the surface,
with a hairline where the step alone is too subtle at arm's length.

| Role | Light | Dark | |
|---|---|---|---|
| `surface` | `#FFFFFF` | `#0A0A0C` | The page |
| `raised` | `#F4F4F6` | `#1A1A1F` | The one card |
| `high` | `#E8E8EC` | `#26262D` | A control on it |
| `outline` | `#8A8A96` | `#62626E` | The hairline between them |
| `textPrimary` | `#0A0A0C` | `#FFFFFF` | |
| `textSecondary` | `#3E3E48` | `#C9C9D2` | |
| `ready` | `#6B4E00` | `#FFD166` | A note is named, or the frame is good |
| `onReady` | `#FFFFFF` | `#0A0A0C` | What is legible **on** `ready` |
| `caution` | `#7A4200` | `#FFB454` | *Check* — the hedged answer, or *hold steady* |
| `stop` | `#9E1B14` | `#FF8A80` | *I don't recognise this*, or *too dark* |

The page carries a two-stop vertical gradient — `#121216` to `#0A0A0C` in the dark,
`#FFFFFF` to `#F2F2F5` in the light — barely apart. **The gradient, not `surface`, is what
text is drawn on**, so the assertions measure every stop.

**Dark is the default.** Both are authored; neither is derived. A low-vision user who has
set the system to light gets light, because that setting is a medical choice and the app
does not overrule it — this is the one project in the portfolio where `ThemeMode.system`
wins, and the reason is written here.

`ready` is a warm yellow rather than a green because yellow on near-black is the highest
luminance contrast available and the one most low-vision users can still see. Green means
*go* to a sighted person and nothing to this one.

**Colour is never the sole carrier of meaning.** Every state is spoken, felt and coloured.
Lose two channels and the third still lands.

## Targets

**The whole screen is the target.** A tap anywhere repeats the last announcement; a
two-finger double-tap (VoiceOver's magic tap) starts over. There is no button to find.

Where a control does exist — settings, the language picker in v1.1 — `Target.standard` is
**64 pt**. Nothing in this app is 44.

## Shape and spacing

Radii: 20 for the one card, 12 for chips, fully round for the pill. Spacing on a four-point
grid — 4, 8, 16, 24, 32.

## Type

**San Francisco, the system font, with Dynamic Type honoured to the largest accessibility
size.** Not bundled Inter, which every other project in the portfolio uses, and the
divergence is deliberate: a low-vision user has set a text size in Settings and that setting
is the most important design decision on the phone. SF is the face Dynamic Type was designed
around, and the accessibility sizes render it well. Inter scaled to 310% does not.

Display 34 pt, headline 28, body 17, secondary 15 — at the default size. At the largest
accessibility size the display denomination is over 100 pt and fills the screen, which is
the intent: a low-vision user holding the phone six inches from their face reads *500* and
nothing else. Every screen is asserted at the largest size without a truncated word by
`TenderUITests/DynamicTypeTests.swift`.

## What the app says

Everything the app says is a VoiceOver announcement — `UIAccessibility.Notification` with
interruption — so it lands over whatever VoiceOver was reading, and is repeated by a tap.
When VoiceOver is off, the same strings go through `AVSpeechSynthesizer`, because a sighted
user with a new ₦200 also benefits from being told.

**Framing** — one of five, said as the frame changes and not more than once a second:

| | Said | Felt |
|---|---|---|
| Too dark | *"Too dark."* | one long, soft |
| Too bright | *"Too bright."* | one long, soft |
| Nothing | *"I can't see a note."* | nothing |
| Steady | *"Hold steady."* | two short, soft |
| Ready | *(the answer follows)* | — |

**The answer** — one of three, decided by two numbers ([the confidence gate](docs/ROADMAP.md#phase-3--the-camera)):

| Condition | Said | Colour |
|---|---|---|
| Sure | *"Five hundred naira."* | `ready` |
| Probably | *"I think five hundred naira. Check."* | `caution` |
| Not sure | *"I don't recognise this."* | `stop` |

The redesign is named only when it matters: *"Five hundred naira, new design"* is said
when the top result is a 2022 note, because a sighted person may be about to argue with the
user about it. The old design is just *"five hundred naira"*.

**No sentence anywhere says or implies whether a note is genuine.** `make copy-check`
reads every string and fails on *genuine, real, fake, counterfeit, authentic, verified*.
[ADR-0003](docs/adr/0003-the-app-names-the-denomination-not-the-authenticity.md).

## What the app does with the haptic engine

Eight patterns for eight values, designed to be learnable in a minute and felt through a
pocket. A **short** is a sharp transient of 60 ms; a **long** is a continuous 220 ms with a
soft attack. Gap 120 ms within a pattern.

| Value | Pattern |
|---|---|
| ₦5 | short |
| ₦10 | short short |
| ₦20 | short short short |
| ₦50 | long |
| ₦100 | long short |
| ₦200 | long short short |
| ₦500 | long long |
| ₦1000 | long long long |

The grammar: shorts count up to twenty, one long is fifty, hundreds add shorts to a long,
five hundred and a thousand are longs alone. Two designs of the same value feel the same;
the difference is spoken, not felt.

**This vocabulary is provisional** and the release ledger says so (R4). It was designed by
people who can see, and whether *long short* and *long short short* are distinguishable in a
moving bus is a question for the hands that will use it.

The hedged answer plays its pattern at half intensity. *I don't recognise this* plays a
single soft long — the same as *too dark*, deliberately: both mean *the app has nothing for
you yet*.

## Motion

The splash is the portfolio's: the mark, a warm bloom, the wordmark, about 1.2 seconds, the
camera initialising behind it, driven by a timer and not by an animation so that Reduce
Motion — which many low-vision users enable — gets a still frame for the same duration
rather than nothing. VoiceOver announces *"Tender"* over it. The launch screen is painted
`#0A0A0C` so there is no white flash on handover.

Nothing else in the app moves. A pulsing ring around a frame is decoration to the user who
cannot see it and distraction to the one who barely can.
