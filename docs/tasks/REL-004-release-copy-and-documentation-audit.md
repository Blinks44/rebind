# REL-004: Pre-release product, copy and documentation audit

- Updated: 2026-10-21
- Stage: awaiting_verification
- Owner: Unassigned; local audit complete, candidate/runtime/publication review pending
- Baseline: main e070ec9 plus preserved uncommitted touch/UI/update/signing work
- Owned surfaces: six-language string catalog and website messages/configuration, English Sketch copy/notes, public documentation, release guide and affected project records
- Requirements: user-requested final feature-gap review, ordinary-user wording in all six languages, current instructions/README/website and actionable GitHub DMG release plan; SPEC §§3–11, 13, 15–16

## Outcome and boundaries

Audit implemented functionality before recommending additional scope. Repair misleading or unclear copy, stale release/support claims and broken public links. Keep native input behavior and the accepted preset pool stable unless a concrete critical defect requires a separate fix. Review live English Sketch and preserve reusable components/layout. Prepare release instructions and notes locally; no Git commit/tag/push, installation, permission/rule changes, GitHub publication or website deployment is authorized by this audit.

## Required checks

Read all six catalog/website locales, inspect placeholder/plural parity and call-site meaning, build the app and website after edits, run affected localization/layout tests, inspect changed Sketch frames through MCP and save explicitly. Verify GitHub release instructions against current official documentation. Preserve the user's successful general manual report; changes invalidate only affected copy/layout evidence. Fluent-reader and untested hardware/platform claims must retain their limits.

## Feature-gap decision

