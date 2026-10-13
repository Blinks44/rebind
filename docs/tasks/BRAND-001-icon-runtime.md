# BRAND-001 — finish existing icon runtime acceptance

- Updated: 2026-10-13, new keycap icon and menu bar template checked from fresh builds; live Dock/menu bar look still needs the user's eyes.
- Stage: `awaiting_verification`
- Owner: Unassigned; last artifact/cache check by `/root`. No geometry or Sketch edits.
- Owned surfaces when claimed: brand runtime evidence/this task; coordinate any new Sketch/Composer/asset changes.
- Requirements: SPEC §10 Application icon/Menu Bar icon; PLAN Phase 8.
- Baseline inspected: `6c1a5be`, `apps/rebind/rebind/AppIcon.icon` and named `RebindMenuBar` template exist.

## Outcome and existing delivery

Confirm the existing icon in real runtime contexts. Do not recreate it because acceptance is incomplete. Sketch owns refined vector geometry; Composer owns the app delivery materials/mask/appearances. Menu Bar uses its own monochrome template. [DESIGN source index](../DESIGN.md#brand-existing-source-and-delivered-assets), [brand README](../DESIGN.md#brand).

## Acceptance

- [x] Native AppIcon.icon is the sole app-icon input; superseded PNG sets removed, fresh Debug/Release/artifact checks pass. Prior generated appearances/small-size and Finder evidence retained. Composer evidence.
- [x] Separate vector Menu Bar template integrated; prior Debug/Release AppKit checks load at 18 pt with template rendering. Evidence.
- [ ] Dock uses the delivered icon after normal user relaunch; live menu icon is clear in Light/Dark/selection states.
- [ ] Check actual user tint and high-contrast/transparency settings where relevant; record results and any limitation.
- [ ] Confirm macOS 26 runtime appearances when available. Development-host/native generation-26 exports do not prove minimum-OS execution.

## Cleanup delivery

The new package was already connected at baseline `6c1a5be`. Deleted the superseded app/reference PNG sets and verified matching brand/package SVGs, fresh builds, native ICNS artwork, bundle metadata and signing. Detailed checks. No behavioral tests or app/input launch were needed for this asset-only change. Stage remains `awaiting_verification` for the runtime gates below.

## Fresh-build check — 2026-10-13

Agent-observed on macOS 27.0.1 after the 2026-10-13 icon redesign (UI-023): the repository Debug bundle and the Xcode DerivedData Debug bundle carry the same `AppIcon.icns` (identical checksum). `NSWorkspace.icon(forFile:)` for the Xcode bundle returns the new full-bleed keycap icon at 128, 64, 32 and 16 pt, so the system icon service is not serving a stale image for that path. The `RebindMenuBar` template, tinted black on a light bar and white on a dark bar at 18 pt, is legible in both. Rebind was not running during the check; the live Dock tile, the real menu bar (including selection highlight), tinted/clear icon appearances and macOS 26 were not observed.

## Next handoff

Latest stale-icon report prompted resource inspection: fresh Xcode/repository Debug copies contain identical native AppIcon.icns; another older DerivedData copy has different resources. Finder Get Info for the repository Debug bundle visibly shows the new Command mark. Touched and force-registered only the two fresh app bundles with LaunchServices, and restarted Dock once without clearing its preferences or removing DerivedData. Evidence. No Rebind/input launch by the agent; runtime result remains unconfirmed.

Have the user start one explicitly identified freshly rebuilt bundle and inspect Dock/live Menu Bar. Record that path/revision and appearance. If still stale, identify the exact icon/location and running bundle before any further cache operation. Minimum-OS/tint gates remain separate.
