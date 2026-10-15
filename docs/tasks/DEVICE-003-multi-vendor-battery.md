# DEVICE-003: Multi-vendor device discovery and battery

- Updated: 2026-10-16
- Stage: awaiting_verification
- Owner: Unassigned; /root implementation session released 2026-10-16
- Ownership checked: app edits on main `1a0801b` (DEVICE-002 was committed externally during source research); this task is uncommitted. Concurrent documentation maintenance preserved.
- Owned surfaces: Devices discovery/battery adapters, Bluetooth purpose resource/project key and permission button, tests, battery-related SPEC/capability/state/research sections and bundled source notices
- Requirements: SPEC §3.2; broad mouse/keyboard recognition and battery support, preserving the headset exclusion

## Outcome and acceptance

- [x] External mice, keyboards and trackpads recognized across vendors, including devices with no readable battery. Built-ins and consumer/vendor-only headset collections excluded.
- [x] Driver-provided macOS registry and standard HID Battery Strength reads.
- [x] Optional standard Bluetooth Battery Service (BAS) for already-connected HID peripherals; explicit access button and purpose text in six languages, no nearby-device scan or pairing. Static Report Map must identify a supported input before Battery Level is read. No typed key reports collected.
- [x] Read-only known-model Razer/SteelSeries USB adapters from audited permissive sources. No arbitrary vendor-wide command guessing, device settings writes, driver installs or permission grants through tools.
- [x] Existing Logitech HID++, local name identity, mouse settings and category-wide rules preserved. Interface/connection changes reject late battery results; one in-flight USB read per location. Non-configurable HID++ mice without a conventional pointer interface retain an identity card even when battery data is unavailable.
- [x] Software build/tests, native fixture review, source/license audit and records complete.
- [ ] Named Razer/SteelSeries USB hardware, standard HID/BAS peripherals, Bluetooth allow/deny/revoke/off/on and reconnect/sleep acceptance.
- [ ] Runtime keyboard/VoiceOver focus and Sketch reconciliation of the permission state.

## Implementation and source decisions

[Audit and compatibility limits](../research/multi-vendor-batteries.md) owns source URLs, full revision pins, licensing/platform/maintenance facts and rejected candidates. Native IOKit/CoreBluetooth plus small MIT codec/profile adaptations were selected over broad app/library products or Rust/Python runtimes. Full MIT notices are bundled. No external package, installer, driver, helper, privileged path or third-party script was run.

- `PeripheralBatteryReader`, `PeripheralBatteryReading`: driver percentages and precisely matched Battery Strength elements; invalid/null ranges remain unknown. Native synchronous feature I/O stays on a separate utility queue, with the OS's device-call timeout; no measured hard device-IPC deadline is claimed.
- `VendorBatteryProtocol`: 22 Razer and 24 SteelSeries USB product/transport profiles, not 46 distinct models. USB interface number, input category and report capabilities are checked first. SteelSeries interrupt reads require a vendor control collection with no mouse/key usages; padded and short forms repeat only the same known battery query. Razer uses only battery/charging feature commands with status, transaction, command and checksum validation.
- `BluetoothBatteryMonitor`, `HIDReportMap`: public connected-HID retrieval, bounded static descriptor parsing, five-second read deadline and logical connection release. Failed connections do not leave a permanent pending-disconnect block; pending cancellations cannot close a newer read. Missing services/error/denial yields no invented percentage. A unique native name/kind match preserves the existing card/alias identity; ambiguous identical names are not attributed to one physical device.
- `MouseHardware`: independent device management, all external keyboard/touchpad matching, common readers, source priority and stale-result guards. Zero location IDs use a registry ID. Logitech readings remain preferred. No input engine behavior changed.
- `DevicesSettingsView`, `Localizable.xcstrings`, `InfoPlist.xcstrings`, Xcode project: localized Bluetooth access explanation/request/privacy-settings route. Bluetooth is optional and does not gate normal rules; tooling did not request/grant it. Tests/fixtures cannot start discovery from `refresh` on an unstarted model.

