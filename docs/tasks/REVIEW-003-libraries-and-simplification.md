# REVIEW-003: App architecture, library reuse and simplification audit

- Updated: 2026-10-27
- Stage: done (review delivered; recommendations are not implemented)
- Owner: Codex review complete; production source unchanged; review ownership released
- Ownership checked: main at `8eba440`, preserving the uncommitted LIGHT-001/FIX-003 continuation (source/package 1.0.0 (25), schema 47)
- Owned surfaces: this audit and its concise STATE/history/research index entries; no app, package, catalog or Sketch changes
- Requirements: AGENTS dependency preference; ENGINEERING §§2–7; existing SPEC safety, persistence, device and localization contracts

## Outcome and scope

Review the native application's architecture and custom mechanisms, compare reusable libraries/system APIs against actual requirements, and identify concrete simplifications with priority, source evidence, licensing/maintenance/platform limits and estimated effort. Cover input/touch, device protocols, actions/window/audio, persistence, UI/lifecycle, updates and test/build boundaries. Website implementation and pixel/design review are outside this app audit.

Preserve existing behavior and uncommitted work. Research and analysis do not authorize dependency installation or a broad rewrite. Distinguish demonstrated defects, maintainability opportunities and candidates requiring a prototype/hardware evidence. No claim that every line, platform or hardware combination has been dynamically verified.

## Acceptance

- [x] Inspect current source/settings/dependencies and existing research decisions.
- [x] Refresh relevant primary-source libraries/native API candidates, including license and maintenance evidence.
- [x] Record actionable findings with file/line evidence and tradeoffs; separate worthwhile reuse from unsuitable replacements.
- [x] Provide an ordered next implementation slice and evidence limits.
- [x] Review documentation links and `git diff --check`; update STATE/history/research index.

## Result and coverage

The highest-value replacement candidate is **Swift Subprocess 1.0.2**, together with a correction to long-action scheduling. The clearest small native simplification is the SDK's **AudioHardwareSystem** API. The larger maintenance opportunities are explicit configuration transactions, narrower device-service ownership and less repeated action metadata. A general dependency/framework migration is not justified by the inspected requirements.

Inventory: **207 app Swift files / 17,507 lines**, plus the local HIDPP package, app test target, catalogs, project/release configuration and credited source adaptations. Package references contain one remote dependency, Sparkle 2.10.0, and the local MIT HIDPP package. The app target uses macOS 26, Swift 6 language mode, MainActor default isolation and complete strict-concurrency checking. Coverage is a source/dependency/architecture audit across all source areas with deeper callback, action, storage and device reviews; it is not a line-by-line security certification or a new complete runtime/hardware pass.

## Findings

