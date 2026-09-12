# Feature backlog

## Built, and why — ADR-0004

Twenty features, each checked against the five rules before it was built:
nothing requires sight, nothing stored or sent, never authenticity, never money
movement, native for a reason. All twenty are in.

| | Serves | Where |
|---|---|---|
| Two frames must agree before *sure* | Halves confident-wrong answers | `Agreement`, domain |
| *"Closer."* | A small note in the frame, said | `FramingRule`, domain |
| The torch, in the dark | A blind user does not know it is dark | `LightPolicy`, domain; `Torch` |
| *"Try near a window."* | Advice that escalates instead of repeating | same |
| Audible patterns | Earphones in a bag; hands in a coat | `Earcons`, synthesised |
| Hide the number | Nobody on the bus reads the screen | Settings → Screen |
| Dim the screen | Battery, and privacy | Settings → Screen |
| Haptic strength | Thick pockets, thin phones | Settings → Haptics and sounds |
| Speech rate | Without VoiceOver, still fast | Settings → Speech |
| *How sure?* | The two numbers in words, on request | VoiceOver action; `Sureness` |
| Say it again on return | Back from a call, the answer again | `scenePhase` |
| First-launch hint | One spoken sentence, once, no screen | `Reader.say` |
| Quiz | The app pulses; you name the value. R4 in the app | Settings → Quiz |
| Tally | A handful of change, counted aloud | VoiceOver action; `Tally` |
| Change checker | Paid ₦1000, cost ₦350, is this ₦650? | VoiceOver action; `Change` |
| Face-down pause | In a pocket, the camera and the voice stop | `Posture` |
| Low Power Mode | Fifteen frames a second, a longer day | `CameraSession` |
| Siri, Shortcuts, the Action button | *"Identify a note with Tender"* | `IdentifyNoteIntent` |
| *"What Tender knows about you"* | The privacy promise, out loud | Settings |
| **The denomination in your own language** | Naijá, Hausa, Yorùbá, Igbo, Fulfulde, from bundled recordings; twelve lines per language; a language is offered only when none of its clips is a placeholder | Settings → Speech → Language; [`RECORDING-KIT.md`](RECORDING-KIT.md) |

## Not yet

Things worth building that are not in the current phase. Each one names why it
is not being built yet, because "later" without a reason is how a backlog turns
into a graveyard.

| | Why not now |
|---|---|
| A stack of notes, counted | v1.1. Several notes at once is a detection problem before it is a classification one, and the classifier is not trained yet. Also arithmetic on cash needs its own sentence about not being fintech. |
| The Action button | v1.1. Launch-to-camera is already the default, so the button saves one unlock. Worth having; not worth having before the camera works on a handset. |
| CFA francs, for the border markets | Not scheduled. A second currency doubles the dataset and the classes and the failure modes, and nobody has asked. It goes in when somebody who crosses that border does. |
| Coins | Not scheduled. Naira coins are effectively out of circulation; ₦1 and ₦2 coins exist in law and not in pockets. |
| Counterfeit detection | **Never**, and the reason is [ADR-0003](adr/0003-the-app-names-the-denomination-not-the-authenticity.md). Listed here so that the request has somewhere to land. |
