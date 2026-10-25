# Rebind: development and local setup

Build commands, signing, permission troubleshooting and local diagnostics for contributors. For the product overview and first launch, see the [root README](../README.md). Current capability evidence is in [CAPABILITIES](CAPABILITIES.md); agent startup/handoff is defined in [AGENTS](../AGENTS.md) and [WORKFLOW](WORKFLOW.md).

## Build and test


Use full Xcode with Swift 6.2+ and a macOS 26+ SDK. The app runs on macOS 26+.
The last recorded development environment (2026-10-20) used Xcode 27.1 (27A9275), Swift 6.4, macOS SDK 27,
and macOS 27.0.1 (26A434) on Apple Silicon. macOS 26 runtime compatibility
and Intel runtime behavior still need testing.

Open `apps/rebind/rebind.xcodeproj`, select the shared **rebind** scheme, and Run (⌘R).
Test (⌘U) uses the connected **rebindTests** target.
The project carries Xcode 27.1 recommended settings: dead-code stripping, the
nonlocalized-string analyzer check, project-level String Catalog symbols and
Development Team, and the Utilities App Store category.

```sh
apps/rebind/scripts/dev.sh doctor
apps/rebind/scripts/dev.sh resolve
apps/rebind/scripts/dev.sh build
apps/rebind/scripts/dev.sh build-for-testing
apps/rebind/scripts/dev.sh test
apps/rebind/scripts/dev.sh release
apps/rebind/scripts/dev.sh run
```

The script respects `DEVELOPER_DIR` or a valid `xcode-select` selection, then
falls back to `/Applications/Xcode.app/Contents/Developer`. It never modifies
the system selection. For another Xcode installation:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer apps/rebind/scripts/dev.sh build
```

Build output is under ignored `apps/rebind/build/DerivedData/`. Set `REBIND_DERIVED_DATA`
to an absolute alternate directory for an isolated build/test/run, preserving a different
app artifact currently being tested on hardware. Do not pass a second `-derivedDataPath`.
Do not run concurrent Xcode build commands against the same DerivedData directory. Extra arguments
are forwarded to `xcodebuild`, for example:

```sh
apps/rebind/scripts/dev.sh test -resultBundlePath build/Tests.xcresult
```

Use a fresh result-bundle path for each run. The equivalent direct build is:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
  -project apps/rebind/rebind.xcodeproj -scheme rebind -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath apps/rebind/build/DerivedData
```

The Swift Testing target covers matching, exact modifiers, press/release
ownership, conflict handling, emergency pause, recording, bounded dispatch,
Secure Input/suspension policy, balanced/tagged event construction and
wheel direction/passthrough, scroll throttling, double-press sequences and
versioned configuration migration.
Tests do not post global input or start the event tap;
they use temporary configuration files. Real event interception and shortcut
delivery still require the documented manual checks.

Debug UI walkthroughs can use the production window/editor/Settings hierarchy without
loading real rules or starting the input engine:

```sh
open -n apps/rebind/build/DerivedData/Build/Products/Debug/Rebind.app --args --application-fixture
```

`--application-fixture` seeds do-nothing rules in disposable temporary storage and disables
category-preference persistence. Main-window permission values are injected. It is Debug-only and does not prove
actual permissions, recording delivery or hardware remapping. See [UI-024](tasks/UI-024-keyboard-navigation.md)
and the [final acceptance queue](verification/release-candidate.md).

## Signing and permissions

Keep bundle ID `blinks44.rebind` and the existing automatic signing settings stable.
The recorded development builds use Xcode's **Sign to Run Locally** ad-hoc signing.
Choose an appropriate local identity/team for your environment; no developer
credentials are stored in this repository.
The app is named **Rebind**, while the project, target, scheme, directories,
and Swift module retain their existing names.

