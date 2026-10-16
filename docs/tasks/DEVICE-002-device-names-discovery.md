# DEVICE-002: Device names and keyboard visibility

- Updated: 2026-10-16
- Stage: awaiting_verification
- Owner: Unassigned; /root implementation session released 2026-10-15
- Ownership checked: 2026-10-15 on `ca2e4c8`; prior INPUT-011 changes preserved; scoped ownership now released
- Owned surfaces: device discovery/classification, device name persistence, Devices cards/name editor, battery menu labels, affected tests/catalog/docs
- Requirements: SPEC §3.2 and Settings; user-requested local device names and G915 visibility
- Code baseline: original work started on `1401d30` plus INPUT-011 fixes (subsequently `ca2e4c8`); implementation is included in `fdaef8f`, confirmed by REVIEW-001.

## Outcome and scope

Persist local display names for Devices and the battery menu without renaming hardware or changing its settings identity. Show discovered Logitech keyboards (including G915 TKL) and system-reported battery devices in Devices. Audit the HID++ headset gate using hardware descriptors and regression tests. Names follow the existing vendor/model identity; identical models share a name.

## Acceptance

- [x] Local name persistence/reset, backup round trip, old-schema migration and protected-storage tests.
- [x] Keyboard inventory/card implemented; G915 type/charge confirmed by a read-only protocol probe and isolated native specimen.
- [x] Vendor-only headset gate and unknown/non-input HID++ kinds covered by regression tests; G435 gate checked against live descriptors.
- [x] Build and affected tests pass; six-language Light/Dark specimens fit; final diff reviewed.
- [ ] Running app: rename/save/cancel/reset, menu width, restart, receiver reconnect/wake and G915 card.
- [x] Sketch inventory and Rename states saved through [REVIEW-001](REVIEW-001-production-review.md).
- [ ] Keyboard/VoiceOver focus.

## Sketch source

Initial implementation inspected Devices and naming-sheet patterns without editing Sketch. On 2026-10-16 [REVIEW-001](REVIEW-001-production-review.md) saved inventory, Rename and battery/menu states. [DESIGN](../DESIGN.md) owns the current source/digest; native runtime/VoiceOver checks remain open.

## Implementation and verification

