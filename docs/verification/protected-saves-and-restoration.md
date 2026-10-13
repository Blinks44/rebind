# Protected ordinary saves and restored rules — 2026-10-11

STORAGE-001; SPEC §§3.3, 9, 12, 15.12. Engineering-only change on `main` / `ed0b5d9` plus ConfigurationStore, scoped AppModel persistence handling, three new test files and isolated Advanced/Main layout fixtures. Independent Sketch work is preserved. No new schema, dependency, product copy, visual design, capture mechanism or native action.

## Defect and repair

Startup and Advanced replacement already rejected unreadable/future files. Ordinary saves relied on startup validation: replacing the file with corrupt/future/oversized data after launch allowed a subsequent profile/rule/preference save to overwrite those bytes.

ConfigurationStore now validates an existing non-directory original through the same bounded ConfigurationBackup codec immediately before an atomic save. Rejected originals produce a distinct storage error. AppModel uses shared persistence handling for ordinary rule/profile/enable, Language, setup acknowledgement and whole-document commits: this error locks editing and reuses the existing unreadable-storage recovery state. Failed profile/rule/language/setup/resume saves retain the in-memory snapshot, language projection, action revision and pending output. Deliberate Pause still cancels pending output in memory and retains suppressed source-release ownership without writing the protected file.

A directory occupying the destination remains a recoverable filesystem write failure, without permanently locking editing. Valid current and legacy originals still permit explicit saves. Legacy preflight migration is in memory; reading alone does not rewrite. Candidate validation and the two-megabyte limit remain shared with backups; no file work enters an input callback.

Retained native Foundation after reviewing Apple's [fileExists(atPath:isDirectory:)](https://developer.apple.com/documentation/foundation/filemanager/fileexists%28atpath%3Aisdirectory%3A%29) and [atomic writing](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic) contracts. Atomic replacement protects against partial writes; preflight is not interprocess locking or compare-and-swap. A file changed between validation and replacement, or a concurrently changed healthy configuration, is not covered by this slice. No new dependency or third-party code is required for reuse of the existing codec/write mechanism.

## Injected software evidence

Environment: Apple Silicon MacBook Air, macOS 27.0.1 (26A434), Xcode 27.0 / Swift 6.4 / SDK 27. Temporary authored stores, injected permissions/login service and a shortcut-sender stub; AppModel.start() and global acquisition are never called. No real rules, grants, login registration, configuration or native output are changed.

- Before repair: `scripts/dev.sh test -only-testing:rebindTests/ConfigurationStoreProtectionTests -resultBundlePath build/ProtectedSaveBefore.xcresult` fails all three corrupt/future/oversized scenarios (six issues): the save returns and replaces the original bytes.
- After repair: `scripts/dev.sh test -only-testing:rebindTests/ConfigurationStoreProtectionTests -only-testing:rebindTests/AppModelStorageProtectionTests -only-testing:rebindTests/ConfigurationRestorationTests -only-testing:rebindTests/LanguageSettingsTests -only-testing:rebindTests/GeneralSettingsTests -only-testing:rebindTests/AdvancedSettingsTests -only-testing:rebindTests/AppModelPermissionSetupTests -only-testing:rebindTests/ProfileSwitchTests -only-testing:rebindTests/AppModelProfileTests -resultBundlePath build/ProtectedSaveAndRestore.xcresult` passes **45 functions / 152 expanded executions**, zero failures/skips, no xcresult runtime warnings.
- Store tests: changed corrupt/future/oversized originals survive; a directory failure can be repaired/retried; schemas 1–23 remain readable without rewrite and save explicitly as schema 24.
- Model tests: five save routes × three protected originals preserve snapshot/revision/queue and latch storage protection; Pause remains immediate and the consumed source up is still owned. Existing failed-write retry, language activation/projection, setup, Advanced rollback and profile cancellation tests pass.
- Restoration: six combinations of Press/Double Press/Hold × previously enabled/paused exercise actual file export, confirmed reset, validated/confirmed import and explicit resume. Both profiles, selected profile, rule identity/options and backup bytes survive. Pending old output never reaches the worker stub; pre-reset source release remains owned. Imported rules stay paused until resume, then dispatch exactly the selected profile's shortcut once. A newly constructed model reloads the saved configuration. This exercises the real matcher/worker with an injected sender, not physical capture or native delivery.

