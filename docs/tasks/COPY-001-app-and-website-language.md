# COPY-001: Natural, accurate app and website language

- Updated: 2026-10-28
- Stage: awaiting_verification (2026-10-28 follow-up; the original audit below is done)
- Owner: Unassigned; follow-up implemented and packaged, user review of the revised strings pending
- Ownership: Copy work based on `824b8c3`; release-script/permanent-link commit `5252dc1` preserved on main; scoped Sketch editing complete
- Owned surfaces: Localizable catalog, six website message catalogs and device labels, app build number and affected project records; Navigation/InfoPlist reviewed without changes
- Requirements: User-requested full source/localization copy audit; SPEC §§3–11 and localization/permission/privacy contracts

## Outcome and scope

All three app catalogs (655 Localizable entries, four Navigation entries and four InfoPlist entries) and all six website locales were reviewed. Revised **233 app values across 99 keys** and **251 existing website values across 80 keys**; added two device-name keys in every website locale (now 161 messages each). Input matching, actions, storage and the saved-language/reopen contract are unchanged. No installation, remapping, permission changes, publication or deployment.

Voice remains calm, concise, direct and helpful (ENGINEERING). App terms remain Binding/rule, Belegung, règle, regla and 规则; distinguish keyboard shortcuts from Apple Shortcuts and a tap from a physical click. German app and website instructions use Sie consistently.

## Changes

- Replaced literal phrasing around held keys, physical clicks, scrolling, device names, onboarding and language activation. Russian instructions distinguish taps from presses and use consistent rule terminology. German website uses Sie consistently and distinguishes Tastenkürzel from Apple-Kurzbefehle. French backup labels use sauvegarde; French/Spanish/Chinese website rules match the app's terminology. Chinese Magic-device tabs and alt text now use the localized names.
- Website now describes the published DMG in the present tense, startup snapshots with up to 10 copies, optional automatic update checks, category-wide rules and Bluetooth batteries for mice, keyboards and trackpads. Removed unsupported universal-input and one-minute-install promises and the imprecise paid-Developer-ID explanation.
- App Secure Input feedback names the actual macOS state rather than asserting a focused password field. Diagnostics distinguishes a queued action from an action already started. Hold guidance includes the optional short-press shortcut. Closed-window guidance remains true with the menu-bar icon hidden. Experimental/native-gesture and device-model limits are preserved.

## Verification — 2026-10-25

- JSON/catalog review confirms complete locale coverage for translatable entries, nonempty values, unchanged printf/plural/substitution placeholders and unchanged existing plural structures. Brand and interpolation-only entries intentionally remain nontranslated. Website key/placeholder parity passes with the two added name keys. No new checker framework or test was added.
- Debug build passes. The first sandboxed build could not write standard Swift/Xcode caches; the host-context rerun succeeds. The first native test launch timed out before connecting to its runner (zero tests executed); subsequent serialized runs pass without project/toolchain changes.
- Existing language suite: **9 methods / 48 parameter cases**, zero failures/skips (`Test-rebind-2026.10.25_22-34-33-+0300.xcresult`). Main affected slice: **33 methods / 74 executions**, zero failures/skips (`Test-rebind-2026.10.25_22-35-10-+0300.xcresult`), covering language labels, backup plural counts/transactions and native About, Advanced, General, Input/Language, Mouse/Trackpad/Magic Mouse and Permissions/Devices layouts across all six languages and Light/Dark. After the final closed-window wording correction, **two native methods** pass (`Test-rebind-2026.10.25_22-39-29-+0300.xcresult`): General states/locales plus main-window/sheet renderings. Counts overlap; do not add them as unique tests.
- Sampled native attachments reviewed: Russian About/Advanced/Permissions, German hold editor, English Magic Mouse editor and final Welcome. Text wraps within the existing scrollable layouts; no geometry change. These offscreen fixtures use disposable data and never start input capture. Screenshots remain temporary. Existing fixture AppKit live-window-count warning is not a production regression.
- Website `pnpm check` passes (Paraglide, formatting, lint, TypeScript, **15 tests**); final `pnpm build` and **seven HTTP smoke tests** against the fresh workerd preview on port 4179 pass. Earlier sandboxed preview/HTTP attempts failed on socket access; host-context checks pass. Existing upstream CSS `@theme`, sourcemap and bundle-size advisories remain. Browser connectors are unavailable, so final browser wrapping/interaction and physical-phone review are not claimed. Local previews were stopped after checks.
- Source version/build is **1.0.0 (16)** in Debug and Release. Packaging evidence is recorded below.

## Local installation package

