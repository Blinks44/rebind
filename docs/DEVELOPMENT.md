# Rebind — development and local setup

Build commands, signing, permission troubleshooting and detailed rule semantics for contributors. For the product overview and first launch, see the [root README](../README.md). Current capability evidence is in [CAPABILITIES](CAPABILITIES.md); agent startup/handoff is defined in [AGENTS](../AGENTS.md) and [WORKFLOW](WORKFLOW.md).

## Build and test


Use full Xcode with Swift 6.2+ and a macOS 26+ SDK. The app runs on macOS 26+.
The last recorded development environment (2026-10-10) used Xcode 27.0 (27A266a), Swift 6.4, macOS SDK 27.0,
and macOS 27.0.1 (26A434) on Apple Silicon. macOS 26 runtime compatibility
and Intel runtime behavior still need testing.

Open `apps/rebind/rebind.xcodeproj`, select the shared **rebind** scheme, and Run (⌘R).
Test (⌘U) uses the connected **rebindTests** target.

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

Build output is under ignored `apps/rebind/build/DerivedData/`. Do not run concurrent
Xcode build commands against the same DerivedData directory. Extra arguments
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
entitlements, helpers or drivers are added. The app has no Swift package dependency;
isolated dynamic private APIs are used for explicitly experimental trackpad/Dock/lock
paths. See the
[current mechanism decisions](research/README.md) and bundled third-party notices.

For repeatable permission persistence tests, prefer a suitable existing Apple
Development identity/team in Xcode and keep bundle identity and launch location
stable. A locally signed build can be tested after granting access, but ad-hoc
rebuilds can invalidate TCC grants. Developer ID signing and
notarization require real credentials before distribution. Permission requests
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

New installations start paused with no bindings. Record a key or middle/extra
mouse button and an output shortcut, save, then enable bindings. In **All mice**,
choose **Scroll Wheel** in the editor to record up/down/left/right with modifiers.
Key/button output defaults to one pulse per press. Choose **Double press** to
fire on the second down after releasing the first, within the system double-click
interval measured from the first down. Both presses are consumed; a lone press
does nothing. Other presses, modifier changes, repeats and dragging cancel the
sequence. Only one enabled activation mode is allowed for a source/modifier
combination. Choose **Long press** for one pulse after holding for 100–5000 ms
(default 500 ms). Short presses are consumed without replay. Modifier changes,
another press, scroll, pause or editing cancel the pending action. Movement with
the held mouse button preserves the deadline; dragging with another button cancels it.
Switching away from Rebind cancels explicit recording, but preserves background recognition. A delayed
worker skips stale actions. This mode does not hold output keys or repeat actions.
Held output and native triple-click recognition remain deferred.
Choose **Button + movement** in **All mice** to record a middle/extra button with
modifiers and select left/right/up/down. Move clearly within five seconds of pressing
the source: one shortcut fires when its stroke crosses the threshold. Direction rules
may share the same button/modifiers, but conflict with ordinary/double/long press on
that chord. These four directions are the complete intended mouse pointer gesture set;
diagonals, spirals/circles and multi-stroke figures are out of scope. A click without a
gesture is consumed without replay. Gesture movement
is consumed until release, cancellation or timeout; diagonals or an unconfigured
first direction cancel. Other presses, modifier changes, scrolling, editing and pause
also cancel. Sensitivity depends on delivered Quartz deltas and mouse/driver settings.
This is implemented and software-tested; the configured G603 leftward gesture works
per the user, while other directions and full safety/cursor checks remain pending.
Wheel output is limited to one pulse
per 100 ms across wheel bindings; intermediate matched events are consumed.
Smooth, momentum, diagonal and unmatched scroll events pass through. Directions
follow delivered macOS events, including system direction settings and other
utilities' transformations; there is no physical mouse attribution.
Repeats/held output, Caps Lock, Fn and modifier-only sources
remain deferred. Escape cancels recording. Pause is available in the menu bar
or with ⌃⌥⇧⌘ Escape while capture is active. The main window may close without
quitting the app. Settings are stored at
`~/Library/Application Support/Rebind/configuration.json`; a corrupt or future
file is preserved and locks editing instead of being overwritten. Configuration
schema 23 reads schemas 1–22, preserving profiles, selection and existing actions/triggers,
ordinary/wheel/double/long-press/gesture rules, IDs and enabled state. Legacy rules get the default long-press threshold without rewriting
the file until the next successful save. Schema 23 also stores explicit first-run setup acknowledgement; existing installations migrate with setup acknowledged. Grant recovery never changes saved pause or rule flags.


