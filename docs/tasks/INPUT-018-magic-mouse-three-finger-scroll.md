# INPUT-018: Magic Mouse three-finger vertical scrolling

- Updated: 2026-11-10
- Stage: awaiting_verification
- Owner: unassigned; implementation ownership released
- Ownership checked: `main` at `832ea6e`, preserving the uncommitted INPUT-017 changes from this chat
- Owned surfaces: Magic Mouse native scroll admission, trigger/model/schema, preset/copy, focused tests and related records
- Requirements: SPEC §3.5, G1/G2
- Code baseline: `832ea6e` plus INPUT-017 and this uncommitted change set

## Outcome and mechanism

Add “Scroll up · 3 fingers” and “Scroll down · 3 fingers” to the existing scroll group after its two-finger entries, making eleven Experimental presets. Exact fresh contact count at a source-attributed vertical Began selects the rule. Two- and three-finger rules remain distinct; unassigned/ambiguous starts pass through for the whole stream. A recognized stroke queues one action and retains ownership of its tail/momentum after contacts, modifiers, rules or admission change. Existing Natural Scrolling direction conversion, arming, freshness, revision, queue, permission, protected-context and source gates remain.

Reuse the already audited acquisition/phased-scroll mechanism from [INPUT-015](INPUT-015-touch-release-scope.md#requested-physical-click-and-scroll--2026-10-19). No new API, recognizer, package, copied third-party implementation or license decision. Three-contact observation is already used by the physical-click path. This software extension does not prove that every Magic Mouse/OS emits an attributable three-contact vertical Began; missing metadata remains native. Physical delivery is tester-accepted; the specific passthrough/safety/settings matrix remains open.

Keep the existing Codable `magicMouseScroll(direction)` case unchanged for two fingers. A separate `magicMouseThreeFingerScroll(direction)` case requires schema 52; old rules migrate without changing their identities. Six-language titles and count-specific help reuse existing terminology. No visual control changes; live Sketch screen-58 menu structure re-inspected, source unchanged. Synchronize its catalog and Foundations in a future authorized design pass.

## Acceptance

- [x] Exact-count matching, no fallback/midstream takeover, once-only delivery and momentum ownership pass software tests.
- [x] Persistence round trip/schema protection and existing two-finger rule migration pass.
- [x] Eleven presets fit the six-language/two-theme native editor matrix; format/lint/build pass.
- [x] Signed 1.3.2 (49) app/DMG and image verification pass.
- [x] Both new directions deliver on a real Magic Mouse: tester reports excellent operation on 2026-11-10 after the build-49 handoff.
- [ ] Specific unmatched/ambiguous scrolling, both Natural Scrolling settings and interruption/reconnect edge checks; general success does not establish this matrix.

## Next handoff

Preserve accepted ordinary delivery of all eleven Magic Mouse presets; do not request another general delivery pass. Only the named passthrough/settings/safety checks above remain. Trackpad post-keyboard investigation stays in [INPUT-019](INPUT-019-trackpad-coexistence-and-typing.md).

## Verification — 2026-11-10

Apple silicon, macOS 27.2 / Xcode 27.1, baseline and preserved changes above. `dev.sh format` and `dev.sh lint` pass. Focused run passes **59 Swift Testing methods in eight suites plus two native XCTest editor/layout methods**, including eleven presets × six languages × Light/Dark × two heights. Tests cover both counts/directions, exact-count admission without fallback or midstream takeover, once-only action delivery, tail/momentum ownership through admission loss, migration/round trip/schema rejection, unchanged two-finger rules and backup/store protection. These are injected software/native-layout fixtures, not hardware action acceptance. No full-suite run claimed.

Final `dev.sh build` passes at **1.3.2 (49)** / schema **52**. `release.sh` passes app/DMG signing and image verification with the existing identity. Current deliverable: `apps/rebind/build/release/Rebind.dmg`, SHA-256 `d255a06e930189c99ef04ffa2ec41c0dfdbba7c7a3cba1df2ddbd3c15494dac2`. Package version/build inspected directly. No real configuration/permission changes, installation, publication or Sketch save. Source review confirms the two group boundaries still precede the first physical click and first scroll; all four scroll entries remain together. `git diff --check` and affected document-link review pass. Subsequent hardware delivery acceptance is recorded below.

## Physical acceptance — 2026-11-10

The tester confirms three-finger scrolling works very well on Magic Mouse after the 1.3.2 (49) handoff. Both new directions are accepted for ordinary operation, completing basic delivery acceptance of the eleven-preset pool. Exact running artifact/model/OS/settings were not independently inspected or restated. This adds no specific unmatched-input, Natural Scrolling, interruption, reconnect, multi-mouse, accessibility or platform evidence; retain those checks. No source, tests, package, permissions or real rules changed for this report.
