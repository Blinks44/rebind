# UI-004: Input settings and per-binding hold timing

- Updated: 2026-10-16 (documentation reconciliation)
- Stage: awaiting_verification
- Owner: Unassigned; implementation released
- Requirements: SPEC §§2–4, 10–11
- Code baseline: initial native slice `b453d8d`; material/copy adoption included in `2bc4b97`; integrated in `1a0801b`. No app changes/checks in this cleanup.

## Current outcome

Input settings and the per-binding hold-duration editor are implemented using existing engine/storage constraints. Later pointer-distance, wheel/exclusion and per-mouse smooth-scrolling changes belong to [INPUT-009](INPUT-009-held-output-exclusions-catalog.md), [INPUT-010](INPUT-010-smooth-scrolling.md) and [INPUT-011](INPUT-011-apps-mice-gesture-button.md). The current touch pool/actions follow SPEC §3.4; old four-preset shortcut-only guidance is superseded.

No global hold/double-press override was introduced by this task. Current visual source is [DESIGN](../DESIGN.md); the [historical Input handoff](../history/settings-design-through-2026-10-11.md#input) preserves its original design checks, not current geometry.

## Acceptance and verification

- [x] Per-binding duration, save failure/draft retention/retry and shared native UI integration.
- [x] Software/layout checks and scoped live native save/retry review.
- [ ] Actual keyboard/mouse Hold timing and cancellation.
- [ ] Complete keyboard/focus/VoiceOver, six-language error/editor layouts and accessibility preferences.
- [ ] macOS 26; Intel only if claimed.

[Native evidence](../verification/input-language-native.md) owns commands/artifacts: 539 Swift Testing + five XCTest cases (544 total), zero failures; 352 full Settings combinations plus standard/failure/editor checks. Live French 575 → 675 ms, write failure/retained draft/retry/readback and Russian Dark/compact navigation were checked. The 2026-10-12 material/copy slice passed 20 functions / 74 executions, 608 native viewports, Debug/signature and scoped English/German review. These results do not prove physical timing.

## Next handoff

Verify physical Hold timing/cancellation and full native accessibility on a named current bundle. Reuse the integrated Settings/editor and full-main layout coverage; route new Input/Devices behavior to its own feature task.
