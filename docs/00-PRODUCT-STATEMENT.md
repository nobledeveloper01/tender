# Tender — Product Statement

**A naira note identifier for blind and low-vision Nigerians. Point the camera, hear the
denomination, feel it in your hand.**

---

## The Problem

Naira notes have no tactile marking. None of the eight denominations in circulation — ₦5,
₦10, ₦20, ₦50, ₦100, ₦200, ₦500 and ₦1000 — can be told apart by touch. They are close to
the same size, printed on the same paper, and after a year in a market they feel identical.

So a blind Nigerian handling cash is trusting the other party. Every purchase, every bus
fare, every change handed back is an act of faith in a stranger. The workarounds are real
and they are all bad: fold each denomination a different way (which only works for notes
you already know), keep denominations in separate pockets (which fails at the first
mixed handful of change), ask the person you are paying (who is the one person with an
interest in the answer), or carry a sighted companion (which is the loss of independence
the whole thing is about).

The 2022 redesign made it worse. New ₦200, ₦500 and ₦1000 notes entered circulation
alongside the old ones, so there are now **eleven visually distinct notes** carrying eight
values, and a sighted person unfamiliar with the new designs needs a second look. A blind
person gets no look at all.

---

## Why Existing Solutions Do Not Work

**Apple's own tools.** VoiceOver is excellent and Magnifier is genuinely useful, but neither
knows what a naira note is. Magnifier will enlarge the note; it will not name it.

**General object-recognition apps** — Seeing AI, Lookout, Be My Eyes — do recognise currency,
for a list of currencies that does not include the naira. Nigeria's is the largest economy in
Africa and its banknotes are not in any of them.

**Human-assistance apps** work, and they work by putting a stranger on a video call to look
at your money. That is a fine fallback and a bad default: it needs data, it needs a
volunteer to be awake, and it means telling somebody how much cash you are holding.

**Cash-reading devices** exist for other currencies and cost more than a phone.

---

## The Product

Tender does one thing.

1. **Point** — the camera opens on launch. There is nothing to tap first.
2. **Frame** — the app says, out loud and through the haptic engine, whether it can see a
   note: *too dark*, *hold steady*, *closer*, *ready*. The user is not looking at the
   screen and the app never assumes they are.
3. **Name** — *"Five hundred naira."* Spoken through VoiceOver, and pulsed through the
   haptic engine in a pattern that is different for every value, so the answer arrives even
   in a market too loud to hear it.
4. **Repeat** — a tap anywhere says it again. A shake starts over.

That is the whole product. It runs on the device, needs no network, no account and no
server, and stores nothing.

---

## The Insight

**The accessibility layer is the product, not a feature of it.**

A currency classifier is not hard; the model is a few days' work and a few thousand
photographs. What is hard, and what nothing on the market has done for the naira, is the
interface *around* the model: an app a blind person can operate one-handed while holding a
note in the other, that speaks before it is asked, that is honest when it is unsure, and
that works with VoiceOver's own gestures rather than fighting them.

That is why this is native. VoiceOver rotor actions, accessibility announcements that
interrupt correctly, Core Haptics patterns with real texture, and a camera pipeline the
classifier can keep up with are the platform's own APIs, and a cross-platform framework
reaches them through a seam. On this product the seam is where the user lives.

---

## Target User

**Primary — the blind or low-vision iPhone owner in Nigeria.** An iPhone because it is the
phone blind smartphone users disproportionately choose — screen-reader surveys put iOS at
roughly seven in ten worldwide, and VoiceOver is the reason. Nobody has measured that
figure for Nigeria, and this document does not pretend to. Uses cash daily,
because cash is how Nigeria buys things. Operates VoiceOver in English, because VoiceOver
has no voice for Hausa, Yoruba, Igbo or Pidgin — a constraint of the platform, not a
choice of this product.

This is a minority of a minority: iPhones are a small share of Nigerian handsets, and blind
users a small share of iPhone owners. The product statement says so rather than implying
a market it does not have. The user it serves is served *completely*, and the thing being
proved is that the platform can be used to its full depth for somebody it was built for.

**Secondary — the sighted person with a new note.** The 2022 designs confused everybody.
That user is welcome and is not who the interface is designed around.

---

## Why Now

- **On-device inference is free.** A Core ML image classifier runs on the Neural Engine in
  well under a tenth of a second, on every iPhone sold in the last six years, with no
  server and no data. The model ships inside the app.
- **Create ML makes the classifier a solo job.** Eleven classes of a flat, rigid, printed
  object is the easy end of image classification. The dataset is photographs one person
  can take in a week.
- **The 2022 redesign** put eleven notes into circulation for eight values and gave the
  problem a second audience.
- **Nothing serves the naira.** Every established currency reader covers the dollar, euro,
  pound, rupee and yen. Not one covers the currency of Africa's largest economy.

---

## Explicitly Not

- **Not a counterfeit detector.** Tender names the denomination a note *is designed as*.
  It does not and cannot say whether the note is genuine, and no sentence in the app may
  imply otherwise. See [ADR-0003](adr/0003-the-app-names-the-denomination-not-the-authenticity.md).
- **Not fintech.** It touches no money. No wallet, no payment, no balance, no account. It
  identifies a piece of paper and forgets it.
- **Not a general object reader.** It knows eleven notes. Point it at a bottle and it says
  it does not recognise this, which is the correct answer.
- **Not cross-platform.** iOS only, by decision, recorded in
  [ADR-0001](adr/0001-tender-is-native-and-ios-only.md). The one project in this portfolio
  that is, and the reason is written down.
