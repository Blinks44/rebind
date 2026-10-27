# FIX-004: Release held input during long Apple Shortcuts

- Updated: 2026-10-27
- Stage: awaiting_verification
- Owner: Codex implementation
- Ownership checked: clean main at `7a6b224` after the requested checkpoint commit
- Owned surfaces: Shortcuts process/dispatch, the existing bounded workspace handoff, related tests, SPM/project references/notices, build number and affected records. No visual/Sketch/catalog change planned.
- Requirements: SPEC held-output/safety and Apple Shortcuts contracts; REVIEW-003 F1
- Code baseline: `7a6b224`, source/package 1.0.0 (25), schema 47

## Outcome and scope

Keep held-key/modifier release responsive while a selected Apple Shortcut runs. Reuse the existing single bounded asynchronous workspace handoff, preserving ordinary action ordering and generation checks. Adopt the reviewed stable Swift Subprocess 1.0.2 transport for list/run output, cancellation, timeout and child cleanup. No new callback task/actor hop, real remapping or user-configuration change.

The pre-fix injected diagnostic in REVIEW-003 confirms held release remains queued until synchronous command execution returns. This is the bounded first implementation slice; configuration/device/catalog refactors remain separate.

## Acceptance

- [x] Held release progresses while an injected long shortcut is still active; ordinary commands do not overtake it.
- [x] Pause/edit/profile/permission/stop cancellation terminates the child and ignores stale completion; one task/request slot, bounded queue.
- [x] UUID-only argv, no shell/stdin/stderr collection, bounded list output and nonzero/overflow/timeout/cancellation tests retained.
- [x] Stable package compatibility/license checked before integration; dependency pins/notices/research updated.
- [x] Affected tests/build pass; Debug/Release incremented together; signed app/DMG and image verification succeed.
- [x] Task, STATE/capabilities/history and review finding reconciled; installed-runtime limits remain explicit.

- [ ] Installed long-Shortcut/physical held release/order and pause/quit acceptance (next section).

## Implementation and evidence

- Requested checkpoint commit: `7a6b224` (RGB, error fixes and architecture/library audit). This patch is the first bounded implementation slice from REVIEW-003; other findings are unchanged.
- `ActionWorker` submits `.appleShortcut` to the existing `WorkspaceRequest` slot. `WorkspaceActionExecutor` awaits execution; the worker continues held release/repeat servicing. The slot blocks later ordinary actions until completion/cancellation cleanup. Existing mailbox generations protect profile/edit/pause/stop transitions and stale errors. Progress derives from the request target, avoiding a second mutable flag and preserving separate Shortcuts/workspace UI labels.
- Swift Subprocess **1.0.2**, exact `dbe21bd7dfd4ffef8c32588918542a8abfa1b54c`; tools 6.2/macOS 13, Apache-2.0 root license and upstream copyright bundled (no NOTICE file). Source headers also name the Swift Runtime Library Exception. Stable manifest/license/README/SPI reviewed before adoption; isolated `printf` prototype passes on Swift 6.4. The manifest resolves swift-system 1.8.1 for non-Apple platforms; macOS uses SDK System. [Dependency register](../research/DEPENDENCIES.md) and lockfile own pins/limits.
- Replaces the custom pipe/fcntl/read/poll/kill transport with structured async process collection/teardown. CLI input is null; stderr and run output discarded; list output capped at **262,144 bytes**. UUID remains the sole run target, without shell/name interpolation or payload. Waiting limits remain 10 seconds for list / 60 for run. Only an active command has a 20 ms cancellation/authorization monitor; group cancellation awaits child teardown (SIGTERM, 250 ms grace, then kill if needed), never process-group termination. Accepted workflow effects cannot be recalled by stopping the CLI.
- Focused `dev.sh test` passes: **31 methods / four suites** (61 parameter-expanded passes), `Test-rebind-2026.10.27_22-30-15-+0300.xcresult`. Deterministic gates prove held modifier release arrives while the injected command remains active and the following window action waits. Lifecycle changes, protected/revoked posting, progress, UUID routing, failure/cancellation, null input, literal argv, successful exact output bound, overflow/nonzero/timeout and parent-task cancellation pass. Native fixtures are only harmless printf/cat/false/sleep/head/yes; no user's Apple Shortcut or real key output.
- Build **1.0.0 (26)**, Debug/Release equal, schema 47 unchanged. All **955 Swift Testing methods / 148 suites** pass: `dev.sh test` with the 15 native XCTest layout/navigation classes skipped, `Test-rebind-2026.10.27_22-31-02-+0300.xcresult`. No visual/copy change; prior build-25 native layout evidence is retained, not presented as rerun. Only the existing no-AppIntents extraction warning appears.
- Final strengthened parent-task cancellation check waits for active-command authorization checks instead of cancelling at pre-spawn. All seven process methods pass again: `Test-rebind-2026.10.27_22-34-44-+0300.xcresult`. Local Markdown targets and `git diff --check` pass.
- Packaging passes: universal arm64/x86_64 Release, existing signer retained, strict deep app signature, strict DMG signature, `hdiutil verify` and EdDSA appcast generation. `apps/rebind/build/release/Rebind.dmg`, SHA-256 `3fed206fc6be15a25acd189592304c82c62f89c9d4a2a2ae306e823fc5ac52f9`. No installation, publication, real remapping, user-configuration or permission change.

## Remaining runtime acceptance / next

Install the signed build 26 manually and run an intentionally slow selected Shortcut while releasing a previously held key/modifier. Verify immediate release and subsequent action ordering, then pause/quit during the run and confirm no stuck output or stale error. Existing accepted Shortcuts happy-path effects remain preserved; this software/injected coverage does not establish real workflow cancellation, physical input delivery, macOS 26 or Intel runtime behavior. Other REVIEW-003 simplifications are separate follow-up work.
