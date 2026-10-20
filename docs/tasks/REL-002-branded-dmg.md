# REL-002: Rebind-style drag-to-install disk image

- Updated: 2026-10-19
- Stage: done
- Owner: unassigned; released
- Baseline: main e070ec9 plus existing touch/keyboard/signing work, preserved
- Scope: Brand DMG frame in Rebind.sketch, shipping background, release packaging and related records

## Outcome

Match Monny's simple installer composition using Rebind's own soft light surfaces, blue accent and icon. Native Finder app and Applications targets sit on rounded cards with an arrow. Source in Sketch, one versioned Retina TIFF, no extra permanent generator. Preserve stable signing and existing ZIP fallback; no app launch, permissions, rules or publication.

## Acceptance

- [x] Saved/live-reviewed Sketch source and matching shipping asset.
- [x] Existing release command creates the branded signed DMG; app/DMG/integrity checks pass.
- [x] Actual mounted Finder window and targets inspected, docs/current records updated.

## Source and regeneration

Saved Rebind.sketch on 2026-10-19. Page 04 · Brand, frame Brand/Distribution/DMG · Light: B4C4E361-CE7D-420F-95D2-09D015D93CCF. Background-only child: B6D5B769-FD4E-4702-86A8-D9D90020B9F7. Native icon/filename preview is a separate group and is not shipped in the raster. Existing Rebind Canvas/Card layer styles, Title text style and blue Accent variable are reused. No new product copy/localization is required; Finder supplies real filenames and targets.

Export background-only child at 1×/2× to temporary PNG files, then tiffutil -cathidpicheck background-1x.png background-2x.png -out apps/rebind/scripts/dmg/background.tiff. This one shipping artwork is intentionally versioned. Deleted tools/dmg-background.swift, which generated the superseded arrow-only artwork; all active regeneration references updated. Existing create-dmg 1.3.0 remains the build-time tool; ZIP fallback is preserved. No new dependency or generator.

## Verification — 2026-10-19

Source screenshot reviewed and saved separately from Git. Existing release.sh passed Release build, strict app and DMG signature checks and final hdiutil integrity verification (now included in the script). Artifact: apps/rebind/build/release/Rebind-1.0-1.dmg; SHA-256 598ef62f83aa1a18e01af14d7468fb829433763f81c901cbe7dc4e81da2fab9d. Same Rebind Release signer retained. Existing unrelated deprecation warnings were not changed.

Mounted final image read-only and inspected actual Finder window through CUA: title/blue-tinted canvas, rounded cards, arrow, app icon and native Applications folder are present and aligned. Saved metadata confirms 660×420 window, 128 pt icons, 13 pt labels and image background. Applications resolves to /Applications; app executable exists. No copy/install/launch, permission/rule changes, publication or Git commit. Packaging-only change: full application tests not rerun. Shell syntax, document links, shipping-asset ignore policy and git diff --check pass. Existing unrelated touch/keyboard and signing work preserved.

Next: use this styled artifact for the existing manual installation/update/accessibility acceptance; packaging verification does not close those gates.


## UI continuation package — 2026-10-20

The UI-024 continuation rebuilds the unchanged packaging source with the current UI and grouped six-choice mouse menu. apps/rebind/build/release/Rebind-1.0-1.dmg now has SHA-256 fb25d5faa0ddcc128b2e1c1a278a7b8ce50358ac6ca0200b2c74195e492f260d. Release/app/DMG signature and hdiutil verification pass under the same stable signer. The previous dated artifact hash above remains historical; same local filename is replaced. No new Finder-layout inspection, installation/update or publication is claimed.


## Final app candidate — 2026-10-20

REL-003 supersedes the earlier local package at the same filename after the manual update command and final regression pass. Current Rebind-1.0-1.dmg SHA-256: `ee033c3f76247c8a929a11057694a95065ddb65c07f4ff93b451bb52909adccb`. Stable app/DMG signature and image integrity verification pass; packaging source/artwork unchanged. No new installation/update acceptance.
