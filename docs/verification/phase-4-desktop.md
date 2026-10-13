# Phase 4 — Mission Control and Spaces via configured shortcuts

**Historical first implementation.** The user subsequently reported unintended
effects on 2026-10-09; it did not pass hardware verification. The current
[Dock/Space follow-up contract](phase-4-dock.md) replaces three shortcut actions with
experimental direct Dock requests and changes the Space sender. Evidence below
describes the original implementation, not current runtime guarantees.

Scope: SPEC §5 A1/A2, §§6–7, 9–12. Implemented/software-tested on 2026-10-09.
Russian native configuration inspected. Real system effects require physical
testing with the user's enabled system shortcuts; no live output by the agent.

## Execution contract

| Action | Suggested output (not detected settings) |
|---|---|
| Mission Control | Control + Up Arrow |
| Show current app windows (App Exposé) | Control + Down Arrow |
| Show desktop | F11 function key, without Fn |
| Previous Space | Control + Left Arrow |
| Next Space | Control + Right Arrow |

- Each action stores its kind and an explicit physical output shortcut. The editor
  prefills a suggestion, supports recording another combination and restoring the
  suggestion, and retains a saved custom chord on reopening. Choosing another
  desktop action supplies that action's suggestion; ordinary output remains separate.
  The rule label includes the actual stored chord.
- The shortcut must be enabled and match System Settings → Keyboard → Keyboard
  Shortcuts → Mission Control. Suggestions are not a read of the user's preferences.
  No undocumented symbolic-hotkey mapping, private Dock/CGS calls, settings writes,
  temporary shortcut enabling or permission requests. Fn/modifier-only/Caps Lock
  output remains unsupported. F11 is a suggestion, not proof of this Mac's binding;
  choose another supported combination if its system shortcut requires Fn.
- Spaces need a neighbouring Space. No wrap, direct numbered Space selection,
  desktop creation, display targeting, window movement or animation control.
  Displays/full-screen behavior follows macOS and its settings.
- The shared serial worker checks generation, posting permission and Secure Input
  before sending. Existing tagged Quartz down/up pairs provide balanced output and
  prevent self-trigger loops. No process/AX/task/UI work on the input callback.
  Existing queue limits, profile/pause/recording/suspension cancellation apply;
  already posted input cannot be recalled.
- Failure to construct output uses the existing output-error/emergency-pause path.
  Quartz does not acknowledge delivery or the intended system effect. A disabled
  or different shortcut may do nothing or reach the foreground app; UI explains
  this dependency rather than claiming native action success or silently replaying
  source input. Key posting alone does not verify Mission Control/Space switching.
- Schema 11 migrates 1–10 in memory without rewriting on load, preserving all
  profiles/IDs/pause/selection and shortcut/audio/window/opening/Apple Shortcut
  actions. Desktop actions disguised in any old schema, including inactive
  profiles, are rejected. Atomic save and size bounds are unchanged.

## Software and UI evidence

- Xcode 27.0 / Swift 6.4 / SDK 27.0, macOS 27.0.1 (26A434), Apple Silicon.
  Minimum remains macOS 26.0; Intel/macOS 26 execution is unverified.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/DesktopActionsTests.xcresult`:
  **255 tests / 36 suites / 0 failures**, all 243 previous plus 12 new functions.
  New coverage: catalog/custom parameters, suggestions, invalid/unknown output,
  schema-10 migration/byte preservation and old-schema gates, typed key/button/wheel
  matching/release, balanced tagged event construction/feedback exclusion, serial
  custom-chord routing, cancellation after dequeue, revoked posting/Secure Input,
  failure emergency bypass and localized labels/error state. Events are constructed,
  not posted. Temporary persistence only; no system settings/user-store writes.
- Debug/universal x86_64/arm64 Release pass; both signatures verify, Release ad-hoc
  Hardened Runtime with no entitlements, deployment 26.0. See PLAN for logs.
- Russian native catalog shows all five actions. Search, Mission Control → Next
  Space → Show Desktop switches suggestions to Control+Up, Control+Right and F11.
  Restore-suggestion button, wrapped explanation and scroll access to Cancel/Save
  inspected. Save disabled without trigger; recording disabled without grants.
  Cancelled without saving and quit the inspection copy. User schema-10 two-profile
  file hash unchanged. No physical output/permission request. Custom recording,
  reopened saved editor, other locales/tab order/VoiceOver remain manual checks.

## Manual checks

1. Use one rebuilt authorized copy. First check the displayed system combination
   physically from another app. If it does not perform the intended function,
   inspect its enabled shortcut in macOS settings yourself; record the matching
   supported combination in Rebind. Do not infer enabled settings from suggestions.
2. Map an ordinary G603 side button to Mission Control, then App Exposé and Show
   Desktop. Test entry/exit and one output per press, normal release, no old rule
   output. Record actual OS, system chord, trigger/modifiers and result.
3. With two existing Spaces, map previous/next. Test both directions and the edge
   with no neighbour; macOS may stay in place. Check full-screen/multiple displays
   only if available, documenting actual behavior rather than assuming a target.
4. Record a custom supported system chord, save/reopen/relaunch the rule: same
   displayed and emitted chord. Restore suggested output in an unsaved editor,
   then cancel: the saved custom chord remains. Fn recording must not be accepted.
5. Check existing Apple Shortcut/audio/window/opening/key rules and another profile.
   Exercise pause/profile switch/recording while held or queued, plus protected
   contexts and capture lifecycle using earlier walkthroughs. Verify no stuck
   modifiers, stale output or feedback. Measure repeated navigation/animation timing.
6. Wrong/disabled system shortcuts have no delivery acknowledgement. Test only a
   harmless combination/foreground app if checking this limitation. Verify the
   explanation, EN/RU/DE/FR wrapping, keyboard access and VoiceOver. Happy-path
   success does not close cancellation/latency/hardware safety gates.