App Sandbox is disabled for the specified global input filtering, synthesis,
and Accessibility actions outside the Mac App Store. Hardened Runtime and
build-script sandboxing are enabled. Release disables Xcode base-entitlement
injection; Debug retains Xcode's debugger/test-runner entitlements. No custom
entitlements or drivers are added. The app uses the local MIT HIDPP package and the
embedded Sparkle framework (its own updater helpers);
isolated dynamic private APIs are used for explicitly experimental trackpad/Dock/lock
paths. See the
[current mechanism decisions](research/README.md) and bundled third-party notices.

For repeatable permission persistence tests, prefer a suitable existing Apple
Development identity/team in Xcode and keep bundle identity and launch location
stable. A locally signed build can be tested after granting access, but ad-hoc
rebuilds can invalidate TCC grants. Releases are signed with the shared pinned Apple Development certificate and are not
notarized; see [Releasing without notarization](#releasing-without-notarization). Permission requests
are explicit UI actions; status uses actual AX and Quartz preflight checks. The engine starts only when the configuration is enabled or
recording is requested and required access is available. Grant access explicitly to the copy you intend to run; do not reset TCC as a build step.

The current active Quartz tap needs **Accessibility** and actual event-posting
access. A separate **Input Monitoring** grant is not required for this engine;
its missing state no longer blocks recording or remapping. If Accessibility is
granted but the event-sending check remains false, use **Allow Event Sending**
to explicitly request Quartz synthesis access. Recording/remapping remains blocked
until the real check succeeds. If a request does not show a prompt, Rebind opens
the Accessibility pane. Enable the running copy of
the app there; **Show App in Finder** reveals that exact bundle for adding it
with the + button. Refresh the status and relaunch if macOS asks. See the
[permission verification record](verification/permissions.md).

## Configuration and rule behavior

New installations start paused with no bindings. Configure a keyboard/mouse trigger or choose a curated touch preset, select an action, save, then enable bindings. Escape cancels recording. Global pause is available in the Menu Bar and through ⌃⌥⇧⌘ Escape while capture is active; closing the window does not quit the app.

[SPEC §§2–4](SPEC.md#2-trigger--rule--action-contract-core) owns current matching, held output, pointer/wheel behavior, profiles and editing requirements. [CAPABILITIES](CAPABILITIES.md) separates implementation from actual hardware acceptance. Historical verification contracts describe their tested revision; do not infer current restrictions from an old schema or UI snapshot.

Configuration lives at `~/Library/Application Support/Rebind/configuration.json`. The current codec is [Configuration.swift](../apps/rebind/rebind/Persistence/Configuration.swift): it owns the current schema and supported migrations. Corrupt/future originals are preserved and editing locks instead of silently overwriting them. Migrations retain source bytes until a successful save. See [protected-save/restoration evidence](verification/protected-saves-and-restoration.md); no real user configuration belongs in repository records.

## Trackpad scheduling diagnostics

For an explicitly authorized physical run, `--diagnose-trackpad` enables a one-minute aggregate console report; it uses existing rules and may execute their configured actions. It does not create a test rule or induce UI stalls. Quit the other Rebind copy before starting the identified bundle.

Alongside cancellation/output counters, `frame-age-*` records receipt-to-dequeue age and `posted-queue-age-*` records mailbox admission to the final pre-post time for balanced pairs actually posted. Buckets are disjoint: up to 10, 20, 60, 100 and 160 ms, then greater than 160 ms. Each boundary belongs to the lower bucket. Exact durations/timestamps, contacts, typed text and target identity are excluded. These counters do not measure physical finger-lift-to-visible-action latency, successful app delivery, or callback cost; use an external timing method for those. Missing buckets mean no samples, not zero latency. Report collection finishes once; protected-context/capture-loss paths clear it. [Scheduling checks and remaining acceptance](verification/trackpad-scheduling-timing.md).

## Packages and research tools

The app target uses the vendored local MIT package `apps/rebind/Packages/HIDPP` for Logitech HID++ and the remote MIT package Sparkle 2.10.0 for updates (`Package.resolved` is versioned). Source adaptations and isolated private APIs are documented in [research](research/README.md), the [dependency/reference register](research/DEPENDENCIES.md) and [bundled notices](../apps/rebind/rebind/Resources/ThirdPartyNotices.txt).

The standalone TrackpadProbe package that established contact acquisition was removed on 2026-10-13 once its engine was integrated; it remains in Git history (last present in `64dadc3`). `apps/rebind/tools/magic-mouse-probe.swift` is the current single-file probe for external multitouch devices. `apps/rebind/tools/trackpad-click-probe.swift` prints trackpad button and pressure events beside the contact state, to tell physical presses from clicks macOS makes itself.

## Releasing without notarization

Rebind is distributed outside the App Store and is not notarized. `apps/rebind/scripts/release.sh` builds Release, signs the bundle with the shared pinned Apple Development certificate (same existing certificate as Monny; override with `REBIND_SIGN_IDENTITY`, optional keychain with `REBIND_SIGN_KEYCHAIN`) under the hardened runtime, and writes `apps/rebind/build/release/Rebind.dmg` (a fixed name for the stable latest-release download link) and prints its SHA-256 for GitHub Releases. The complete publication sequence is in [RELEASING](RELEASING.md). The disk image (app, Applications shortcut and an arrow on `scripts/dmg/background.tiff`) needs the `create-dmg` tool (`brew install create-dmg`, MIT); without it packaging stops before building. The source is the saved Brand/Distribution/DMG frame in Rebind.sketch; export only its background child at 1×/2× and combine with `tiffutil -cathidpicheck`. Source and verification: [REL-002](tasks/REL-002-branded-dmg.md). No separate background generator is kept.

- Release resolves one exact name/fingerprint including self-signed identities; missing/ambiguous matches stop before building and never generate a replacement. Full build/backup/reinstall instructions: [SIGNING](SIGNING.md).
- The certificate is created once in Keychain Access (the script prints the steps when it is missing). **Back up its `.p12`.** macOS permission identity depends on the signature and bundle identity. A signer transition can require a new grant; test preservation between distinct stable-signer builds.
- The current local installation candidate uses the shared Apple Development identity. Build 3 is a deliberate transition from Rebind Release and may need a fresh Accessibility grant; keep that signer stable afterwards. Developer ID/notarized distribution and other-Mac acceptance remain open.
- Gatekeeper still blocks the first launch of a downloaded copy until the user chooses **Open Anyway** in System Settings → Privacy & Security; the README explains this to users.
- Moving to Developer ID and notarization later changes the signature once: users confirm the Accessibility permission one more time.

## Contribution workflow

Inspect the existing implementation and [current state](STATE.md) before choosing a slice. Read [engineering standards](ENGINEERING.md) for native input, Swift/concurrency, localization and security requirements. UI work follows [DESIGN](DESIGN.md) and current Sketch frames. Build/test the affected behavior, record the required runtime/manual checks and preserve unrelated work. [WORKFLOW](WORKFLOW.md) describes durable task records and handoff. Detailed per-action behavior and checks live in [verification](verification/); the root README stays a concise public overview.


### Updates (Sparkle)

Rebind embeds Sparkle 2.10.0 (SPM, exact version). `apps/rebind/Info.plist` is merged into the generated Info.plist and sets `SUFeedURL` (`https://github.com/Blinks44/rebind/releases/latest/download/appcast.xml`), `SUPublicEDKey`, `SUEnableAutomaticChecks` and a daily `SUScheduledCheckInterval`. Sparkle compares `CFBundleVersion`, so every published build needs a larger build number. `release.sh` signs Sparkle's nested code with the app identity and writes `build/release/appcast.xml` with `generate_appcast`, which signs the DMG with the EdDSA private key from the login keychain (created once with Sparkle's `generate_keys`; see [SIGNING](SIGNING.md#update-signing-key)). Upload the DMG and `appcast.xml` to the same stable GitHub release. Drafts and prereleases are not offered because `latest/download` resolves only the latest published release. See [REL-005](tasks/REL-005-onboarding-and-updates.md).
