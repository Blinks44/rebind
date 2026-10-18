# Manual checklist results: 2026-10-18

Recorded 2026-10-19 from the tester's marked `rebind-manual-test-2026-10-18.md`. This is a technical summary of supplied results, not an agent-observed run. The original checklist remains local; no raw output, configuration or personal paths are copied here.

## Artifact and evidence limits

Item 0.1 is checked: the installed app was quit and a fresh build launched with `apps/rebind/scripts/dev.sh run`, including the October 18 fixes. The exact revision/bundle, OS build, complete device inventory, permission state and native gesture settings were not supplied. The project previously recorded macOS 27.0.1, but this report does not independently establish it. The current documentation baseline is `main` `7aaea20`; do not treat that as the tested revision.

The checklist is dated October 18 but does not identify whether the tested bundle includes the October 19 shared-adapter follow-up. Its built-in trackpad passes are therefore not tied to that corrected artifact. [INPUT-014](../tasks/INPUT-014-magic-mouse-integration.md) separately records the later Magic Trackpad single-tap recovery and Magic Mouse action-delivery reports. Blank boxes remain unverified.

## Reported passes

| Checklist items | Reported outcome | Limits / owning record |
| --- | --- | --- |
| 0.1 | Fresh development build launched after quitting the installed app. | No exact tested revision. |
| 1.1–1.2 | With G HUB's window closed and its tray process running, Rebind shows the companion note and disables DPI changes; DPI no longer oscillates during app switching. After tray Quit, Rebind restores its DPI and enables the slider in approximately two seconds. | [DEVICE-005](../tasks/DEVICE-005-companion-dpi-reconnect.md); checked checklist expectation, not instrumented timing. |
| 1.3 | Mouse power-cycle/sleep-and-wake DPI check marked passed with G HUB absent. | No elapsed time or exact exercised route supplied; no quantified reconnect-latency claim. |
| 1.4 | Menu slider stays blue without a thumb focus ring on reopening; dragging changes DPI and agrees with Devices. | [DEVICE-004](../tasks/DEVICE-004-menu-pointer-speed.md); mouse model, Light/Dark, VoiceOver and localized widths not specified. |
| 2.1 | Activity Monitor idle CPU is near zero and energy impact low. | [REVIEW-002](../tasks/REVIEW-002-idle-energy.md); qualitative report, no sample duration or Release measurement. |
| 2.2–2.3 | Dual-role key (tap Esc / hold Control) works, including the first press after one quiet minute. Held arrow repeat is even and stops immediately on release. | [INPUT-009](../tasks/INPUT-009-held-output-exclusions-catalog.md); does not establish release on lock, sleep, pause or quit. |
| 2.5 | MX Master 2S gesture-button hold recognizes without a noticeable delay. | [INPUT-011](../tasks/INPUT-011-apps-mice-gesture-button.md); no measured timing or reconnect/quit-diversion acceptance. |
| 2.6 | Smooth-scrolling exclusion follows the background window under the pointer; other windows remain smooth and the start of scrolling is preserved. | [REVIEW-002](../tasks/REVIEW-002-idle-energy.md); broader multi-mouse/glide lifecycle remains open. |
| 3.1 | Built-in trackpad three-finger single and double taps run their rules. | [INPUT-013](../tasks/INPUT-013-trackpad-review-fixes.md); the item permits either working Look Up or an evident conflict, so it does not prove conflict-free coexistence. |
| 3.2 | Built-in two-finger double tap works; secondary click and Smart Zoom remain functional. | No native suppression claim; exact native settings and double-effect outcome not supplied. |
| 3.3 | Built-in physical three-finger click runs the rule instead of the ordinary click. | Item marked passed without a separate breakdown of resting-finger/dragging negative trials; four-finger and external-surface coverage not established. |
| 3.4 | Ordinary built-in trackpad scrolling, swipes and pinch remain functional. | Named ordinary-use subset, not the full safety/coexistence matrix. |
| 4.1 | Magic Mouse standalone probe item marked completed. | No output attached to this checklist. Existing raw/classified probe evidence remains in [INPUT-012](../tasks/INPUT-012-magic-mouse-probe.md); no new contact counts, gestures or app-support claim inferred. |

The introduction also says holds/modifiers, AirPods volume, per-app rules, gesture button, battery and Bluetooth access were already checked on October 15–16. This preserves that scoped earlier confirmation; it is not a new detailed walkthrough of every variant or lifecycle case.

## Still open

- **2.4:** first three-finger single and double tap after one quiet minute, on the current artifact.
- **4.2:** Magic Trackpad discovery, independent rules for built-in/external surfaces, and power-cycle recovery without restarting Rebind. Later single-tap recovery alone does not close this combined check.
- **5.1:** Insert Text with Russian text and emoji in TextEdit, Terminal and a browser field.
- **5.2:** keyboard traversal of the main window, editor and Settings, with visible focus and all controls reachable. VoiceOver and accessibility preferences are separate release gates.
- **5.3:** signed DMG build/install/update rehearsal, preserved rules and Accessibility grant. Certificate backup and packaging-tool installation are not evidenced.
- Return from the development build to the installed app: not marked completed.

Broader release gates remain in [PLAN](../PLAN.md): protected-context/lifecycle safety, latency, accessibility/localized widths, current brand artwork, macOS 26, and distribution. Next engineering slice: Insert Text acceptance and keyboard/focus review on an identified current bundle; fix reproduced defects. In parallel with available hardware, complete 2.4/4.2 and Magic Mouse safety/reconnect checks.
