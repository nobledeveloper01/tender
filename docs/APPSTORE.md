# App Store listing

The text the store shows. `make copy-check` reads this file against the same
word list as the app's own strings — ADR-0003 says which words, and why.

## Name

Tender

## Subtitle

Naira notes, spoken and felt

## Description

Point the camera at a naira note and Tender tells you which one it is — out
loud through VoiceOver, and through the haptic engine in a pattern that is
different for every value, so the answer reaches you in a market too loud to
hear your phone.

Built for blind and low-vision Nigerians. Naira notes have no tactile marking,
and since the 2022 redesign there are eleven visually distinct notes carrying
eight values. Tender knows all eleven.

- Opens straight to the camera. Nothing to tap first.
- Says whether it can see a note: too dark, hold steady, ready.
- Names the denomination. Says "new design" when it matters.
- Eight haptic patterns for eight values. One short tap for ₦5, three long for
  ₦1000. Learnable in a minute.
- Honest when unsure. "I think five hundred naira — check" and "I don't
  recognise this" are things it will say rather than guess.
- Tap anywhere to hear it again. Two-finger double-tap to start over.
- Works fully with VoiceOver, Dynamic Type at every size, Reduce Motion and
  Voice Control. Speaks through the synthesiser when VoiceOver is off.
- Entirely on your phone. No account, no internet, nothing stored, nothing
  sent. It identifies a piece of paper and forgets it.

Tender names the denomination a note is designed as. It does not, and cannot,
tell you whether a note is a good one — that takes a bank.

## Keywords

naira, currency, banknote, blind, low vision, VoiceOver, accessibility, Nigeria, money reader

## Privacy

Data Not Collected. Tender has no network access.

## What's new (0.1.0)

First release.
