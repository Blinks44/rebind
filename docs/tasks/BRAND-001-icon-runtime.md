# BRAND-001 — finish existing icon runtime acceptance

- Updated: 2026-10-10, fresh-resource comparison and scoped cache refresh completed; Dock runtime confirmation pending.
- Stage: `awaiting_verification`
- Owner: Unassigned; last artifact/cache check by `/root`. No geometry or Sketch edits.
- Owned surfaces when claimed: brand runtime evidence/this task; coordinate any new Sketch/Composer/asset changes.
- Requirements: SPEC §10 Application icon/Menu Bar icon; PLAN Phase 8.
- Baseline inspected: `6c1a5be`, `rebind/AppIcon.icon` and named `RebindMenuBar` template exist.

## Outcome and existing delivery

Confirm the existing icon in real runtime contexts. Do not recreate it because acceptance is incomplete. Sketch owns refined vector geometry; Composer owns the app delivery materials/mask/appearances. Menu Bar uses its own monochrome template. [DESIGN source index](../DESIGN.md#brand-existing-source-and-delivered-assets), [brand README](../../assets/brand/README.md).

## Acceptance

- [x] Native AppIcon.icon is the sole app-icon input; superseded PNG sets removed, fresh Debug/Release/artifact checks pass. Prior generated appearances/small-size and Finder evidence retained. [Composer evidence](../verification/app-icon-composer.md).
- [x] Separate vector Menu Bar template integrated; prior Debug/Release AppKit checks load at 18 pt with template rendering. [Evidence](../verification/menu-bar-onboarding.md).
- [ ] Dock uses the delivered icon after normal user relaunch; live menu icon is clear in Light/Dark/selection states.
- [ ] Check actual user tint and high-contrast/transparency settings where relevant; record results and any limitation.
- [ ] Confirm macOS 26 runtime appearances when available. Development-host/native generation-26 exports do not prove minimum-OS execution.

## Cleanup delivery

The new package was already connected at baseline `6c1a5be`. Deleted the superseded app/reference PNG sets and verified matching brand/package SVGs, fresh builds, native ICNS artwork, bundle metadata and signing. [Detailed checks](../verification/app-icon-composer.md#sole-source-cleanup-and-fresh-artifact-verification--2026-10-10). No behavioral tests or app/input launch were needed for this asset-only change. Stage remains `awaiting_verification` for the runtime gates below.

## Next handoff

Latest stale-icon report prompted resource inspection: fresh Xcode/repository Debug copies contain identical native AppIcon.icns; another older DerivedData copy has different resources. Finder Get Info for the repository Debug bundle visibly shows the new Command mark. Touched and force-registered only the two fresh app bundles with LaunchServices, and restarted Dock once without clearing its preferences or removing DerivedData. [Evidence](../verification/app-icon-composer.md#stale-icon-report-and-scoped-refresh--2026-10-10). No Rebind/input launch by the agent; runtime result remains unconfirmed.

Have the user start one explicitly identified freshly rebuilt bundle and inspect Dock/live Menu Bar. Record that path/revision and appearance. If still stale, identify the exact icon/location and running bundle before any further cache operation. Minimum-OS/tint gates remain separate.
