# Phase 5 — integrated four-finger tap (experimental)

## Implemented subset

Built-in trackpad only: an unmodified, light, stationary single four-finger tap
can send a configured keyboard shortcut through Rebind's serial action worker.
The trigger is a named preset in the editor, not a gesture recorder. Rules use
normal profile selection, enable/edit/delete and versioned local persistence.
Schema 22 preserves schemas 1–21, including inactive profiles, without rewriting
on load. Unsupported activation/modifier/action payloads are rejected.

This first integration does not yet expose the full shared action catalog for
touch. It does not remove SPEC §5's eventual requirement. Three-finger taps,
physical multi-finger clicks, double taps, corners, modifier combinations and
external Magic Trackpad remain separate implementation/hardware gates.

## Runtime and limits

- Private MultitouchSupport is isolated in NativeTrackpadDevice. Only a built-in
  default device is accepted, on macOS major versions 26–27. Neither macOS 26 nor
  Intel execution has been verified. Future OS versions fail unavailable.
- C signatures/contact layout were compared with pinned Apache-2.0 Subsurface;
  the full notice is bundled. No app SPM dependency, Scribe/SwiftSyntax macros,
  external helper, haptics, seizure, system preference change or GPL code.
- Count is checked before reading native memory; at most 16 records are examined
  and four active contacts copied into a fixed 64-frame ring. Overflow, invalid
  metadata, unknown release time, backwards/repeated native IDs, nonmonotonic
  time or stale (>100 ms) frames cancel. Forward gaps also cancel an active
  stroke or pending output. Between strokes, after known neutral, a forward
  ID gap may start a fresh stroke; it never bridges an unfinished contact sequence.
  Callback time/frame are preserved even for an empty contact array: a known
  consecutive zero-contact callback can finish a stroke without a terminal record.
  Callback timing is used throughout, rather than mixing record and callback clocks.
  Coordinates/contact IDs are transient and never logged, displayed or persisted.
- One process-owned native device/registration/context is retained until exit.
  Acceptance closes before MTDeviceStop; native callback quiescence is not a
  documented guarantee, so no unretained released Swift context is reused. Pause,
  edit/record, profile changes, permissions, Secure Input and protected sessions
  invalidate the mailbox/session; callbacks refuse protected runtime snapshots.
  Actual stop/restart/wake behavior remains a hardware check. MainActor stop can
  be delayed if the UI thread is blocked; no delayed output is replayed.
- Three-second arming delay after capture starts. Candidate bounds now allow
  30–400 ms contact duration, ≤150 ms arrival/lift spread, at least two peak-count
  frames and individual movement ≤0.04 normalized units, neutral before a stroke.
  The second peak frame may arrive in 8 ms; no fixed 15 ms peak dwell is required.
  Identity replacement/bounce, five contacts, >50 ms active-frame gaps, holds and
  larger movement still reject a stroke. Pressure is not a click classifier.
- A completed candidate waits 60 ms. Any real key/modifier/button/wheel event,
  new contact, focus change, capture loss or revision change cancels it. Existing
  Quartz observation supplies the activity counter even for remapped buttons;
  tagged Rebind output is excluded. The counter is sampled at native receipt,
  not retroactively when the UI consumes buffered contacts.
- Empty native tails preserve an already qualified release, but cannot qualify
  an incomplete release without native timing. Repeat taps produce one action each; rapid taps within
  the settling interval cancel the previous candidate.
- One bounded gesture dispatch slot; busy ordinary/workspace queues discard the
  gesture. Posting expires after 100 ms and rechecks cancellation, session/access,
  held modifiers/buttons/output key. Complete tagged down/up pairs go to the
  captured foreground PID through public CGEvent.postToPid. The existing public
  AX client rechecks current application PID on the action thread before posting,
  covering delayed MainActor focus notifications. No delivery ack/retry.
- A button-free 60 ms interval is a conservative condition, not physical-source
  proof or universal tap/click exclusivity. Native gestures cannot be suppressed.
  System conflicts/double effects remain possible and are disclosed in the UI.

## Software verification — 2026-10-09–10

The user confirms integrated app output (2026-10-10), but reports approximately
one successful tap out of seven and noticeable delay versus BetterTouchTool. This
is a usability failure, not Phase 5 acceptance. After the responsiveness change,
the user reports somewhat better detection initially, then complete loss of tap
output after physical four-finger clicks. Synthetic click → neutral → separated
tap sequences reproduce an idle-frame-gap cancellation loop. The recovery fix
allows forward frame gaps only after known neutral and outside pending output.
The actual hardware cause and recovery still need confirmation; no input trace
was collected from the reported failure. The responsiveness fix preserves
empty-callback timing, widens natural-contact tolerances and reduces the click
check from 500 to 60 ms. The probe’s observed +12/+28 ms button pair fits that
window; other-device timing and real end-to-end latency are not established.

Swift Testing covers the pure recognizer/session, timestamped empty release,
8 ms peak frames, 320 ms rolling contacts with small drift, click-to-tap recovery
with forward idle ID gaps, backwards/repeated IDs with recovery, qualified empty tails, repeated
single taps, gaps/invalid/stale frames, click/activity/focus cancellation, arming,
delayed clicks at +12/+28/+59 ms, late poll, bounded buffer/pointer copy, schema/profile compatibility, duplicate
rules, queue expiry and targeted dispatch with injected senders. No test creates
or starts a native device, posts real input, changes permissions or writes user
configuration. See docs/PLAN.md for exact final commands/counts/build evidence.

Current Sketch Rebind document 10246E46-59D2-4110-95FB-7576E75168A9 and keyboard/
editor frames were inspected read-only. Existing native sidebar/form conventions
were reused. On 2026-10-10 the trackpad category's vertical fixedSize regression was
reproduced and fixed. Russian native sidebar/header/Add and preset editor/Cancel
were screenshot-verified after rebuild, including repeated category transitions.
Compact resizing, other locales/VoiceOver and real capture remain unverified;
compilation alone does not establish them.

## User hardware walkthrough

1. Run one rebuilt Rebind copy with its actual Accessibility/posting permission.
2. Use a test profile. Select **Built-in Trackpad**, add a rule, record **⌘W**
   as output and save; enable rules. Trigger is already **Four-finger tap**.
3. Switch to a disposable browser tab, release keys/buttons, wait at least three
   seconds. Tap four fingers naturally and lift them. Repeat 10–20 times using disposable
   tabs. Expect one tab per tap with a short response after lift. Record successes,
   target app, OS/Mac, perceived latency and any original effect. Do not infer a
   measured 60 ms end-to-end latency from the software settling constant.
4. Repeat with slightly rolling placement/lift and small fingertip shifts.
   A physical four-finger press (including a quick click), hold,
   movement, three-finger tap and new contact during settling must not produce
   the configured shortcut. Then lift all fingers and try another series of
   light taps without restarting, toggling rules or changing profiles: tap output
   must recover. Check both a quick physical click and a longer held click.
   Ordinary native behavior remains active.
5. Tap then switch app/profile or pause before dispatch during the short click check: no delayed close.
   Switch profiles back/resume and wait three seconds; repeat the positive case.
6. Relaunch and confirm the saved rule, then test sleep/wake, lock/unlock and
   access revocation/restoration. No old action may fire after recovery.

If a system gesture also fires, pause the test and inspect its System Settings
assignment before testing again. Rebind never disables native settings itself.
T1/T2 and production adapter lifecycle remain unchecked until these real checks.
