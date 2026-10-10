# Phase 4 — Active window/application actions

Scope: SPEC §5, A1/A2, current Phase 4 slice. **Implemented and software-tested;
all four ordinary action happy paths are user-confirmed.** Cancellation, unsupported
targets, revoked access and latency still require manual checks.

## Execution contract

- Shared searchable **Windows and Applications** group for every supported input
  category. Four actions: close active window, minimize active window, toggle full
  screen via the window's public full-screen button, hide active application.
- Public AX only: `AXFocusedApplication`, `AXFocusedWindow`, `AXCloseButton`,
  `AXFullScreenButton` + `AXPress`; settable `AXMinimized`/`AXHidden` booleans.
  No AppleScript, menu traversal, fixed keyboard shortcut, private full-screen
  attribute, whole-window inventory or additional dependency.
- Resolve the active target **when the serial worker starts executing**, not when
  the original input is intercepted. Require trusted AX, a positive external PID,
  window role and matching ownership, enabled button or writable property. Rebind
  itself is excluded. Hide can operate when the active app has no window.
- Recheck focused application/window after preparatory reads. Check mailbox
  generation, pause/edit/record/sleep/stop, actual posting permission and Secure
  Input immediately before mutation. AX queries and mutations never run on the
  tap's CFRunLoop or UI actor. No per-event task or additional queue.
- Each IPC request gets at most a 150 ms AX messaging timeout and the adapter stops
  starting requests after its 450 ms budget. Timeouts are best-effort OS request
  limits, not measured worst-case latency. The system-wide object's timeout sets
  this process's AX default; other elements get their own bounded timeout. A slow
  AX target can temporarily delay this serial action worker, not input interception.
- An accepted AX request cannot be recalled. Focus checking and mutation are not
  atomic across applications; a final-check-to-call race remains a platform limit.
  Success means request acceptance, not confirmed closing/animation completion.
  Closing unsaved content may display the target app's normal save dialog; Rebind
  never confirms it. Full-screen button behavior depends on the target app.
- Unsupported, disabled, missing, timed-out or rejected targets report a localized
  failure, retaining other rules. The mapped input is already consumed; no replay,
  automatic retry or shortcut fallback. Cancelled/stale work does not show a false
  failure. Availability depends on the eventual target, so the editor explains it
  rather than claiming universal support based on Rebind's own editor window.
- Read only PID, focus, role, button references/enabled state and settable metadata.
  No titles, text, window contents, positions or target details in diagnostics.
- Schema 8 preserves schemas 1–7 in memory and writes atomically only on a successful
  user edit. Schema-7 audio actions/profiles remain intact. New window actions are
  rejected in older schemas. Unknown action values and future schemas remain errors.

## Software evidence — 2026-10-08

- `scripts/dev.sh test -resultBundlePath build/WindowActionsTests-Final.xcresult`:
  **205 tests / 30 suites / 0 failures**, including 13 new parameterized functions.
  Covers target selection, ownership/self/permissions, absent/disabled/read-only
  targets, focus changes, revocation/cancellation after reads, rejected mutation
  without retry, hide without windows, matching without an audio device, worker
  routing/errors, schema-7 migration preserving bytes until save, old schema gates,
  and localized UI failure. Backends are injected; no actual window/input mutation.
- Initial test build caught a malformed `@Test(arguments:)` declaration; corrected
  to an array before the successful complete run.
- Debug and universal Release builds pass; Swift 6 strict concurrency/deployment
  macOS 26 retained. Final build logs: `/tmp/rebind-window-build-final.log`,
  `/tmp/rebind-window-release-final.log`; test log `/tmp/rebind-window-tests-final.log`.
  Release arm64/x86_64, strict/deep code-sign verification and project/product plist
  lint pass. Only the expected skipped AppIntents metadata warning.
- Exact Debug bundle inspected in Russian: all four entries, category search
  the localized Windows query, full-row minimize selection, explanatory paragraph, hidden shortcut-only
  parameters and disabled Save with an empty trigger. Escape cancels the editor.
  The inspection copy has no AX/post grant; no grant or rule/profile save performed.
  User configuration bytes are unchanged before/after UI inspection; copy quit.
- EN/RU/DE/FR translations are present; other language layout, VoiceOver, actual
  requests/timeouts, cancellation and hardware fault cases are still pending.

## User confirmation — 2026-10-08

Manual test report, 2026-10-08: all four requested window actions completed
successfully in the Finder/TextEdit walkthrough, including full-screen entry/exit.
This confirms ordinary execution of close, minimize, full-screen toggle and hide
on the user's existing setup. Exact applications, trigger chords, macOS version
and entry/exit details were not restated. Do not treat this as confirmation of
save dialogs, windowless apps, every activation mode, protected contexts, focus
races, cancellation, unsupported targets or performance.

## Manual walkthrough — remaining detail and safety checks

1. On the user's authorized copy, assign an unused side-button/modifier chord to
   **Minimize Active Window**. Activate a disposable TextEdit or Finder window,
   trigger it and restore it via the Dock. Verify one action and normal button-up.
2. Check **Close Active Window** on a disposable window. With unsaved text, verify
   the target app's normal save prompt appears and is never automatically confirmed.
3. Check **Toggle Full Screen** entering **and** leaving full screen in TextEdit or
   Finder. Verify the operation is full screen rather than ordinary zoom. Record
   target app/macOS version and any unsupported button behavior before claiming it.
4. Check **Hide Active Application**, then restore it using the Dock. Also check an
   app without an active window if practical. Rebind must stay alive in the menu bar.
5. Verify keyboard, wheel, double/long press and pointer gesture activation, one-shot
   execution, mismatches, release ownership, existing shortcut/audio mappings and
   independent profile switching.
6. Pause/switch profiles/edit/record/sleep during pending actions; check no stale
   mutation. Check unsupported dialogs/full-screen-only windows and revoked access:
   useful error, no replay, no repeated request and normal unmatched input.
7. Verify no action changes Rebind itself, and inspect serial latency with a slow
   target. Measure before claiming a worst-case bound or performance acceptance.

Next: continue Phase 4 open/activate app and URL/file actions after focused native
API/library research, retaining these hardware gates.
