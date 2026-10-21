# FIX-002: Window actions across Finder, Chrome and ChatGPT

- Updated: 2026-10-21
- Stage: awaiting_verification
- Owner: current implementation chat; implementation ready, runtime handoff open
- Ownership checked: 2026-10-21, main `5bafe80`; clean starting checkout, no overlapping edits observed
- Owned surfaces: WindowActionExecutor/AXWindowAccessibility, WindowActionTests, project build number, task/STATE/PLAN/capability/research evidence
- Requirements: SPEC §5 Windows and applications; existing focus, permission and cancellation safeguards
- Code baseline: main `5bafe80`; implementation, workflow and evidence are included together in the commit containing this record

## Outcome and scope

Repair the reported minimize failure in Chrome and ChatGPT while Finder works with Mouse Button 5 + downward movement. The supplied screenshot reports the generic window-action failure; the disconnected external-trackpad notice is separate. Actual user rules and permissions are unchanged.

## Acceptance

- [x] Identify the failing AX stage and compare application capabilities without collecting window content.
- [x] Repair application discovery with regression coverage, retaining bounded worker execution and focus/cancellation gates.
- [x] Build the incremented app and run affected tests; separate injected coverage from application/hardware evidence.
- [ ] Confirm repaired native action execution and the actual Button 5 + down gesture in Finder, Chrome and ChatGPT on build 8.
- [x] Update task, STATE and affected evidence with a concrete next step.

## Cause and correction

The old shared client obtains `AXFocusedApplication` from a system-wide AX object. On this machine that query fails when Chrome or ChatGPT is active, before any minimize request is attempted. The localized failure conflates unsupported windows, permissions and discovery failures. Both affected apps expose valid standard windows and writable `AXMinimized`; Accessibility trust is actually granted to the read-only probe.

The shared client now reads `NSWorkspace.shared.frontmostApplication`, requires an active/nonterminated positive PID, creates a direct application AX handle, verifies its `AXFrontmost` flag and resamples the PID after that potentially blocking AX read. Stale/disappearing/changed focus is rejected without selecting a replacement. Executors still recheck application/window identity, trust and dispatch cancellation before mutation. No system-wide focused-app query or shortcut fallback remains. The 150 ms request / 450 ms slice budgets remain; timeouts now apply only to individual handles, not the process-wide AX default.

This client is used by close/minimize/full-screen/hide, window layout, window cycling and previous-application activation. Those paths receive the same discovery correction; this does not establish that every target supports every operation. No callback, event matching, rule storage, UI copy or Sketch changes.

## Research / native evidence — 2026-10-21

Environment: Apple silicon, macOS 27.0.1 (26A434), Xcode 27.1 / Swift 6.4 / SDK 27. Chrome 155.0.8059.85; ChatGPT 26.1013.40934 (local app bundle ID `com.openai.codex`). Installed Rebind metadata is 1.0.0 (7).

Agent-observed native read-only probes briefly activated the named apps and restored the original application. They read only PID/focus, roles, minimized state, settable flags and button references; no titles/text/document contents.

| Active application | Old system-wide focused-app query | Direct application attributes |
| --- | --- | --- |
| Finder | success | AXFrontmost true; focused window success after activation |
| Chrome | AXError.noValue (-25212) | AXFrontmost true; focused standard window with correct PID; AXMinimized writable; stable repeated window reference |
| ChatGPT | AXError.noValue (-25212); earlier sample also cannotComplete (-25204) | AXFrontmost true; focused standard window with correct PID; AXMinimized writable; stable repeated window reference |

Direct focused-window reads were about 17 ms for Chrome/ChatGPT in the initial samples; these are observations, not latency guarantees.