Inspected current trigger/action, configuration/profile, Settings and update implementations. Compared the intended small remapper with current primary references for [BetterTouchTool shortcuts](https://docs.folivora.ai/docs/keyboard-shortcuts/overview/) and [Karabiner-Elements](https://karabiner-elements.pqrs.org/docs/), accessed October 20. These references inform candidate ideas; they do not establish a user requirement or Rebind support. No dependency or capture mechanism was added.

| Need | Current result / release decision |
| --- | --- |
| Stop/recover safely | Menu/window pause, emergency pause, permission recovery, lifecycle release and protected storage already exist. Retain detailed runtime limits; no new input feature needed. |
| Tailor input to apps/tasks | Per-app rules, exclusions, manual profiles, search, duplication and notes already exist. No automatic profile expansion. |
| Protect settings and troubleshoot | Full/profile export/import, startup backups and private-content-free support report already exist. Added a user guide and clearer bug/support instructions instead of another diagnostics system. |
| Discover a new version | Manual GitHub checker exists. Website repository/download wiring fixed. Automatic updater needs a separate feed/signature/install/lifecycle design and is not required for the first release. |
| Easier first bindings | Optional starter presets could help after release. Examples now match actual conflict/gesture rules; automatic rule creation is not added. |
| Undo window placement | Useful post-release candidate, but needs per-window history/lifecycle/display policy and separate acceptance. Existing halves/quarters/center/fill are sufficient for the current release. |
| More gestures/macros | No critical gap demonstrated. Keep 12 presets per trackpad category and six Experimental mouse presets. Avoid another recognizer or automation platform before release. |

## Copy and documentation outcome

- Read all 644 translatable entries in Localizable, four Navigation entries and four InfoPlist entries (brand/identity values intentionally do not translate), plus all six website catalogs (178 messages each). Reviewed variable/plural forms and context in code/live English Sketch. Completeness and argument-type checks pass; plural categories preserve language-specific differences.
- Revised 104 app catalog values: natural tap/click/scroll guidance, complete six-preset mouse wording, shorter companion-app recovery, unambiguous backup/privacy language, About scope, consistent formal German/Russian address, clearer German wheel terms and consistent Chinese preset labels. Russian Bluetooth permission purpose is also clarified. No matching, action or storage logic changed.
- Website now uses Blinks44/rebind, correct supported mouse examples and distinct F13/F14/F15 activation examples. Removed nonexistent swipes, immediate/every-app guarantees, untested universal Intel claim, daily/seven-day backups and zero-network implication. Added a GitHub footer link and required explicit User-Agent to release metadata requests. No release means Download remains disabled.
- README, CHANGELOG, SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, bug template, website README, DEVELOPMENT/SIGNING and current state/plan/design/research records reconciled. Added USAGE, RELEASING and draft 1.0.0 release notes. Private vulnerability reporting availability is a maintainer check, not assumed enabled. Historical test reports remain historical.
- AGENTS/WORKFLOW/ENGINEERING and relevant skill instructions reviewed; existing native/callback/localization/security boundaries still apply. No workflow framework, dependency, new skill or instruction migration needed. STATE/PLAN condensed while retaining task owners, evidence links and all open checks.

## Saved Sketch

English source reviewed through live MCP, including screen text and nested text overrides. Scoped changes: setup privacy, Advanced backup scope/retention, About, companion-app advice, mouse Experimental guidance in screens 54/55/58/59/60, and obsolete Foundations 07–09 next steps. Light/Dark contexts screenshot-reviewed. Shortened companion advice after screenshot showed the longer text too close to the warning edge; final text fits. Existing six-choice menu, components, brand and geometry preserved. Saved Rebind.sketch SHA-256: `039b3def609a8aeed54ea2cbc96da56de20b24541acddfecb67f86efc4b2467a`. Saved ZIP readback finds zero stale daily-backup/two-preset descriptions on current pages. No exports versioned.

## Verification

- Debug build succeeds after granting normal Xcode cache access; first sandboxed attempt could not write module/package caches (not a source error).
- Existing affected test slice: **19 Swift Testing methods / four suites and 20 native XCTest methods**, zero failures/skips. Covers language resolution/catalog/update feedback and all-six-language Light/Dark main/editor/Settings/device/About geometry. Result: Test-rebind-2026.10.20_11-11-03-+0300.xcresult in isolated copy-audit DerivedData.
- After shortening companion advice and setting 1.0.0 (2), final affected rerun: **one Swift Testing method and seven native XCTest methods**, zero failures/skips; subset of earlier scope, not additive unique coverage. Result: Test-rebind-2026.10.20_11-19-14-+0300.xcresult. Russian InfoPlist purpose compiled with this build. Earlier 903 engine methods remain dated REL-003 evidence; input logic was unchanged here.
- Website `pnpm build` (Rsbuild client/Worker + TypeScript) succeeds. First sandboxed package-manager identity check lacked registry network access; rerun retained signature verification and succeeded. Local Wrangler serves all six locale routes with HTTP 200; parsed SSR checks confirm localized hero/FAQ/backup content, GitHub link, canonical metadata and no-release fallback. Catalog key/placeholder parity passes. No dependency/lockfile change.
- Browser visual/hydration/mobile walkthrough remains unverified: no browser tab connector was available, and automatic approval review rejected attaching to the existing Chrome session because unrelated private tabs might be exposed. No workaround, private-tab access or browser settings change. Local HTTP/SSR checks completed safely instead.
- Release/signature/integrity and final artifact evidence are recorded below. No real rules/permissions, output actions, installed-app replacement, Git commit/tag/push, GitHub publication or website deployment.

## Remaining acceptance / next handoff

Preserve the user's successful general manual report. Next: export configuration, replace the previous stable-signed candidate with the new distinct candidate and verify saved rules plus actual Accessibility access. A short affected copy/layout smoke pass suffices; do not repeat the accepted basic gesture inventory. Minimum macOS 26, full normal-build VoiceOver/preferences, fluent-reader proofreading, detailed device matrices and measured granted-profile CPU/callback/action latency remain separately limited in PLAN/tasks. The app/site copy audit is not native-speaker certification.

Before public release, review/commit the intended source, align the tag with the rebuilt tested DMG, close or disclose remaining gates, attach DMG/checksums to a GitHub draft, verify downloads and update behavior, then review/deploy the website. Instructions and prepared notes are linked from RELEASING. No additional input feature is a prerequisite identified by this audit.

## Final local candidate — 2026-10-20

Version/build **1.0.0 (2)** in both app configurations; bundle identifier and signing identity unchanged. Source is main e070ec9 plus the preserved uncommitted app work and this copy/version/site/docs audit. Explicit final non-quiet Release build ends BUILD SUCCEEDED with no error diagnostics; final release.sh signs/packages successfully. An earlier quiet build repeated Xcode’s zero-exit/no-further-output diagnostic; it was followed by the explicit build and clean final packaging. Existing CompanionApp String(cString:) and create-dmg/hdiutil deprecation warnings remain; no unrelated API refactor.

Final app strict/deep signature, DMG signature and hdiutil integrity pass. The additional sandboxed codesign verification could not establish trust for the self-signed certificate; the standard host/keychain-context rerun passes without changing trust. Packaged Info.plist and localized strings readback confirm the new version and final wording.

Artifact: apps/rebind/build/release/Rebind-1.0.0-2.dmg. SHA-256 `600bb69984f6b644da17305c225d01bcfd213ffa2f60da343862ea53c18c5917`. SHA256SUMS.txt beside it verifies successfully. Earlier intermediate 1.0.0/2 package hashes are superseded; do not publish them. The previous 1.0/1 DMG remains intact with hash ee033c3f76247c8a929a11057694a95065ddb65c07f4ff93b451bb52909adccb.

Read-only installed-bundle inspection now confirms /Applications contains **1.0 (1)** with the same Rebind Release designated requirement as the new package. This supersedes the earlier signer-transition assumption; it does not itself prove an installed update preserves the actual grant. The agent did not replace/restart that app or inspect real rules.

Final website build/type check also passes after the last Chinese metadata refinement. Public unauthenticated recheck: repository 200/public, latest release 404. The local preview was stopped after successful SSR checks. Documentation links, affected facts/anchors and git diff --check pass. No code commit, tag, push, installation or publication; ownership released awaiting the scoped runtime/distribution handoff.


## Current signing candidate handoff — 2026-10-20

User subsequently authorizes signing/release alignment with Monny. [REL-001](REL-001-signing-workflow.md#unified-default-pipeline-verified--2026-10-20) owns build 1.0.0 (3), the shared Apple Development signer and installed/running check. This supersedes build 2 as the current candidate without invalidating the dated copy/layout tests above. Old self-signed build 1/2 → new development-signed build 3 is a signer transition; it cannot close the old same-signer update gate. Accessibility/window/input smoke and two subsequent development-signed update builds remain. No publication.

Before any website publication, reconcile the undeployed six-language installation FAQ with the newer Apple Development test-candidate signing route; its earlier self-signed wording predates REL-001 alignment. Website publishing remains outside this signing task.


## Final copy pass — 2026-10-21

Second full read of the six-language catalog and website before release; fixes and evidence are in [history](../history/2026-10.md#2026-10-21-final-pre-release-review). English/Sketch copy unchanged. Remaining: visual check of the changed Russian/German strings at minimum width in build 11.
