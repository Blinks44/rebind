# LIGHT-001: Keyboard lighting in Settings → Devices

- Updated: 2026-10-24
- Stage: ready_for_implementation (design saved 2026-10-25; hardware write probe is the first implementation step)
- Owner: unassigned; design session released 2026-10-24
- Ownership checked: 2026-10-24 on `main` after `f961b3b`; released
- Owned surfaces: Rebind.sketch screens 66–68, Foundations 12, `Light|Dark/Color Well/Default` components; future `Devices/`, `Packages/HIDPP` feature adapters, Devices settings view and catalog strings
- Requirements: SPEC §3.2 (device settings stay in Settings → Devices, rules stay category-wide), §10, §11; next release scope chosen by the user 2026-10-24
- Code baseline: `main` at `f961b3b`; no code changed

## Outcome and scope

For a Logitech keyboard that reports HID++ lighting, Settings → Devices lets the user turn the backlight on/off, set its brightness and pick one static color for the keys and one for the G logo. An optional low-battery mode (Keep colors / Red / Blinking red) turns the lighting red below 10 % while not charging and restores the saved colors after charging. While G HUB runs, lighting controls are disabled behind the existing companion-app banner pattern.

Out of scope (user decision 2026-10-24: drop anything complex or unclear): per-key colors (0x8081), animated effects (wave, ripple, cycle), lighting actions in rules, non-Logitech lighting, OpenRGB/Solaar code (GPL; Rebind is MIT, protocol facts only).

## Hardware facts (read-only probe, agent-observed 2026-10-24)

G915 TKL on Lightspeed receiver `046d:c545`, slot 1, macOS 27.0.1. A local read-only HID++ 2.0 probe (feature set enumeration and `getInfo`/`get` calls only, no writes) found 0x8040 Brightness Control (max 100, 5 steps, current 50), 0x8071 RGB Effects and 0x8081 Per-Key Lighting V2, plus 0x8100 Onboard Profiles. 0x8071 reports two zones: zone 0 location 0x0002 (logo) with Disabled/Static/Cycle/Breathing; zone 1 location 0x0001 (keys) with Disabled/Static/Breathing/Cycle/Wave/Ripple and an unidentified effect 0x0C. Static color and breathing color exist in both zones, which covers the scoped design. Probe source stayed in the session scratchpad and is not versioned.

## Acceptance

- [ ] Write probe on G915 TKL: set brightness and a static color, then check after keyboard sleep, power cycle and receiver reconnect, and with G HUB running. If the keyboard cannot keep or reliably regain the setting, defer the feature instead of adding a workaround.
- [ ] Brightness/color/on-off apply live and persist per keyboard; reapplied after reconnect/wake; nothing is written while G HUB runs.
- [ ] Low-battery mode switches at < 10 % not charging and restores saved colors/brightness after charging or recovery above the threshold; default is Keep colors.
- [ ] Only keyboards reporting 0x8040/0x8071 show the section; a one-zone device shows a single Color row.
- [ ] Six-language copy, Light/Dark, keyboard/VoiceOver for the new controls; tests for the HID++ request encoding and low-battery state transitions.
- [ ] Task/evidence, STATE, CAPABILITIES and research updated before handoff.

## Sketch source

Rebind.sketch first saved 2026-10-24; current file after the 2026-10-25 parity cleanup and lighting fixes has SHA-256 `1f8125d0e2c3647ceed6e3e6eed3e042f8fa2921cd6e384a0ea061a46dbbd305`: Screens **66** (lighting card), **67** (G HUB running, controls disabled) and **68** (low battery active, Blinking red), Light/Dark; Foundations **12 · Keyboard lighting** holds the interaction contract; new `Light|Dark/Color Well/Default` components on 03 · Components. Light/Dark screenshot-reviewed through MCP after restoring the squashed toggle, slider and low-battery segmented control (2026-10-25); the user asked to finish the design and record it.

## Next handoff

Code: run the write probe above on the G915 TKL, then add HID++ 0x8040/0x8071 adapters to `Packages/HIDPP` following `AdjustableDPI.swift`, and the Devices card from the saved source.