`apps/rebind/scripts/release.sh` succeeds for **1.0.0 (16)** with the existing pinned Apple Development identity. Release compilation, nested/app strict/deep signatures, DMG signature, image integrity and checksum verification pass; the signed Sparkle appcast and `SHA256SUMS.txt` were regenerated locally. Packaged Info.plist and 30 representative changed values across all six compiled catalogs match source. Artifact: `apps/rebind/build/release/Rebind-1.0.0-16.dmg`; SHA-256 `8d2c87894ada048b99d97041a9214b2567d04241c1a643315a8b404a2d1d1576`. The package remains non-notarized. Build 15 remains the published release; this task does not upload or install build 16.

## Source and evidence

Baseline: main `824b8c3`, source 1.0.0 (15). ConfigurationStore confirms startup snapshots, not every-edit history; AppUpdater confirms optional automatic checks and installation confirmation. Native Secure Input status does not establish that a password field is currently focused. Diagnostics queue acceptance does not establish completed action execution.

Apple installation and Magic Mouse gesture instructions checked against https://support.apple.com/102445 and https://support.apple.com/102482 on 2026-10-25.

Sketch synchronized and saved on 2026-10-26. Updated the English app screens in Light/Dark, component text overrides, desktop/mobile website copy, installation alert, FAQ, About build 16 and the optional-update annotation. Each MCP edit batch was screenshot-reviewed; longer copy received local spacing corrections in hold sheets, mouse cards and mobile website sections. The final mobile composition and annotation were reviewed visually. After the Sketch connector became unavailable, remaining About/annotation edits and Save used the native UI. Saved-file readback confirms seven representative text layers, the annotation and mobile frame height. SHA-256: `ba7afd4328e097cb4e222fd30f3a2e5487f63117fb1e1fb13cd6857968d24c24`. Existing embedded device illustrations do not contain the changed copy; no shipped image refresh was needed. Screenshots remain local.

Completion preserves `5252dc1`, the other agent's committed permanent `Rebind.dmg` release name and website link. Shell syntax check passes. The signed build-16 package above predates that filename change; it remains the verified installation artifact. No new native source edits or packaging rerun were needed for the final Sketch/documentation work.

## Tester acceptance — 2026-10-26

The user confirms completing the requested targeted review of the corrected app/website text associated with build 16. Exact environment, locale/width/per-control VoiceOver matrix and native-speaker coverage were not supplied; this closes the bounded copy follow-up, not broader platform/accessibility gates. Read-only artifact inspection during PERF-001 also confirms installed Rebind is 1.0.0 (16).

## Follow-up pass — 2026-10-28

User-requested second pass over all six languages, including strings added after build 16 (standard actions, lighting, error banner). Revised **81 app values across 48 keys** and **30 website values across 16 keys**; no keys added or removed, placeholders unchanged.

- Accuracy: launch backups are described as copies saved when the configuration changed (last 10), matching `ConfigurationStore.backUpLoadedFile`; the physical-key fallback is now a key code; the Spotlight/Emoji hint says it works only when macOS uses the same shortcut; vendor apps are quit, not closed.
- Calques and literal phrasing: Russian mouse output actions use "Щелчок … кнопкой" consistently with Double Left Click; Russian "Keep color" no longer reads as "save"; German uses Tastaturkurzbefehle for macOS keyboard shortcuts, fixes "unmute" rendered as "activate" and names the Force Quit window; French fixes the iPhone "silent mode" calque, Zoom In/Out colliding with Minimize, and "Clic central"; Spanish "idle" no longer reads as sleep (reposo); Chinese removes duplicated wording.
- Website: Russian privacy text no longer repeats "доступ", German download button no longer says "Laden", lighting/menu sentences rewritten in all languages, high-resolution wheel and smooth-scrolling names match the app.

Verification: website `pnpm check` (Paraglide, format, lint, TypeScript, 15 tests) passes. App `dev.sh test -only-testing:rebindTests`: **960 tests / 148 suites** pass. `release.sh` succeeds for **1.0.0 (29)**: app/DMG signatures verified, packaged `ru.lproj` contains the revised values. DMG `apps/rebind/build/release/Rebind.dmg`, SHA-256 `bde86889488f258d82e1c56e407c0aacc708cc92535592ea742ddc7ab9948722`. Not installed, not published; website not deployed. Sketch not updated: affected English source strings (backup description, key code, Magic Mouse scroll help, shortcut hint, lighting messages, website menu text) still need a Sketch sync if those frames show them.

## Next handoff

- User: review the revised strings in build 29 and on a local website preview; then deploy the website and sync the changed English strings to Sketch when authorized.
- Maintainer: publish/deploy only through the existing release workflow when separately authorized; the website uses the permanent latest-release link (currently published build 15).
