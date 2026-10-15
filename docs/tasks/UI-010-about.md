# UI-010: About Rebind and bundled licenses

- Updated: 2026-10-16 (documentation reconciliation; dated checks unchanged).
- Stage: `awaiting_verification`; native implementation and scoped software checks pass.
- Owner: Unassigned; `/root` implementation released the bounded scope, 2026-10-11.
- Ownership checked: `main` / `bf36465`; UI-007 released, UI-009 design remains independent.
- Owned surfaces: new About/bundle information/license views and tests, ContentView sidebar and rebindApp About scene/command, new About catalog keys; scoped task/index/evidence updates. Existing Advanced changes preserved. Sketch read-only.
- Requirements: SPEC §§10–11; PLAN Phases 7–9.
- Code baseline: started on `main` / `bf36465`; external HEAD advanced to `8daa97b` with previous Advanced changes. About remains uncommitted; no agent commit. Independent Mouse release preserved.

## Outcome and scope

Make About available beside Settings and from the application menu, using the released Sketch composition, the shipped icon, actual bundle version/build, a short description and credits. Provide readable/selectable bundled third-party notices locally. No invented website/update link, new dependency, capture/action/persistence change or Sketch edit.

## Acceptance

- [x] Inspect live About frame and reuse existing icon/materials/native controls.
- [x] About navigation, bundle information and bundled license access work in EN/RU/DE/FR; Done/Escape close safely.
- [x] Native compact/Light/Dark/localized layout, read-only license semantics, relevant tests and Debug build checked.
- [ ] Complete VoiceOver, full keyboard traversal and accessibility-preference acceptance.
- [x] Record remaining VoiceOver/platform gates and update task/evidence/STATE before handoff.

## Sketch source

Rebind.sketch, read live 2026-10-11: `07 · About / Rebind`, `FCD17D45-D89C-44AF-842A-2095BFB50986`. Compact centered identity/description/credits, Licenses and Done inspected through MCP tree/text/screenshot. No external links in the released source. The license document uses native AppKit text semantics; additional About design variants remain independent.

## Implementation and verification

Read [native evidence and final identified artifact](../verification/about-native.md). About is available from both sidebar and application menu; it uses actual bundle metadata/icon and complete local notices, with native Find and safe closing. All four languages are implemented and software-sized; live menu/sidebar/Light/Dark/search/closing checks used Russian in an identity-isolated empty/paused test host. Full suite: 574 tests / zero failures before the final Find deferral; four targeted native/resource tests and Debug/signature checks pass on the final source. Update-cycle repair verified without new cycles; an internal test-host QoS warning remains documented. Temporary interaction fixture removed.

Source review found no new P0/P1 accessibility blocker; native labels/headings and read-only document semantics are retained. VoiceOver/complete Tab traversal/accessibility preferences and macOS 26/Intel execution remain open. No user configuration, grants, login registration, capture or remapping changed. Sketch remained read-only, including a final recheck after Mouse's new saved document ID.

## Next

Verify About/Licenses VoiceOver reading/selection/Find and complete keyboard/accessibility-preference checks from the evidence checklist. Mouse list/editor and whole-app styling are already integrated; select independent work from STATE. Advanced restored-binding acceptance remains separate.