Follow-up: [FIX-004](FIX-004-shortcuts-held-release.md) implements F1 and adopts Swift Subprocess; its software checks pass, with installed long-Shortcut/held-output acceptance still open. Build 27 adopts the native `AudioHardwareSystem` default input/output lookup from the Core Audio row ([2026-10-28 review](../history/2026-10.md#2026-10-28-review-of-october-2627-commits)); mute/volume HAL logic is unchanged. Findings below preserve the audit snapshot at `7a6b224`.

### F1 · P1 · Long Apple Shortcuts execution blocks held-key release

Pre-fix evidence (checkpoint `7a6b224`): [ActionWorker.swift:134](../../apps/rebind/rebind/Actions/ActionWorker.swift#L134) drains a held output on the same serial worker that calls synchronous `performAppleShortcut` at [line 201](../../apps/rebind/rebind/Actions/ActionWorker.swift#L201). [AppleShortcuts.swift:19](../../apps/rebind/rebind/Actions/AppleShortcuts.swift#L19) gives this operation a 60-second timeout. [ShortcutsProcess.swift:36](../../apps/rebind/rebind/Actions/ShortcutsProcess.swift#L36) polls/sleeps until the child exits. Normal physical release marks an already-pressed held output released without invalidating the current action generation.

A deterministic injected-worker diagnostic confirmed the pre-fix sequence: start with one already-pressed synthetic modifier; enter an Apple Shortcut handler; mark the source released; the dispatch remains current, no release is delivered when the handler returns, and the release is delivered only on the next worker service. No real shortcut, process, permission change or key event was used. This confirms delayed ownership cleanup in the worker; visible stuck-key behavior on hardware was not exercised. A slow shortcut can therefore hold up release/repeat servicing and later ordinary actions for its execution duration, up to the configured timeout.

Recommended fix: use one bounded asynchronous long-action slot, preserving ordinary-action ordering while the worker continues high-priority held-output cleanup. Reuse the existing workspace handoff model instead of adding an unbounded task per event. Move the child transport to Swift Subprocess; retain UUID-only argv, no shell, null stdin/stderr, bounded output, explicit cancellation/timeout and child-only termination. Replacing `Process` alone without freeing the action worker does **not** fix this finding.

Estimated implementation: **1–2 engineering days**, including injected slow-command/release/pause/quit/cancellation and bounded-queue tests. First implementation priority. Required acceptance: release is delivered while the injected command is still running, the next ordinary action cannot overtake the command, and stale completion cannot update the current generation.

### F2 · P2 · Configuration persistence blocks MainActor and spreads transaction policy

Evidence: `AppModel` is MainActor-isolated. Its initializer synchronously loads and backs up storage ([AppModel.swift:73](../../apps/rebind/rebind/UI/AppModel.swift#L73)); ordinary changes call `persistConfiguration` synchronously ([line 692](../../apps/rebind/rebind/UI/AppModel.swift#L692)). [ConfigurationStore.swift:44](../../apps/rebind/rebind/Persistence/ConfigurationStore.swift#L44) encodes, rereads/decodes the existing file and performs an atomic write. Language, presence, rename, RGB acknowledgement, profile edits and full replacement have separate commit/error/engine-refresh paths. The recent guidance/error-dismissal regression illustrates why those distinctions must remain explicit.

The disk work is demonstrated by the call graph; no new UI stall/latency measurement was performed. Under slow storage or a large valid document it can block the UI and its MainActor touch-buffer consumer. Native configuration validation/protected-original behavior is valuable; deleting it to make saving shorter is not an acceptable simplification.

Recommended fix: one serial configuration-transaction owner with typed commit effects (UI-only, engine reconfiguration, confirmed device setting, explicit replacement). Encode/read/write off MainActor; publish the immutable result only after matching the revision that requested it. Preserve corruption/future-schema protection, atomic replacement, error precedence, manual language activation and profile/rule cancellation. Retain JSON/Codable and Foundation atomic I/O; do not move profiles to UserDefaults or introduce a database/provider hierarchy for this document.

Estimated implementation: **1–2 engineering days**, then storage-failure/stale-commit/import/language/hardware-ack regression checks. A broad async rewrite is unnecessary; begin with one UI-only save path and preserve ordered persistence.

### F3 · P2 · Trackpad idle polling can reuse the existing dormant-observer pattern

Evidence: [TrackpadCapture.swift:70](../../apps/rebind/rebind/Engine/Trackpad/TrackpadCapture.swift#L70) asks permissions, foreground and modifiers before checking whether a runtime exists. Without permission it reschedules after 0.1 s; with no active rules it reschedules after 0.5 s ([line 100](../../apps/rebind/rebind/Engine/Trackpad/TrackpadCapture.swift#L100)); quiet active surfaces use 0.25 s. By contrast [MagicMouseCapture.swift:91](../../apps/rebind/rebind/Engine/MagicMouse/MagicMouseCapture.swift#L91) can suspend its timer until configuration/control changes, using the existing `refreshControl`/buffer wake boundary.

Recommended simplification: share the narrow admission/wake policy for touch capture, checking cheap runtime admission before external API snapshots and sleeping an inactive observer until the existing configuration/lifecycle notification wakes it. Keep any external-device discovery fallback and permission-revocation guards explicit; do not remove them to obtain a zero-timer claim. Do not merge the actual Trackpad and Magic Mouse recognizers or suppression ownership.

Estimated implementation: **0.5–1 day**, plus named-device first-touch/reconnect/protected-context tests and a controlled energy comparison. This is a source-proven reduction opportunity, **not a measured CPU/battery improvement**.

## Other worthwhile simplifications

| Area | Concrete change | Why it helps / limit | Approximate effort |
| --- | --- | --- | --- |
| MouseHardware, 917 lines | Separate HID endpoint/session lifecycle, battery-source orchestration and settings application behind the existing observable inventory facade. Keep queues/access revisions in their owner. | UI inventory, receiver probing, Bluetooth/system/proprietary batteries, gesture diversion, smooth-scrolling attribution and RGB currently share one class. This reduces coupling and makes transport-specific tests smaller; merely moving extensions between files does not. No library supplies Rebind's combined ownership policy. | 1–3 days, after F1; hardware regression remains separate. |
| AppModel, 786 lines | Extract the configuration transaction policy in F2 first; keep lifecycle/window-facing state in the model. | A state-management framework would not remove file/device/callback contracts. Avoid a broad framework migration before isolating those responsibilities. | Covered by F2; other extraction only when it removes a real dependency. |
| Action catalog | Consolidate **parameter-free command metadata** (title, hint, symbol, category, fixed shortcut) into one descriptor source. Keep `RebindAction` typed and decoding/version checks exhaustive. | `ActionKind`/`ActionLabels` repeat command selection in several switches; adding entries touches multiple policy lists. A small descriptor for this subset can reduce drift. Do not build a plugin registry/code generator or flatten parameterized/window/media actions into strings. | 0.5–1.5 days; catalog round-trip/localization tests. |
| Core Audio | Replace repeated default-device C marshalling with `try? AudioHardwareSystem.shared.defaultOutputDevice?.id` and its input equivalent; evaluate native listener APIs locally. | The installed SDK exposes the Swift API from macOS 15, inside Rebind's baseline. Both lookups typecheck for an arm64 macOS 26 deployment target. This does not replace all HAL property logic. | 0.5 day for a small bounded patch and existing capability tests. |
| Core Audio safeguards | Retain device main-element mute semantics and same-device cancellation checks. | `isProcessInputMuted` mutes this process, not the user's global hardware microphone. Control `scope`/`element` convenience properties in the inspected SDK require macOS 27; a complete migration must preserve macOS 26 fallbacks. No audio setting was read/changed by the typecheck. | Include in the preceding patch's acceptance. |

These estimates are rough implementation planning, not deadlines; hardware/platform verification and unreported edge cases can add work.

## Refreshed ready-made candidates

Primary manifests/licenses/README files and GitHub default-branch commit metadata were fetched 2026-10-27. Commit dates below are evidence of source activity, not support guarantees. No candidate was installed, linked, copied into production or built as an app dependency.

| Candidate / source snapshot | License / declared baseline | Fit and decision |
| --- | --- | --- |
| [Swift Subprocess 1.0.2](https://github.com/swiftlang/swift-subprocess/tree/1.0.2), stable release 2026-10-16; main `dbe21bd7`, commit 2026-10-15 | Apache-2.0; exact 1.0.2 manifest tools 6.2/macOS 13. Darwin target uses the SDK's System framework; manifest also declares swift-system for other platforms. | **Best adoption candidate for F1.** Ready async process/output/cancellation/teardown implementation replaces the custom fcntl/read/sleep/kill transport. Stable-tag manifest, full license file and bounded-output/teardown documentation inspected. Needs an isolated build/behavior prototype and integration with the bounded action slot before adoption; no local package-build claim. |
| [Native Core Audio Swift API](https://developer.apple.com/documentation/coreaudio/audiohardwaresystem), installed SDK 27 overlay | Apple SDK API; AudioHardwareSystem/Object/Device available macOS 15; selected newer conveniences require 27. | **Prefer a small native simplification**, not an additional audio package. Two default-device lookups typechecked for macOS 26. No runtime/audio equivalence claim. |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts/tree/772133d9dbe800fdac0473226822994c5c162c58), 2026-09-11 | MIT; tools 6.2/macOS 10.15, MainActor default. Full lowercase `license`/`readme.md` and manifest retrieved. | Maintained recorder/registered-hotkey candidate. Does not replace arbitrary event interception, numeric mouse buttons, held ownership or selective suppression. Existing trigger/output recording shares its data/design; adopt only for a demonstrated recorder gap. |
| [AXSwift](https://github.com/tmandry/AXSwift/tree/e18a18453d135ad45809a384ee5139e05ea52def), default-branch commit 2021-11-14, non-archived | MIT; tools 4.0, no package dependencies or declared OS floor in manifest. | **Retain the current AX adapter.** A wrapper would still need Rebind's focus validation, per-handle timeout, stale-target/cancellation and bounded budget. Maintenance/Swift 6 adaptation cost is not justified to replace a relatively small native bridge. |
| [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport/tree/15c6bb0c6a2d2858559493a28ab23f7ac58648a3), 2026-05-28 | MIT; tools 6.2/macOS 15, XCF binary 4.0.0 and AsyncAlgorithms. | Real acquisition library, **prototype candidate only**. Does not remove private MultitouchSupport ABI risk or supply complete recognition/suppression/ordered loss handling. Rebind separates built-in/external Trackpad/Magic Mouse, retirement and bounded callbacks. Existing [touch audit](../research/touch-library-audit.md) source findings remain current at the same SHA. |
| [Subsurface](https://github.com/mrkai77/Subsurface/tree/88eb16b0a6f7a44a898cecff9e283298aa413936), 2026-09-30 | Apache-2.0; tools 6.2/macOS 13; Scribe dependency uses a main branch. | Acquisition/recognizer candidate; its newest-frame stream is not a direct substitute for ordered bounded contact edges. Pin/review transitive dependency and demonstrate edge loss/cancellation before replacing the native adapter. No new package build/hardware proof. |
| [CalmMouseCore](https://github.com/Malik1942/CalmMouse/tree/ce05497fbca6cf61ed9a35157bd6281e2e112ba8), 2026-09-22 | MIT; tools 5.9/macOS 13; exported pure-logic product. | Narrow reusable tap/scroll core, not complete private acquisition/paired suppression. Existing Rebind filtering is integrated/tested with different presets/ownership; no evidence yet that replacing it reduces the required adapter code. Retain as a targeted candidate, not a wholesale gesture-engine replacement. |
| [Defaults](https://github.com/sindresorhus/Defaults/tree/00a7465a0668a87fa159e779b9d80f1f9652357e), 2026-06-23 | MIT; tools 6.2/macOS 11. Current manifest also exports optional macros and declares SwiftSyntax. | Suitable typed UserDefaults wrapper, **not a replacement** for the atomic versioned rule/profile document and protected-file transactions. Adding it only for a few existing native preferences has little benefit. |
| [SimplyCoreAudio](https://github.com/rnine/SimplyCoreAudio/tree/b5430564b1d55adab3c331fb7574445a84bd4ceb), 2024-02-25 | MIT; **archived**; tools 5.1/macOS 10.12, C shim and swift-atomics. | Do not add an archived wrapper for the small HAL surface; prefer current native Swift APIs where equivalent. Full `LICENSE.md`, manifest and README retrieved. |

Swift Package Index discovery was refreshed for process/touch packages; the Subprocess listing was available, while touch searches did not establish current index build evidence. GitHub API/tag manifests take precedence over stale search snippets for the stable Subprocess release. The [RGB reuse audit](../research/rgb-lighting.md) remains the current cross-vendor RGB decision; OpenRGB is a separate optional server/backend, not a drop-in replacement for the app's native HID ownership.

## Custom code that should remain

- **Event matching, down/up ownership, held output and synthetic tags:** product behavior with bounded synchronous callback requirements. Registered-hotkey wrappers are a different mechanism. Bounded arrays of at most 16 pending actions/four held outputs do not justify adding a collections package solely for queue operations.
- **Gesture recognition/click and scroll suppression:** wrapper libraries do not establish native-gesture cancellation or Rebind's category/preset/protected-context behavior. Keep the private ABI isolated and experimental; do not claim a package makes it public/stable.
- **Native window policy:** the small AX bridge includes safeguards generic wrappers do not replace. Window geometry and same-target/cancellation checks are application policy, not accidental boilerplate.
- **Configuration codec/validation/migration:** keep JSON/Codable, bounds, corrupt/future-file protection and atomic writes. Improve ownership/scheduling rather than replacing this with a database or provider framework.
- **Design-system controls and native AppKit bridges:** shared theme/control primitives, anchored NSMenu tracking, keycaps, menu battery/DPI rows and window lifecycle address the app's selected design/native behavior. No new visual audit or claim that every bridge is necessary on every OS.
- **HIDPP and Sparkle:** ready solutions are already reused. Sparkle owns update verification/install UI; the app's adapter is only 50 lines. HIDPP transport and credited battery/smoothing/source adaptations avoid several full custom stacks. No custom update cryptography/network downloader needs replacing.
- **ServiceManagement, Foundation/AppKit and OS permissions:** native main-app login-item service and explicit permission controls are already the simpler ready-made solution; extra helper/framework layers would not remove current requirements.

## Evidence and limits

- Current branch/HEAD/status, 207-file source inventory, build settings, SPM lockfile/manifest, callback/unsafe/I/O/task/timer searches and key engine/action/storage/device/UI/lifecycle paths inspected. Existing source/research/contracts were reconciled; this audit creates no new capability support claim.
- One temporary injected test, `heldReleaseWaitsUntilSynchronousAppleShortcutReturns`, **passed while asserting the current undesired behavior**. It is diagnostic evidence, not a regression acceptance test. Native bundle: `Test-rebind-2026.10.27_21-54-45-+0300.xcresult`. Temporary test source was removed afterward; logs/results remain local and no real output was sent.
- Native Core Audio default input/output API typecheck passed with the installed compiler/SDK and deployment target `arm64-apple-macos26.0`. No hardware stream/mute/volume operation executed.
- No new complete app test run, dependency build, installed runtime session, profiling, permission change, actual user-configuration read/write, real remapping, device write, app packaging, Sketch save, Git commit or deployment. Existing build-25 evidence remains historical and is not presented as a fresh review run.
- Documentation-only final checks: affected link targets and `git diff --check`; no app build-number increment or new DMG is required.

## Recommended next implementation

**F1 is implemented in [FIX-004](FIX-004-shortcuts-held-release.md)** using the existing handoff and Swift Subprocess 1.0.2. Finish its installed long-Shortcut/held-output/quit checks before claiming runtime acceptance. Preserve ordinary-action ordering, bounded slots, generation cancellation and child/output restrictions; no whole-app framework or gesture rewrite.

After F1, address the narrow dormant-trackpad observer and configuration commit policy. Native Core Audio cleanup can be a small independent patch. Larger device/catalog extraction should follow a concrete boundary/test improvement, with no feature expansion. Findings remain open until implemented and verified; this task's completed status applies only to the requested audit.
