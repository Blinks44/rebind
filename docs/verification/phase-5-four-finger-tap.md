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
  metadata, unknown release time, discontinuity or stale (>100 ms) frames cancel.
  Coordinates/contact IDs are transient and never logged, displayed or persisted.
- One process-owned native device/registration/context is retained until exit.
  Acceptance closes before MTDeviceStop; native callback quiescence is not a
  documented guarantee, so no unretained released Swift context is reused. Pause,
  edit/record, profile changes, permissions, Secure Input and protected sessions
  invalidate the mailbox/session; callbacks refuse protected runtime snapshots.
  Actual stop/restart/wake behavior remains a hardware check. MainActor stop can
  be delayed if the UI thread is blocked; no delayed output is replayed.
- Three-second arming delay after capture starts. Candidate bounds match the
  successful probe: 30–250 ms contact duration, ≤80 ms arrival/lift spread,
  stable peak ≥15 ms, movement ≤0.02 normalized units, neutral before a stroke.
- A completed candidate waits 500 ms. Any real key/modifier/button/wheel event,
  new contact, focus change, capture loss or revision change cancels it. Existing
  Quartz observation supplies the activity counter even for remapped buttons;
  tagged Rebind output is excluded. The counter is sampled at native receipt,
  not retroactively when the UI consumes buffered contacts.
- Empty native tails preserve an already qualified release, but cannot qualify
  an incomplete release. Repeat taps produce one action each; rapid taps within
  the settling interval cancel the previous candidate.
- One bounded gesture dispatch slot; busy ordinary/workspace queues discard the
  gesture. Posting expires after 100 ms and rechecks cancellation, session/access,
  held modifiers/buttons/output key. Complete tagged down/up pairs go to the
  captured foreground PID through public CGEvent.postToPid. The existing public
  AX client rechecks current application PID on the action thread before posting,
  covering delayed MainActor focus notifications. No delivery ack/retry.
- A button-free 500 ms interval is a conservative condition, not physical-source
  proof or universal tap/click exclusivity. Native gestures cannot be suppressed.
  System conflicts/double effects remain possible and are disclosed in the UI.

## Software verification — 2026-10-09–10

Swift Testing covers the pure recognizer/session, qualified empty tails, repeated
single taps, gaps/invalid/stale frames, click/activity/focus cancellation, arming,
late poll, bounded buffer/pointer copy, schema/profile compatibility, duplicate
rules, queue expiry and targeted dispatch with injected senders. No test creates
or starts a native device, posts real input, changes permissions or writes user
configuration. See docs/PLAN.md for exact final commands/counts/build evidence.

Current Sketch Rebind document 228625FC-9B1E-4187-90FA-5524820A874C and keyboard/
editor frames were inspected read-only. Existing native sidebar/form conventions
were reused. Runtime layout, localized expansion/VoiceOver and real capture are
not proved by compilation.

## User hardware walkthrough

1. Run one rebuilt Rebind copy with its actual Accessibility/posting permission.
2. Use a test profile. Select **Built-in Trackpad**, add a rule, record **⌘W**
   as output and save; enable rules. Trigger is already **Four-finger tap**.
3. Switch to a disposable browser tab, release keys/buttons, wait at least three
   seconds. Lightly tap four fingers, lift them and wait one second. Expect one
   tab to close; record target app, OS/Mac, latency and any original effect.
4. Repeat with another disposable tab. A physical four-finger press, hold,
   movement, three-finger tap and new contact during settling must not produce
   the configured shortcut. Ordinary native behavior remains active.
5. Tap then switch app/profile or pause during the 500 ms check: no delayed close.
   Switch profiles back/resume and wait three seconds; repeat the positive case.
6. Relaunch and confirm the saved rule, then test sleep/wake, lock/unlock and
   access revocation/restoration. No old action may fire after recovery.

If a system gesture also fires, pause the test and inspect its System Settings
assignment before testing again. Rebind never disables native settings itself.
T1/T2 and production adapter lifecycle remain unchecked until these real checks.
