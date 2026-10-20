# REL-003: Finish available app release work

- Updated: 2026-10-20
- Stage: awaiting_verification
- Owner: Unassigned; available app implementation/checks complete, overall tester pass reported; identified distribution/platform evidence pending
- Ownership checked: main e070ec9 plus preserved uncommitted touch/UI/signing work
- Owned surfaces: Updates/, application menu/catalog and update tests, final acceptance evidence; performance trials removed
- Requirements: PLAN release preparation; SPEC §§9–11 and §15; latest request to finish available app work

## Outcome

The planned manual update command is implemented. Public unauthenticated GitHub API confirms Blinks44/rebind exists (200); latest release returns 404 before the first publication. The app menu checks only on explicit invocation, using an ephemeral session with no cookies/credentials/cache and bounded request/resource timeouts. It sends no input, settings or device data. Numeric version comparison handles v-prefixed release tags and omitted zero components; drafts/prereleases, malformed responses and errors are never reported as up to date. Native localized alerts distinguish new/current/no-release/error; new versions open the fixed GitHub latest-release page only after the user's button press. No auto-download, install or startup polling. Six languages are included. [GitHub REST mechanism](https://docs.github.com/en/rest/releases/releases#get-the-latest-release); no dependency added.

A measured paused Release consumed 1.5–3.1% CPU with a disposable empty configuration and no Accessibility grant. Profiling showed repeated TCC preflights. Experiments with slower paused UI polling and fully idle worker guards passed their software checks but did not produce a measurable CPU improvement (rechecks around 1.4–1.6%). All of those experimental code/test changes were removed before packaging: the release keeps the previously verified engine/permission cadence. No claim of improved idle CPU, permission bypass or active-rule performance is made. The real-grant/normal-profile measurement stays open.

## Verification

- Full prescribed dev.sh test: 898 Swift Testing methods / 140 suites and 25 native XCTest passes; two native physical-Tab methods explicitly skip for inactive/key-window conditions. No failures. Local result: Test-rebind-2026.10.20_08-01-05-+0300.xcresult under the isolated release-ui derived data.
- New update slice: five Swift Testing methods pass (17 version parameter cases plus response/localization checks). Initial nonisolated teardown compile error fixed with isolated deinit.
- Live engine-free production hierarchy: app-menu update command, real no-release response and Return dismissal pass; ScreenCaptureKit -3811 temporarily blocked capture, then fresh app binding succeeded. Keyboard Add → editor → Escape returns to Add; options → Edit → Escape returns to the original options button. Profile import/export panels open by keyboard; Escape cancels without file read/write and restores Import/options focus. No production rule/permission changes or output execution.
- Targeted SwiftUI/AppKit semantics review found no additional demonstrated blocker in the sampled controls; native roles/labels/disabled state and keyboard paths were inspected. Actual VoiceOver speech/reading, Voice Control/Switch Control, accessibility preferences and normal-engine coverage remain separate, not certified by AX trees.

- Performance trial evidence only: the UI trial passed 27 scoped tests; the worker trial passed 907 logic methods, including fresh Resume checks and held release under missing posting access. These extra trial changes/tests are absent from the shipping source because runtime CPU did not improve. After restoring the original engine, the final logic rerun passes **903 methods / 141 suites**, zero failures (Test-rebind-2026.10.20_10-23-50-+0300.xcresult in update-check derived data). Earlier 25 native passes/two inactive-runner skips remain applicable dated layout/focus evidence; no subsequent geometry change.

## Remaining acceptance and handoff

No first public release exists, so real newer-release delivery/opening remains pending; response interpretation has injected coverage. Public GitHub is no longer a publication dependency, but website links/deployment are separate work. Release tags should use vMAJOR.MINOR.PATCH; update comparison uses the marketing version, so public updates must increment it.

At the earlier REL-003 preparation the installed app did not use the stable Rebind Release designated requirement; REL-004 subsequently confirms installed 1.0/1 now does. The first transition can require a fresh Accessibility grant; grant survival must be tested between two distinct builds signed with the same stable identity. Preserve an export before replacing the app. Never treat permission regrant during a signer transition as proof of same-signer update failure.

The 1.0/1 artifact below is retained for the same-signer update rehearsal; [REL-004](REL-004-release-copy-and-documentation-audit.md) owns the newer 1.0.0/2 copy candidate. Use the short ordered checklist in [release candidate](../verification/release-candidate.md). macOS 26, hardware interruption/settings/idle-first-touch, real TCC transitions, fluent proofreading and measured callback/action latency remain open. No install, publication or Git commit.


## Previous candidate — 2026-10-20

Final source: main e070ec9 plus preserved uncommitted touch/UI/signing changes and Updates/ReleaseUpdateTests. No commit made. Final full logic rerun: 903 methods / 141 suites, zero failures. Native evidence from the complete earlier run: 25 passes / two inactive-runner Tab skips. The standalone update and final targeted runs overlap these counts; do not add them as unique tests.

Explicit non-quiet dev.sh release CODE_SIGNING_ALLOWED=NO ends BUILD SUCCEEDED; release.sh then completes under the unchanged stable Rebind Release identity. App strict/deep signature, DMG signature and hdiutil integrity checks pass. Earlier quiet compilation emitted an anomalous zero-exit SwiftCompile diagnostic; the explicit final build and final packaging complete without that diagnostic. Existing CompanionApp and hdiutil/create-dmg deprecation warnings remain.

Previous artifact: apps/rebind/build/release/Rebind-1.0-1.dmg, version/build 1.0/1, SHA-256 `ee033c3f76247c8a929a11057694a95065ddb65c07f4ff93b451bb52909adccb`. It supersedes earlier local packages at this filename. macOS 27.0.1 (26A434), MacBookPro18,2 / Apple Silicon. No installation, publication, permission change or configured output execution. All isolated measurement/test processes were stopped; the installed app was preserved.

The isolated paused/no-grant CPU result remains approximately 1.5%; neither the removed experiments nor a real-grant active-rule improvement is claimed. Do not mark the performance/platform/accessibility gates passed from this preparation. The subsequent tester report below supersedes the request to repeat the general walkthrough. First same-signer update preservation and actual newer-release availability need subsequent distinct/public Release builds.

## Tester acceptance — 2026-10-20

The user reports completing the requested checks successfully, with no bugs found. This is overall user acceptance of the current app work, not agent-observed hardware evidence or a scenario-by-scenario certification. Exact installed hash, test environment and individual accessibility/performance/platform results were not supplied; retain the existing identified-candidate and evidence limits in the [release queue](../verification/release-candidate.md#tester-report--2026-10-20). No new defect or implementation work is identified. Stage remains awaiting_verification for the separate distribution/platform gates. Next: prepare release notes/package handoff, verify two distinct stable-signer builds preserve rules/access, and resolve minimum-OS/support claims before publication. No app changes, builds, installation, publication or Git commit in this documentation update.
