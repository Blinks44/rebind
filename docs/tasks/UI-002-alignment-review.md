# UI-002 — consistent alignment across Sketch screens

- Updated: 2026-10-10.
- Stage: `done`; bounded Sketch alignment repair saved and verified.
- Owner: Unassigned; `/root` saved and released the design repair on 2026-10-10.
- Ownership checked: current `main` / `acce2f4`, existing UI-001 delivery preserved; no implementation ownership claimed.
- Owned surfaces: existing 22 frames on 01 · Screens and their affected local layout components, this task/evidence, DESIGN and STATE summary. Brand geometry, Apple library sources, app code and copy remain outside the repair.
- Requirements: SPEC §10 alignment, sizing and Light/Dark; PLAN Phase 8.
- Code baseline: `acce2f4`; previous permission-recovery design records are uncommitted.

## Outcome and scope

Review the live Rebind Sketch screens following repeated alignment issues. Correct shared centers, columns, spacing and responsive anchors while preserving content, materials, live Symbols and prototype routes.

## Acceptance

- [x] Review all 22 current screen frames and relevant repeated components through MCP.
- [x] Repair identified alignment defects and visually verify affected variants.
- [x] Check representative window-size changes and restoration without geometry drift.
- [x] Save the editable document; retain revision and scoped evidence, update affected handoffs and STATE.

## Verification and next step

Twelve desktop frames repaired: brand/status centers, search/profile controls, compact columns, Settings spacing and edge/intrinsic sizing. All 22 frames reviewed, twelve exports refreshed, expanded Light/Dark/compact/DE views checked and final three-frame roundtrip restores all 553 screen-node frames exactly. All 1,470 original local nodes retained, 24 layout groups added; copy/overrides/prototype routes and Brand preserved.

[Verification](../verification/alignment-review.md) owns exact findings, scope and checks. Saved revision SHA-256 `50859f5bfbe9d4bc031431e526ca03f65a3af3fd29e6e554cd867484c28a6f58`; document ID `0D40E26C-3A14-42D3-9DBA-D9DC6DFAB6D4`, resolve again before work. No app build/runtime acceptance or Git commit for this design-only repair.

Next: implement the prepared first-run and permissions design from UI-001, preserving these sizing contracts. Independent design can continue Settings → General. Native accessibility, RU/FR and runtime sizing remain open in UI-001.
