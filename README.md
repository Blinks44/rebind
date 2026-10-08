# Rebind

Native macOS input remapping application. Phase 1 and current Phase 2 slices implement native
Quartz keyboard/middle-or-extra-mouse-button/discrete-wheel/button-movement → shortcut mappings, interactive
recording/editing, exact modifiers, pause/emergency bypass, permission status,
menu-bar lifecycle and atomic local configuration. **The user verified G603 Control + Button 4 → Command+A in TextEdit, with
plain Button 4 retaining its behavior. The user also confirms Button 5 long press
→ Command+A with a 1000 ms delay after cancellation fixes, and the requested
Option + Button 4 + move Left → Command+A gesture works.** Keyboard, wheel,
double press, other gesture directions and full suppression/cancellation/lifecycle checks remain open.
Multitouch and per-device rules are not implemented.

The UI is translated into English, Russian, German and French using a String
Catalog and the system language. Manual language selection remains planned.
See the [Phase 1 verification walkthrough](docs/verification/phase-1.md) for
supported limits and checks needed before claiming end-to-end support.
The [Phase 2 wheel walkthrough](docs/verification/phase-2-wheel.md) covers four
scroll directions, exact modifiers, rate limiting and remaining device checks.
The [double-press walkthrough](docs/verification/phase-2-double-press.md) explains
activation modes, cancellation and physical checks.
The [long-press walkthrough](docs/verification/phase-2-hold.md) covers thresholds,
exclusive activation and cancellation.
The [button-movement walkthrough](docs/verification/phase-2-pointer-gesture.md) covers
four directions, thresholds, cancellation, the user-confirmed leftward G603 gesture
and remaining hardware checks.
The [capture-lifecycle walkthrough](docs/verification/phase-2-lifecycle.md) covers
permission loss, tap interruption, overlapping sleep/session suspension and recovery.
The [input-diagnostics walkthrough](docs/verification/phase-2-diagnostics.md) covers
the opt-in mouse metadata viewer and its remaining physical checks.

Requirements and roadmap: [SPEC](docs/SPEC.md), [PLAN](docs/PLAN.md),
[agent instructions](AGENTS.md). Design references remain in `docs/references/`.

**Input Diagnostics** at the bottom of the main window shows numeric Quartz mouse
button codes (zero-based), button phases, wheel direction, modifiers and the engine's
passthrough/consumption/queue decision. Keyboard events/codes, typed text, pointer
coordinates, output parameters and device identity are excluded. Start explicitly:
up to 128 entries, 20 per one-second window, 60 seconds per session, memory only.
Stop retains the current rows for inspection; closing, sleep, Secure Input or capture
loss stops collection and clears them. Existing rules continue normally; diagnostics
also works with rules paused. “Queued” does not prove output delivery. No export,
logging service or new permission/dependency. Real G603 collection still needs verification.

## Development

Use full Xcode with Swift 6.2+ and a macOS 26+ SDK. The app runs on macOS 26+.
Preparation was verified with Xcode 27.0 (27A266a), Swift 6.4, macOS SDK 27.0,
and macOS 27.0.1 (26A434) on Apple Silicon. macOS 26 runtime compatibility
and Intel runtime behavior still need testing.

Open `rebind.xcodeproj`, select the shared **rebind** scheme, and Run (⌘R).
Test (⌘U) uses the connected **rebindTests** target.

```sh
scripts/dev.sh doctor
scripts/dev.sh resolve
scripts/dev.sh build
scripts/dev.sh build-for-testing
scripts/dev.sh test
scripts/dev.sh release
scripts/dev.sh run
```

The script respects `DEVELOPER_DIR` or a valid `xcode-select` selection, then
falls back to `/Applications/Xcode.app/Contents/Developer`. It never modifies
the system selection. For another Xcode installation:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer scripts/dev.sh build
```

Build output is under ignored `build/DerivedData/`. Do not run concurrent
Xcode build commands against the same DerivedData directory. Extra arguments
are forwarded to `xcodebuild`, for example:

```sh
scripts/dev.sh test -resultBundlePath build/Tests.xcresult
```

Use a fresh result-bundle path for each run. The equivalent direct build is:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
  -project rebind.xcodeproj -scheme rebind -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData
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

The existing bundle ID `blinks44.rebind` and automatic signing are preserved.
There was no development team or usable signing identity configured. Xcode's
**Sign to Run Locally** ad-hoc signing builds and launches without an account.
The app is named **Rebind**, while the project, target, scheme, directories,
and Swift module retain their existing names.

App Sandbox is disabled for the specified global input filtering, synthesis,
and Accessibility actions outside the Mac App Store. Hardened Runtime and
build-script sandboxing are enabled. Release disables Xcode base-entitlement
injection; Debug retains Xcode's debugger/test-runner entitlements. No custom
entitlements, helpers, drivers, private frameworks, or runtime packages are added.

For repeatable permission persistence tests, prefer a suitable existing Apple
Development identity/team in Xcode and keep bundle identity and launch location
stable. A locally signed build can be tested after granting access, but ad-hoc
rebuilds can invalidate TCC grants. Developer ID signing and
notarization require real credentials before distribution. Permission requests
are explicit UI actions; status uses actual AX and Quartz preflight checks. The engine starts only when the configuration is enabled or
recording is requested and required access is available. This development
session does not grant permissions or reset TCC.

The current active Quartz tap needs **Accessibility** and actual event-posting
access. A separate **Input Monitoring** grant is not required for this engine;
its missing state no longer blocks recording or remapping. If Accessibility is
granted but the event-sending check remains false, use **Allow Event Sending**
to explicitly request Quartz synthesis access. Recording/remapping remains blocked
until the real check succeeds. If a request does not show a prompt, Rebind opens
the Accessibility pane. Enable the running copy of
the app there; **Show App in Finder** reveals that exact bundle for adding it
with the + button. Refresh the status and relaunch if macOS asks. See the
[permission verification record](docs/verification/permissions.md).

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
schema 5 reads schemas 1–4, preserving ordinary/wheel/double/long-press rules, IDs and
enabled state. Legacy rules get the default long-press threshold without rewriting
the file until the next successful save.

## Agent skills

Four reviewed MIT skills are installed at project scope in `.agents/skills/`:
**SwiftUI Pro**, **Swift Concurrency Pro**, **Swift Testing Pro**, and
**AppKit Accessibility Auditor**. Their source revisions, licenses, checksums,
installation method, and packaging exclusions are recorded in
`.agents/skills/manifest.json` and `docs/PLAN.md`.

Verify their installed metadata, hashes, references, licenses and Git visibility:

```sh
python3 scripts/verify-skills.py
```

Codex discovers project skills from `.agents/skills/` on the next turn. Invoke
them with `$swiftui-pro`, `$swift-concurrency-pro`, `$swift-testing-pro`, or
`$appkit-accessibility-auditor`, or ask for the named skill. If an agent's skill
picker has not refreshed, start a new session; `AGENTS.md` also lists their
direct paths. Project requirements and the installed SDK govern platform and
API choices. [Codex skill documentation](https://learn.chatgpt.com/docs/build-skills).

The repository has no runtime Swift packages yet. Use Xcode's package manager
when a justified dependency is selected, and commit its `Package.resolved`.
`swift build` / `swift test` are not applicable to this Xcode app without a
`Package.swift`. Runtime candidates and hardware verification gates are in
`docs/PLAN.md`; none have been installed for preparation.
