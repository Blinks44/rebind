# UI-001: Coherent first-run and permission recovery

- Updated: 2026-10-16 (documentation reconciliation)
- Stage: awaiting_verification
- Owner: Unassigned; implementation released
- Requirements: SPEC §§6–8, 10–11; S2
- Code baseline: initial native slice `acce2f4`, feedback adoption `59f5754`; integrated implementation exists in `1a0801b`. No new app checks in this cleanup.

## Current outcome

First-run setup/defer, one-time permission recovery, main notice, Settings → Permissions and Menu Bar routes are implemented. All surfaces use the current soft design system; the former Liquid Glass frames/components are historical. [DESIGN](../DESIGN.md) owns the live source; [historical design evidence](../history/settings-design-through-2026-10-11.md#permissions) retains the earlier source/date and behavior decisions.

Actual Accessibility/event-posting preflights gate capture/output; Input Monitoring is not required by the current tap. Grant state is distinct from engine failure, Secure Input, deliberate pause and storage lock. Setup-later keeps manual editing/profile access; requests and return/focus checks never imply a successful grant. Revocation cancels capture/recording/output while retaining saved rules and intent; avoid repeated modal interruption.

## Evidence and remaining acceptance

[Native evidence](../verification/permissions-native.md) retains final artifact digests, commands, 508 Swift Testing cases plus a native layout case, source-release checks and the full-main overflow repair across 72 locale/grant/rule/size combinations. Missing-grant navigation, editor cancellation and isolated deferral were checked; actual grants and spoken VoiceOver were not.

The 2026-10-12 feedback adoption passed 18 selected functions, 656 native viewports, Debug/signature and scoped English/German Light/Dark review. These dates/results are retained, not renewed by editing this record.

- [x] Integrated setup/recovery/Settings routes, actual-state status and safe editing/pause behavior.
- [x] Software, native fixture and scoped layout/feedback checks on the dated artifacts.
- [ ] Actual grant/request/revocation and return/relaunch paths on a named current bundle.
- [ ] Complete keyboard/focus/VoiceOver, six-language widths and adaptive preferences.
- [ ] macOS 26; Intel only if claimed.

## Next handoff

Verify first-run and permissions on the named bundle using the native walkthrough; the user controls real grants and configured input. Record actual results and limits. General/Input/Language/Advanced and whole-app styling already exist; do not implement them again from old handoff notes.
