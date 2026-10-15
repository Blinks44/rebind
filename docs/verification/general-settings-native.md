# General settings: native implementation and verification

Routine capture files were moved to ignored local storage during repository cleanup on 2026-10-11. The dated observations, commands and acceptance limits below are preserved; these images are not automated test baselines.

Updated 2026-10-11. **Full-main-window correction:** the later reported overflow was reproduced and repaired; current repair/artifact evidence supersedes the initial layout acceptance below. Scope: [UI-003](../tasks/UI-003-general-settings.md), SPEC §§6, 8, 10–11 / S1. General is implemented; actual login/relaunch, native assistive-technology and minimum-OS acceptance remain open.

## Implementation and source

Started from `main` / `acce2f4` with existing uncommitted permission/trackpad/design work. During implementation an external commit advanced HEAD to `b453d8d` and included the first General implementation. Final layout/accessibility/test/documentation refinements remain uncommitted. No agent Git commit, Sketch edit/save, real login registration, permission change, user-configuration write or configured remapping was performed.

Live `Rebind.sketch` General Light and approval frames, hierarchy and Light/Dark row styles were refreshed through MCP on 2026-10-11: Sketch 2026.3.1 / API 2.0.0, document `E50CA3D9-82B1-44C0-AC97-39F1A9663700`. The historical design review is summarized in the [design delivery](../history/settings-design-through-2026-10-11.md#general). Independent Language design work is preserved.

- `SettingsView` serves main-window Settings and the existing Settings scene with the same delegate-owned `AppModel`. General and Permissions are the available sections. Future Input/Language/Advanced controls are omitted until implemented. Permission recovery goes directly to Permissions; opening main Settings selects General.
- `GeneralSettingsView` reuses persisted enabled state, immediate safe pause, existing cards/canvas and window/Menu Bar lifecycle. Runtime presentation distinguishes active, intentional pause, starting, missing access, capture failure, Secure Input, session suspension and storage lock. Refreshed actual grants take precedence over a stale permission-required worker status.
- `SystemLoginItemService` uses public `SMAppService.mainApp` registration/status, async unregister and the public Login Items route. There is no JSON login boolean, helper, launch-agent plist, package or settings mutation during refresh. Focus/appearance and Check Again reread OS state.
- `LoginItemModel` serializes explicit operations. It rereads status after success or failure, preserves approval as distinct from enabled, maps not-found/unknown to unavailable and prevents overlap. Retries are explicit. Busy login removal does not block global pause. Native calls do not alter profiles, rules, enabled intent or the engine.
- Capture retry changes only the mailbox retry generation when capture has failed and remapping remains enabled, allowed and unsuspended. It never resumes deliberate pause or changes persistence.
- All 25 General handoff keys are integrated exactly in EN/RU/DE/FR, plus two supplemental keys for failed approval cancellation and session suspension. Native semantic fonts, wrapping and scrolling retain desktop sizing; section chrome and runtime text are constrained to the viewport.

## Bounded differences and safety

The existing main sidebar/material hierarchy remains outside this slice. The available native segmented sections reuse macOS semantics rather than exposing inert future tabs. The main-window minimum remains 880 × 600; the separate Settings scene retains its 600 × 480 minimum. Fixtures also check the 648 pt detail width of the compact main window.

The earlier design wording about rollback after all failed storage changes conflicts with the existing emergency-pause safety contract. Resume failure retains prior paused state. Explicit pause cancels pending output immediately and stays paused in memory even if disk save fails, with the existing localized save error; it must not restart input to restore a stale disk preference. The old stored preference can survive a failed write, so durable pause after relaunch is not claimed in this failure case. Suppressed source releases remain owned until released. No schema change is needed.

## Initial integration checks (before full-main-window correction)

Environment: Apple Silicon, macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Swift 6.4, SDK 27; project deployment target macOS 26 and Swift 6 strict concurrency unchanged. Xcode MCP was not available. Sandbox-only compilation failed because Swift macro plugin execution was denied; the same project commands succeeded through approved Xcode execution outside the sandbox. No system-wide toolchain setting changed.

- `apps/rebind/scripts/dev.sh doctor`: passed; actual environment and deployment settings inspected.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/GeneralSettingsAccepted.xcresult`: **529 Swift Testing cases / 71 suites plus two native XCTest cases, 531 total / zero failures**; `TEST SUCCEEDED`.
- Debug test build and `apps/rebind/scripts/dev.sh release`: succeeded. Release contains `arm64` and `x86_64`; both app signatures pass `codesign --verify --deep --strict`.
- Initial executable SHA-256 (superseded by repair artifacts): Debug `636746db845757bef088d112342bae7020369e10120c21fc2d3197d9108b9297`; Release `ab5ab681e36fe44de0c9cbc1b561005bcc07a2e51f354d6f84f6d563390420e6`.
- Build/result bundles and raw logs remain ignored/local; curated fixtures and this evidence are versioned. Catalog check confirms all 25 handoff keys match in four languages, with the two supplemental keys complete. Affected links and `git diff --check` pass.

Behavioral coverage includes actual-status success/error reconciliation, approval cancellation, not-found, external OS changes, explicit retries, overlapping operations, login/pause independence, unchanged configuration bytes/profile/rules, storage failure and suppressed-release symmetry. Tests inject a login service and permission/session state; they do not prove native ServiceManagement registration or hardware output.

`GeneralSettingsLayoutTests` checks **264 combinations**: 11 states × four languages × Light/Dark × 600 × 480 / 648 × 600 / 808 × 640. It checks viewport/scroll bounds and document width. States include ordinary enabled/paused, approval, enable/removal/approval-removal failure, unavailable, missing access, engine failure, Secure Input and busy removal. The existing main-window test separately covers 72 locale/grant/rule/size combinations. Models never start capture or load user data.

AppKit `cacheDisplay` attachments sometimes omit left text edges despite passing geometry, including visible-window variants. Those partial snapshots are excluded from visual acceptance. An isolated, visible test window was inspected directly through native UI tools: the French missing-access status and all controls render completely, and General → Permissions → General navigation works. Temporary inspection helpers were removed. Representative complete fixture states are listed below; inactive native switches may be gray while still exposing the correct on/off values. Fixture screenshots are not OS-grant/login evidence.

Reviewed final fixtures: active / English Light, paused / Russian Dark, approval / compact Russian Dark, removal failure / German Light, busy / French Dark. Compact approval is a scroll viewport; lower guidance continues below it.

## Accessibility review

**P1 finding fixed:** AppKit's accessible representation of a multiline SwiftUI Toggle label exposed only its description. Explicit localized accessible titles/hints now retain “Enable remapping” and “Launch at login”; the final French native AX tree exposes both titles, descriptions and correct on/off values. The redundant spinner announcement is hidden because adjacent progress text already provides the state. Headers, native buttons and segmented controls retain their roles. This tree inspection is not a spoken VoiceOver session or a complete keyboard audit.

Regression focus: multiline labels, permission recovery routes, compact scrolling, state changes while a login operation is pending, and preservation of emergency pause. No blocking P0 was demonstrated in the inspected isolated window; full accessibility acceptance remains pending.

## Remaining acceptance and next action

On an explicitly identified bundle, with user-controlled login/permission changes:

1. Enable launch at login, confirm actual Login Items state, disable it and confirm removal. If approval is required, Open Login Items must not itself mark approval; return/Check Again must display the actual OS state.
2. Change the item externally and return to Rebind. Verify refreshed state without automatic registration/retry, including deliberately paused remapping.
3. Relaunch and perform a real login while paused and while enabled with missing access. Profile/rules/pause must restore; input must start only when enabled and allowed. Stable signing/TCC and different app copies remain separate checks.
4. Close/reopen the main window through Menu Bar; use main/standard/Menu Bar Settings routes and both sections. Verify one engine/model and emergency pause. Quit remains distinct from closing a window.
5. Use keyboard only and VoiceOver: section selection, named toggles with values/hints, recovery actions, compact scrolling and focus after navigation. Verify Light/Dark, Reduce Transparency/Motion and Increase Contrast in all four locales. Native AX title inspection passed; spoken output and focus restoration remain open.
6. Verify macOS 26 and Intel execution before claiming either supported runtime. Universal compilation is not execution evidence.

Current continuation: verify General actual login/lifecycle/accessibility on an identified bundle. Input/Language/Advanced and whole-app soft styling are already integrated; use [STATE](../STATE.md) for independent work. General remains `awaiting_verification` until its required actual login/lifecycle/accessibility checks are recorded.