- Persistence: schema 41, migration from 1–40, full backup/import carries local names; profile-only exports exclude them. UI-only saving never restarts/cancels the input engine or applies hardware settings. Empty/original name removes the override; controls/overlong names are rejected. Protected original files stay protected.
- Inventory: Logitech keyboards are retained separately from mice, even when a battery read fails. Keyboard-only receivers no longer become fallback mouse cards. Existing sleeping-device state is retained. System battery types use HID usages; unknown vendor management services use a generic battery icon instead of guessing from a user-editable name. No extra monitoring grant or new dependency.
- Read-only hardware audit, agent-observed 2026-10-15 on Apple Silicon macOS 27.0.1 / Xcode 27: IOKit descriptors for G435 (`046d:0adf`) expose FF00/1 and Consumer 0C/1 only, so the production `allowsHIDPP` gate rejects it before `HIDReportDevice` opens. Receivers `c545`/`c539` expose mouse/keyboard usages and pass. A temporary probe compiled from the current `MouseHardware`, `HIDReportDevice`, `LogitechDevice`, settings and vendored HIDPP object read known slot 1 once: G915 TKL reports keyboard, battery 48 %, no mouse settings; G603 reports mouse, battery 90 %, mouse settings present. The probe never called settings apply, receiver-register writes, diversion or the input engine. This verifies protocol/discovery classification only, not app lifecycle/UI.
- Research: [Apple usage-pair key](https://developer.apple.com/documentation/iokit/kiohiddeviceusagepairskey), [Apple HID manager matching](https://developer.apple.com/documentation/iokit/1438371-iohidmanagersetdevicematching). Existing public IOKit and MIT HIDPP adapter are sufficient; no capture mechanism or dependency was added.
- Polling review also removed a duplicate battery-feature lookup caused by evaluating a side-effectful lazy collection twice. Keyboard tests assert that only name/type and battery are queried and that no hardware command is written.
- Agent-run software checks (macOS 27.0.1 / Xcode 27): `apps/rebind/scripts/dev.sh build` passes. A full `apps/rebind/scripts/dev.sh test` passed 788 Swift Testing tests + 15 XCTest layout tests before final decoder/type-test hardening and the duplicate-query fix. After those changes, the same command with `-only-testing:rebindTests/DeviceNamesTests`, `DeviceNameSaveTests`, `DeviceClassificationTests`, `LogitechKeyboardTests`, `MouseHardwareSettingsTests`, `ConfigurationBackupTests`, and `DeviceNamesLayoutTests` passed 24 Swift Testing tests + one native layout test. Final fixture-only rerun of `DeviceNamesLayoutTests` also passes.
- The native test covers 24 card/sheet combinations (six languages × Light/Dark, card width 560 and sheet width 440). Agent visually inspected Russian Light and German Dark PNGs locally; long original names wrap, charge and Rename remain visible, and naming controls/hint/buttons fit. The first fixture check incorrectly compared unconstrained ideal width with constrained width; corrected to `sizeThatFits(in:)`. The Dark card specimen also needed its normal `ThemeCanvas` backdrop for the translucent surface. No production theme change was needed. The first strengthened mock assertion exposed the duplicate feature lookup above; it passes after the production fix.
- The final Debug test-host app is built from `ca2e4c8` plus this task’s modified/new source and catalog. `Rebind.debug.dylib` SHA-256: `474462ba5a4c97e9fb6f087473c84426542b92808efe1d8a6e13e8b65c70f23b`. Build output and routine PNGs stay local. No production app launch, user configuration edit, remapping, permission change, Git commit or Sketch save was performed.

## Review and open checks

No outstanding source-review finding in this scope. Model names remain separate from mutable display names and support-report hardware identity; persistence errors stay visible. Native buttons expose localized Rename plus the current device as their accessibility value. Main-app menu projection and full-screen resizing were not established by isolated specimens. Hardware risk remains reconnect/sleep lifecycle and other receivers; system battery services lacking a recognized HID usage have a generic icon in the battery menu and are excluded from Devices (2026-10-16 follow-up).

Manual acceptance: in the fresh app, rename G915 to a short name, check the battery menu, cancel a second edit, clear the name to restore the original, then repeat after relaunch and receiver reconnect. With keyboard and VoiceOver, reach Rename, verify initial field focus, Save/Cancel via Return/Escape, and focus return to the initiating control. These runtime/accessibility checks are pending.

## Next handoff

Runtime: verify the checklist above on the fresh Debug build without broadening hardware claims. The keyboard/inventory and Rename designs are saved; inspect them live during comparison.


## Follow-up 2026-10-16: Headsets excluded from Devices

User scope: keep headsets entirely out of the Devices tab. The accessory-list projection now accepts system battery entries only for recognized mouse, keyboard or trackpad kinds. Headsets/unknown services classified as `other` cannot become cards just because macOS reports their charge; user-chosen names do not affect this decision. The battery-menu source and the existing pre-HID++ polling gate are unchanged. This intentionally also hides unclassified system battery accessories from Devices.

Owner: /root implementation session, scoped change on `ca2e4c8` plus the existing uncommitted DEVICE-002 work; released after checks. Changed source: `Devices/MouseHardware.swift` only. No visual composition/copy, hardware commands or configuration changes. Existing running-app/reconnect and accessibility acceptance remains open. Next runtime check: open Devices with G435 and G915 connected; G435 must have no card and G915 must retain its keyboard card. Verification (agent-run, macOS 27.0.1 / Xcode 27): `apps/rebind/scripts/dev.sh build` passes; `apps/rebind/scripts/dev.sh test -only-testing:rebindTests/DeviceClassificationTests -only-testing:rebindTests/LogitechKeyboardTests` passes. `git diff --check` passes. Source review confirms `other` entries are filtered before card construction. No new test scaffolding or app launch for this small projection change; actual Devices rendering remains a runtime check.