## Regression findings

The first complete run (`scripts/dev.sh test -resultBundlePath build/ProtectedSaveFullRegression.xcresult`) stopped progressing in the unchanged About Find XCTest. A local one-second process sample placed the main thread in XCTest issue reporting/CoreSymbolication, not storage. The identified test host and its xcodebuild process were terminated; exit 143 is incomplete evidence, not a pass. The exact trigger of the stall was not established.

The subsequent complete run (`scripts/dev.sh test -test-timeouts-enabled YES -default-test-execution-time-allowance 30 -maximum-test-execution-time-allowance 30 -resultBundlePath build/ProtectedSaveFullRetry.xcresult`) completed with **594 passing / 2 failing functions** (1,542 passing / 2 failing expanded executions), no skips. About passed with its previously recorded QoS priority-inversion diagnostic. Both failures were fixture reuse: Advanced/Main layout loops deliberately corrupted one temporary original, then attempted an ordinary save for the next state. The new guard correctly rejected those saves. Each state now uses a separate temporary path; no production protection is bypassed. Final full-suite evidence below covers both corrections.

## Final artifact and checks

- `scripts/dev.sh test -test-timeouts-enabled YES -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 120 -resultBundlePath build/ProtectedSaveFinalRegression.xcresult`: **584 Swift Testing + 12 XCTest = 596 functions / 1,544 expanded executions**, zero failures/skips. Both corrected layout fixtures pass. One xcresult runtime warning remains: the unchanged About Find test's user-interactive/default QoS wait. Its first-run reporting stall remains an unresolved diagnostic limitation, despite both completed retries passing About.
- `scripts/dev.sh build`: Debug succeeds. `codesign --verify --deep --strict --verbose=2 build/DerivedData/Build/Products/Debug/Rebind.app`: valid on disk and satisfies its designated requirement. This is local ad-hoc signing, not distribution/notarization evidence.
- `git diff --check`: passes; affected documentation links/status reviewed. AppIntents metadata extraction is skipped because the target has no AppIntents dependency; unchanged local Xcode destination/signing and test-host service diagnostics do not establish production behavior.

Final bundle: `build/DerivedData/Build/Products/Debug/Rebind.app`, baseline `ed0b5d9` plus this task's uncommitted Swift files. SHA-256:

| Artifact | Digest |
| --- | --- |
| `Contents/MacOS/Rebind` | `1c15e2dcd70011775f8eec235c317d5a63c1abf9f5c07c8291c0a6be7072abe1` |
| `Contents/MacOS/Rebind.debug.dylib` | `f58a2771d3e17a81de9fec5efdd3967a4bdc782039adaf7d91671cf5fbfa33ec` |

Result bundles/builds and local logs remain ignored; no agent Git commit or Sketch save. The production engine was not launched.

## Open acceptance

STORAGE-001 covers the bounded save guard and software restoration. On 2026-10-11 the tester confirms the requested Button 4 switching scenario: distinct audio/window actions in two profiles and no old action on switch. [Scoped report and evidence limits](profiles.md#user-switching-follow-up--2026-10-11): activation, individual routes and build identity were not restated. This does not verify export/reset/import, storage protection or the full delayed/held-source matrix. Full native panels/recovery/accessibility, physical restored-binding behavior, broader cancellation/routes, production relaunch/login and macOS 26/Intel remain separate gates in [UI-007](../tasks/UI-007-advanced-settings.md) and profiles. A subsequent [restart report](profiles.md#user-restart-follow-up--2026-10-11) confirms selection/rules/pause persistence in the tested setup; build/OS/restart method were not restated. The subsequent [restoration report](advanced-settings-native.md#user-restoration-follow-up--2026-10-11) confirms the named happy path without sequence/artifact details. Next check Advanced keyboard/focus/VoiceOver; detailed restoration, login launch and broader lifecycle coverage remain separate.