## Verification

Agent-run 2026-10-16, Apple Silicon macOS 27.0.1 / Xcode 27 / Swift 6.4, `1a0801b` plus this task's uncommitted files:

- `apps/rebind/scripts/dev.sh build`: pass. Final Debug `Rebind.debug.dylib` SHA-256 `5b9a545b11eb0c9a2075f6374f4f63b42ca36222e9e41182d9afb89752e17a2c`.
- Full `apps/rebind/scripts/dev.sh test`: **802 Swift Testing tests + 17 XCTest native layout tests pass**, before the final endpoint/cancellation/framing hardening.
- Final `apps/rebind/scripts/dev.sh test` with `-only-testing:rebindTests/PeripheralBatteryTests`, `VendorBatteryProtocolTests`, `HIDReportMapTests`, `BluetoothBatteryIdentityTests`, `DeviceClassificationTests`, `LogitechKeyboardTests`, `LogitechMouseTests`, `DeviceBatteryLayoutTests`, `DeviceNamesLayoutTests`: **19 Swift Testing tests + 2 native layout tests pass**, followed by the successful normal build above. Covered scale/null handling, corrupt/mismatched replies, unknown/headset IDs, control-interface routing, static HID classification/bounds, ambiguous Bluetooth identity and Logitech regressions. Initial compiler CF-import/nullability mismatches were corrected; no final test failures.
- Native main-window fixture at 880 × 600 in all six languages, Light/Dark: pass. Russian Light/German Dark renders visually reviewed: permission text/button and empty state fit; existing naming/card fixtures also pass. No input capture, device discovery or Bluetooth manager was started by fixtures. Actual spoken VoiceOver, focus return and system permission dialog remain unverified.
- Built app contains the Bluetooth purpose key and localized `InfoPlist.strings` for EN/RU/DE/FR/ES/zh-Hans (checked with `plutil`). The first Python plist read could not parse the generated XML encoding; native `plutil` validated all six outputs.
- Standalone descriptor-only native probe using independent IOHIDManager opens successfully and enumerates the connected Logitech receiver/input interfaces; G435 exposes Consumer/vendor collections. No individual device open, battery command, settings change or CoreBluetooth access. This verifies discovery API operation only. No Razer/SteelSeries or standard-BAS hardware was available; protocol tests are injected fixtures.
- `git diff --check` for this task’s app sources and owned records, kept/ignored path checks, and affected local documentation links: pass. The global diff check currently reports a concurrent, unrelated SPEC §S2 Markdown hard-break trailing space; that active documentation-maintenance edit was preserved. Routine logs/PNGs and research downloads stay outside the repository. Existing unrelated documentation/skill edits are excluded from this task’s claims.

## Sketch source and review

Live Rebind Devices frame 46 (and existing 39–41 source index) re-resolved and inspected through MCP on 2026-10-16. Existing header/caption/secondary-button/card tokens reused. The optional Bluetooth permission state is a scoped native implementation addition requiring Sketch reconciliation; no Sketch content was edited or saved. Source review found and fixed stale connection handling, raw mouse/key interface rejection and unavailable-battery inventory retention. Full source audit/limitations are linked above.

## Next handoff

Runtime: on this fresh build, connect a named Razer or SteelSeries USB device and a standard Bluetooth/HID battery device; verify identity, battery source, charging where supported, sleep/reconnect, optional Bluetooth authorization/revocation and G435 exclusion, then regression-check G915/G603 and local names. Record OS/model/transport and actual grant state. Unsupported/private protocols remain unknown; Razer proprietary BLE and Corsair USB are not claimed.

Design: reconcile the prepared Devices Bluetooth access states and generic keyboard/trackpad cards in the established live Sketch source. Implementation is ready for those bounded runtime/design checks; broad product/platform acceptance remains open.
