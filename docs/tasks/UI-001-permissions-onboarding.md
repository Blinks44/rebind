# UI-001: Coherent first-run and permission recovery

- Updated: 2026-10-19 (duplicate Accessibility prompt correction)
- Stage: awaiting_verification
- Owner: Unassigned; implementation released
- Requirements: SPEC §§6–8, 10–11; S2
- Code baseline: initial native slice `acce2f4`, feedback adoption `59f5754`; integrated implementation exists in `1a0801b`. Current correction: `497b0d1` plus uncommitted `UI/AppModel.swift`; build and 15 selected permission tests pass.

## Current outcome

2026-10-21: [REL-005](REL-005-onboarding-and-updates.md) wraps the first-run access content in a three-step sheet (Welcome, Access, Ready) and shows it once even when access is already granted. The access checks, recovery sheet and Settings routes below are unchanged.

First-run setup/defer, one-time permission recovery, main notice, Settings → Permissions and Menu Bar routes are implemented. All surfaces use the current soft design system; the former Liquid Glass frames/components are historical. [DESIGN](../DESIGN.md) owns the live source; [historical design evidence](../history/settings-design-through-2026-10-11.md#permissions) retains the earlier source/date and behavior decisions.

Actual Accessibility/event-posting preflights gate capture/output; Input Monitoring is not required by the current tap. Grant state is distinct from engine failure, Secure Input, deliberate pause and storage lock. Setup-later keeps manual editing/profile access; requests and return/focus checks never imply a successful grant. Revocation cancels capture/recording/output while retaining saved rules and intent; avoid repeated modal interruption.

2026-10-29, build 35 (tester report): the setup sheet's green Ready banner no longer offers Check Again. Access is already granted there, and losing it switches the sheet back to the access step on its own. The Settings → Permissions and access-step buttons are unchanged. Sketch never drew the granted Access state; Foundations 11 now records it (saved 2026-10-29).

## Evidence and remaining acceptance

**2026-10-19:** removed the prompted AX call that displayed a redundant system alert alongside the direct System Settings opening. Setup, recovery and Settings share the corrected action; actual grant preflights/return checks remain. Debug build and 15 existing permission/setup tests in three suites pass. [Cause, commands and runtime limits](../verification/permissions-native.md#direct-accessibility-settings-route--2026-10-19). No layout/copy/Sketch changes or actual grant manipulation.

[Native evidence](../verification/permissions-native.md) retains final artifact digests, commands, 508 Swift Testing cases plus a native layout case, source-release checks and the full-main overflow repair across 72 locale/grant/rule/size combinations. Missing-grant navigation, editor cancellation and isolated deferral were checked; actual grants and spoken VoiceOver were not.

The 2026-10-12 feedback adoption passed 18 selected functions, 656 native viewports, Debug/signature and scoped English/German Light/Dark review. These dates/results are retained, not renewed by editing this record.

- [x] Integrated setup/recovery/Settings routes, actual-state status and safe editing/pause behavior.
- [x] Software, native fixture and scoped layout/feedback checks on the dated artifacts.
- [ ] Actual grant/request/revocation and return/relaunch paths on a named current bundle.
- [ ] Complete keyboard/focus/VoiceOver, six-language widths and adaptive preferences.
- [ ] macOS 15 and 26; Intel only if claimed.

## Next handoff

First verify the corrected direct route on the new bundle: first use and prior denial, no duplicate alert, app listing/addition, grant recognition on return, then revocation recovery. Continue the native walkthrough; the user controls real grants and configured input. Record actual results and limits. General/Input/Language/Advanced and whole-app styling already exist; do not implement them again from old handoff notes.
