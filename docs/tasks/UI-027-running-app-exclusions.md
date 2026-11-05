# UI-027: Add exclusions from running apps

- Updated: 2026-11-06
- Stage: awaiting_verification
- Owner: Unassigned; implementation ownership released after this handoff
- Ownership checked: main `fbc4454`; existing ACTION-002 documentation changes preserved; scoped ownership released
- Owned surfaces: ExcludedApplicationsCard, new running-app menu/catalog, related tests, string catalog, build number; scoped SPEC/STATE/CAPABILITIES/history updates
- Requirements: SPEC §§3.2, 10; existing exclusion semantics and storage

## Outcome and scope

Add App opens a native menu of running foreground-capable apps, including VM launchers outside Applications, plus a file-picker action. Refresh on opening, deduplicate by bundle ID and omit Rebind/already excluded/invalid/background-only apps. Keep the existing per-feature switches and identifier-based matching. No polling, new permissions or engine changes. VM exclusions apply to the selected VM identity, not all VMs of its manager.

## Acceptance

- [x] Native running-app menu and file picker implemented; generated-VM identity, duplicates/self filtering covered by software tests. Installed VM selection remains below.
- [x] Bundle name used for menu/saved rows; generated VM.app fixture round-trip passes without a running process.
- [x] Focused tests, formatting/lint, Debug test build and signed Release DMG packaging.
- [ ] Installed selection, persistence/relaunch, real VM scrolling and keyboard/VoiceOver checked separately.

## Sketch source

2026-11-06: live Rebind.sketch General Light/Dark inspected through MCP (frame 31). Reuse existing Add App capsule and native anchored-menu implementation; no Sketch edits. New menu interaction is authorized by the user; design synchronization remains a scoped follow-up.

## Implementation and verification

Code baseline: main `fbc4454`, uncommitted `UI/RunningApplicationMenu.swift`, `UI/RunningApplicationChoice.swift`, `UI/ApplicationTarget+ExclusionDisplayName.swift`, `UI/ExcludedApplicationsCard.swift`, `UI/RunningApplicationMenuTests.swift` (test target), string catalog and both build settings. Existing configuration schema 49 and matching engine are unchanged. Build **1.3.2 (44)**.

Use public [NSRunningApplication / NSWorkspace](https://developer.apple.com/documentation/appkit/nsrunningapplication) APIs on the main actor and the existing AnchoredMenu; no dependency required. Read the running list only when opening the menu. Keep that menu's target snapshot through selection, even if processes exit. Bundle CFBundleName identifies generated VM.app bundles after saving; the filename is the fallback if unavailable. A deleted/moved generated VM bundle can lose that display name, while identifier matching remains unchanged.

2026-11-06, Apple silicon/macOS 27.2:

- `dev.sh format` and `dev.sh lint`: pass.
- `dev.sh test` selecting RunningApplicationMenuTests, ExcludedApplicationTests, ExclusionTogglesAndSmoothScrollingTests and GeneralSettingsLayoutTests: **15 Swift Testing tests plus one XCTest layout test pass**, no failures. Covers generated VM identity/exclusion set, name encode/decode, filtering/sorting and existing per-feature/pointer exclusion behavior. General's existing six-language/Light-Dark/width/state matrix passes.
- Follow-up `dev.sh test -only-testing:rebindTests/RunningApplicationMenuTests`: **4 pass**, including the new six-language/Light-Dark 600 pt exclusion-card layout fixture. Twelve local PNG attachments; RU Light, EN Dark and DE Light reviewed: caption, button/chevron, app row and columns fit. Offscreen fixtures do not establish installed popup tracking or VoiceOver behavior.
- `release.sh`: Release build, existing signer, strict app and DMG signature checks, image verification and Sparkle appcast generation succeed. Package: `apps/rebind/build/release/Rebind.dmg` (identical preserved copy: `apps/rebind/build/release/Rebind-1.3.2-44.dmg`); SHA-256 `6f0fa368d4570b15b40b637f18af184aa35199a75e9b136b77744e91a68c4ca5`. Signed, not notarized; not installed or published.
- `git diff --check` and affected local-link review pass. Existing ACTION-002 edits preserved. Source review keeps native button/menu keyboard tracking and focus restoration, hides decorative chevron from accessibility, and retains limit/storage-disabled gating and translated labels. No input callbacks changed.

Read-only inspection of the installed VMPal bundle and generated VM launcher establishes distinct manager/VM IDs and a VM CFBundleName. By the later NSWorkspace probe, only the manager was running; live VM menu selection and scrolling are not agent-verified. No real rules/permissions/VM state were changed.

Integration: build 44 contains schema 49 and the exclusion work verified above; its preserved DMG remains historical evidence. [ACTION-002](ACTION-002-centered-fill.md) subsequently packages both tasks together in 1.3.2 (46), schema 50, with signed app/DMG/image checks and separate action/persistence evidence. The exclusion-specific tests above were not rerun for build 46; installed VM/menu checks remain open. Both tasks are included in the user-authorized combined commit.

## Next handoff

Install the current build 46 manually, start a VM, then use General → Excluded Apps → Add App to select the VM by name. Verify the saved row after relaunch, smoothing off over its window and smoothing elsewhere, disk-picker fallback, menu cancellation and keyboard/VoiceOver navigation. Design: synchronize only the new native-menu interaction/copy with General frame 31 when design work is next authorized.