## Trackpad scheduling diagnostics

For an explicitly authorized physical run, `--diagnose-trackpad` enables a one-minute aggregate console report; it uses existing rules and may execute their configured actions. It does not create a test rule or induce UI stalls. Quit the other Rebind copy before starting the identified bundle.

Alongside cancellation/output counters, `frame-age-*` records receipt-to-dequeue age and `posted-queue-age-*` records mailbox admission to the final pre-post time for balanced pairs actually posted. Buckets are disjoint: up to 10, 20, 60, 100 and 160 ms, then greater than 160 ms. Each boundary belongs to the lower bucket. Exact durations/timestamps, contacts, typed text and target identity are excluded. These counters do not measure physical finger-lift-to-visible-action latency, successful app delivery, or callback cost; use an external timing method for those. Missing buckets mean no samples, not zero latency. Report collection finishes once; protected-context/capture-loss paths clear it. [Scheduling checks and remaining acceptance](verification/trackpad-scheduling-timing.md).

## Packages and research tools

The app target has no Swift package dependency. Source adaptations and isolated private APIs are documented in [research](research/README.md), the [dependency/reference register](research/DEPENDENCIES.md) and [bundled notices](../apps/rebind/rebind/Resources/ThirdPartyNotices.txt).

The standalone TrackpadProbe package that established contact acquisition was removed on 2026-10-13 once its engine was integrated; it remains in Git history (last present in `64dadc3`). `apps/rebind/tools/magic-mouse-probe.swift` is the current single-file probe for external multitouch devices.

## Releasing without notarization

Rebind is distributed outside the App Store and is not notarized. `apps/rebind/scripts/release.sh` builds Release, signs the bundle with one stable self-signed certificate (default name **Rebind Release**, override with `REBIND_SIGN_IDENTITY`) under the hardened runtime, and writes `apps/rebind/build/release/Rebind-<version>-<build>.dmg` with its SHA-256 for GitHub Releases. The disk image (app, Applications shortcut and an arrow on `scripts/dmg/background.tiff`) needs the `create-dmg` tool (`brew install create-dmg`, MIT); without it the script falls back to a zip. Regenerate the background with `apps/rebind/tools/dmg-background.swift` and `tiffutil -cathidpicheck`.

- The certificate is created once in Keychain Access (the script prints the steps when it is missing). **Back up its `.p12`.** macOS ties the Accessibility grant to the signature; a release signed with a different certificate makes every user grant the permission again.
- Do not sign releases with an "Apple Development" certificate: its designated requirement embeds the account's e-mail address in the published signature, and the certificate expires yearly.
- Gatekeeper still blocks the first launch of a downloaded copy until the user chooses **Open Anyway** in System Settings → Privacy & Security; the README explains this to users.
- Moving to Developer ID and notarization later changes the signature once: users confirm the Accessibility permission one more time.

## Contribution workflow

Inspect the existing implementation and [current state](STATE.md) before choosing a slice. Read [engineering standards](ENGINEERING.md) for native input, Swift/concurrency, localization and security requirements. UI work follows [DESIGN](DESIGN.md) and current Sketch frames. Build/test the affected behavior, record the required runtime/manual checks and preserve unrelated work. [WORKFLOW](WORKFLOW.md) describes durable task records and handoff. Detailed per-action behavior and checks live in [verification](verification/); the root README stays a concise public overview.
