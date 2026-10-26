# LIGHT-001: Keyboard lighting in Settings → Devices

- Updated: 2026-10-26
- Stage: ready_for_implementation (idle-timeout design saved/reviewed 2026-10-26; G915 connection required for the first write probe)
- Owner: unassigned; scoped design/research completed by Codex, released for hardware continuation
- Ownership checked: 2026-10-26 on `main` at `59a3aee`; existing uncommitted ACTION-001 work preserved
- Owned surfaces: Rebind.sketch screens 66–69, Foundations 12, `Light|Dark/Color Well/Default` components; future `Devices/`, `Packages/HIDPP` feature adapters, Devices settings view and catalog strings
- Requirements: SPEC §3.2 (device settings stay in Settings → Devices, rules stay category-wide), §10, §11; next release scope chosen by the user 2026-10-24
- Code baseline: `main` at `59a3aee`, current app package 1.0.0 (20); no lighting code added

## Outcome and scope

For a Logitech keyboard that reports HID++ lighting, Settings → Devices lets the user turn the backlight on/off, set its brightness and pick one static color for the keys and one for the G logo. An optional low-battery mode (Keep colors / Red / Blinking red) turns the lighting red below 10 % while not charging and restores the saved colors after charging. While G HUB runs, lighting controls are disabled behind the existing companion-app banner pattern.

Idle timeout (user addition 2026-10-26): add **Turn off when idle** using the keyboard’s native inactivity/power-mode configuration. Proposed presets: Device default, 30 seconds, 1/2/5/10 minutes, Never. Initial Device default does not write; returning to it restores the captured native policy. Show only confirmed supported options, preserve a current custom value, and omit the row on unsupported hardware. Never needs confirmed firmware semantics. Idle-off takes precedence over low-battery colors; battery refresh must not wake the lighting. No host keyboard-content collection, global activity monitor or periodic idle polling.

Out of scope (user decision 2026-10-24: drop anything complex or unclear): per-key colors (0x8081), animated effects (wave, ripple, cycle), lighting actions in rules, non-Logitech lighting, OpenRGB/Solaar code (GPL; Rebind is MIT, protocol facts only).

## Hardware facts (read-only probe, agent-observed 2026-10-24)

G915 TKL on Lightspeed receiver `046d:c545`, slot 1, macOS 27.0.1. A local read-only HID++ 2.0 probe (feature set enumeration and `getInfo`/`get` calls only, no writes) found 0x8040 Brightness Control (max 100, 5 steps, current 50), 0x8071 RGB Effects and 0x8081 Per-Key Lighting V2, plus 0x8100 Onboard Profiles. 0x8071 reports two zones: zone 0 location 0x0002 (logo) with Disabled/Static/Cycle/Breathing; zone 1 location 0x0001 (keys) with Disabled/Static/Breathing/Cycle/Wave/Ripple and an unidentified effect 0x0C. Static color and breathing color exist in both zones, which covers the scoped design. Probe source stayed in the session scratchpad and is not versioned.

## Acceptance

- [ ] Write probe on G915 TKL: set brightness and a static color, then check after keyboard sleep, power cycle and receiver reconnect, and with G HUB running. If the keyboard cannot keep or reliably regain the setting, defer the feature instead of adding a workaround.
- [ ] Native idle timeout: read/modify/write/readback without changing unrelated flags/dimming; verify timeout, activity wake, Never, restoration, reconnect/power-cycle and G HUB ownership. Default does not change the keyboard. No unsupported choice exposed.
- [ ] Brightness/color/on-off apply live and persist per keyboard; reapplied after reconnect/wake; nothing is written while G HUB runs.
- [ ] Low-battery mode switches at < 10 % not charging and restores saved colors/brightness after charging or recovery above the threshold; default is Keep colors.
- [ ] Only keyboards reporting 0x8040/0x8071 show the section; a one-zone device shows a single Color row.
- [ ] Six-language copy, Light/Dark, keyboard/VoiceOver for the new controls; tests for the HID++ request encoding and low-battery state transitions.
- [ ] Task/evidence, STATE, CAPABILITIES and research updated before handoff.

## Sketch source

Latest scoped save **2026-10-26**, SHA-256 `aac671f693c59438515fb3eb79529787f2cbe4a905d950811bbc7e4515158ef0`. Screens **66–68** now include the idle-timeout row in Light/Dark, including disabled G HUB state and low battery. New **69 · Settings · Devices · Idle timeout menu**, Light/Dark, shows the seven proposed choices. Existing Settings Row/Select and Menu Item components are reused, with a stacked popup; no new icon/token. Frames are extended without scaling their controls; shorter app windows use the existing Settings scroll area. Foundations **12 · Keyboard lighting and idle timeout · 26 October** contains the self-contained supported-subset/default/failure/ownership/idle-wake/accessibility contract. All eight affected screens and the contract were screenshot-reviewed through live Sketch MCP; alignment, control sizes, text and popup order were corrected and verified before saving. No versioned image export.

## Mechanism refresh and current hardware — 2026-10-26

Read [Logitech’s feature index](https://github.com/Logitech/cpg-docs/blob/master/hidpp20/README.rst), the maintained [Solaar feature inventory](https://github.com/pwr-Solaar/Solaar/blob/master/docs/features.md) and [OpenLogi’s RGB Effects implementation reference](https://openlogi.org/hidpp/features/x8071-rgb-effects). 0x8071 has a native power-mode configuration query/set path (function 7, selector read/write) containing flags and separate power-save/off timeouts in seconds. A device-specific read-modify-write must preserve unrelated values; field presence alone does not prove G915 behavior or Never encoding. RGB software ownership and battery overrides must coexist with native power modes. OpenLogi is a Rust reference rather than a drop-in Swift/macOS dependency; no source copied or package installed. GitHub/SPI discovery did not establish a suitable ready Swift implementation. Native IOKit plus the existing MIT HIDPP transport remains the intended route, after hardware validation; GPL sources are protocol references only.

A read-only public IOHIDManager inventory on macOS 27.0.1 found Logitech USB receivers **c52b/c534**, with no G915 Lightspeed **c545**. The inventory did not open/seize devices, read keyboard reports or send HID++ commands. No lighting write, timeout change, takeover, app integration or new build was performed. The October 24 probe remains the only G915 capability evidence. The first required write/idle/wake/persistence check cannot be established without the keyboard. The user explicitly allows continuing this hardware-dependent work later when it is connected; independent design/research is complete.

## Next handoff

Code: when the G915 is connected, identify the matching interface/slot, read brightness/zones/current software ownership and native power-mode config, then run the bounded write/readback + timeout/activity-wake/restore probe. Test brightness/static color persistence through sleep, reconnect/power-cycle and G HUB ownership before exposing controls. If confirmed, add HID++ 0x8040/0x8071 adapters to `Packages/HIDPP` following `AdjustableDPI.swift`, and the Devices card from the saved source.