References refreshed: [Apple frontmostApplication](https://developer.apple.com/documentation/appkit/nsworkspace/frontmostapplication), [AX timeout](https://developer.apple.com/documentation/applicationservices/1459345-axuielementsetmessagingtimeout), installed NSWorkspace/NSRunningApplication SDK headers (including atomic/thread-safe running-app properties and main-run-loop freshness), [Rectangle AX adapter](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/AccessibilityElement.swift), [AXSwift application adapter](https://github.com/tmandry/AXSwift/blob/main/Sources/Application.swift) and [Swift Package Index](https://swiftpackageindex.com/tmandry/AXSwift). Rectangle/AXSwift are MIT references; SPI lists AXSwift 0.3.2 and older maintenance. Keep the existing small native adapter; no dependency, code reuse or licensing change. Apple markdown fetch was unavailable; installed SDK headers and retrieved source/API pages supplied the relevant contracts.

## Build and software verification — 2026-10-21

- Debug and Release `CURRENT_PROJECT_VERSION` incremented together from 7 to **8**; `MARKETING_VERSION` remains **1.0.0**.
- `apps/rebind/scripts/dev.sh build`: succeeds with Swift 6 strict concurrency. Only expected AppIntents metadata-extraction warning. Initial sandboxed doctor failed writing external Xcode/SPM caches; approved normal-cache build succeeds.
- `dev.sh test`, selecting WindowActionTests, WindowLayoutExecutorTests and WindowCycleExecutorTests: **34 functions / 3 suites pass**, including new parameterized invalid/missing PID, stale AX focus and app-switch-during-read cases.
- Separate `dev.sh test -only-testing:rebindTests/ApplicationActivationTests`: **8 functions / 1 suite pass**. First invocation used an unmatched activation-suite filter; this separate correctly named run provides the activation evidence. Total: **42 functions**, with parameterized cases.
- XCResult basenames: `Test-rebind-2026.10.21_11-27-39-+0300.xcresult` and `Test-rebind-2026.10.21_11-29-04-+0300.xcresult`, under local DerivedData/Logs/Test.
- Built artifact metadata confirms **1.0.0 (8)**; strict/deep code-sign verification passes with normal certificate access (sandbox-only verification could not evaluate trust). `git diff --check` and affected local documentation links pass.
- Artifact: `apps/rebind/build/DerivedData/Build/Products/Debug/Rebind.app`; no installation, launch of the repaired normal app or Git commit. Local packaging was subsequently completed below.

## Installable-artifact handoff — 2026-10-21

The workflow now requires `apps/rebind/scripts/release.sh` after each completed app change set and its required checks, with a verified/versioned DMG path for manual installation. The reusable project-local agent-workflow-setup skill is adapted to 1.4.1; AGENTS/WORKFLOW and signing guidance own the exact Rebind command. Documentation-only/test-only/website-only/Sketch-only changes do not repackage. Existing build 8 is reused for packaging this same fix; no extra increment.

`apps/rebind/scripts/release.sh` completes successfully: Release app build, pinned Apple Development signing, strict app/DMG signature checks and image integrity verification. Artifact: `apps/rebind/build/release/Rebind-1.0.0-8.dmg`. Packaged app metadata confirms 1.0.0 (8). SHA-256: `36f64093aa1b893522df6ca14a97e10782c545de380ecd81bbc99c3187c58055`. DMG remains locally ignored; no installation/publication or runtime acceptance follows from packaging.

Workflow review covers app fix → package handoff, docs-only → no package, packaging failure → concrete blocker/no stale artifact. No new skill/dependency or global/canonical skill update. Existing quick_validate was attempted; the default Python lacks PyYAML, so metadata/links/diff are also reviewed directly. This documentation change does not rerun app tests; the 42 functions above still cover the same shipped source.

## Limits / final review

Automatic approval review rejected a proposed native minimize/restore test as an unrequested user-visible change. It did not execute. Do not execute window actions without explicit user authorization. The safer exact-production-source preflight cancelled every action before mutation, but could not reach any application window: the workspace reported `com.apple.loginwindow`, and app activation did not change it. That run proves neither successful repaired discovery nor repaired window execution; do not mistake lock-screen results for another app compatibility failure.

The failure stage and direct capabilities were observed while the desktop was available before the change. Software tests and compilation verify the correction and existing safeguards. Native execution of the repaired client, physical trigger delivery, broader layout/cycle/full-screen behavior, macOS 26 and Intel remain unverified. Earlier accepted behavior and its limits are preserved in [window evidence](../verification/phase-4-windows.md).

Final code review: no mutation retry, permission request, event-path work, content collection or loss of executor focus/cancellation checks. Remaining AppKit snapshot lag fails closed through direct AXFrontmost validation; final-check-to-mutation races remain the existing platform limit.

## Next handoff

Install `apps/rebind/build/release/Rebind-1.0.0-8.dmg` manually, then test the actual Button 5 + down rule on an unlocked desktop. Confirm Finder, Chrome and ChatGPT minimize once and restore normally; record the installed artifact and result. Agent-run real-window actions still need explicit authorization after the earlier review rejection. Check other affected layout/full-screen/cycle actions only if relevant. Keep stage awaiting_verification until runtime evidence exists; installed build 7 cannot validate this change.
