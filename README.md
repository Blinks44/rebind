# Rebind

Native macOS input remapping application. Phase 1 and current Phase 2 slices implement native
Quartz keyboard/middle-or-extra-mouse-button/discrete-wheel/button-movement → shortcut mappings, interactive
recording/editing, exact modifiers, pause/emergency bypass, permission status,
menu-bar lifecycle and atomic local configuration. **The user verified G603 Control + Button 4 → Command+A in TextEdit, with
plain Button 4 retaining its behavior. The user also confirms Button 5 long press
→ Command+A with a 1000 ms delay after cancellation fixes, and the requested
Button 4 + move Left → Command+A gesture works.** Keyboard, wheel,
double press, other gesture directions and full suppression/cancellation/lifecycle checks remain open.
Multitouch is not implemented. Physical-device routing is outside the current scope.

Phase 3 uses **manual profiles**: create, copy, rename and delete named rule sets,
then select one above the rules or from the Menu Bar **Profile** submenu. A profile
covers all input categories; its name does not identify a physical mouse. Switching
preserves pause and cancels the old profile's pending recognition/output/recording,
while retaining already suppressed releases. Existing schemas 1–5 migrate into
**Default** in memory, preserving all rules; the first successful edit saves the current schema (14).
No HID inventory, device-specific routing or private event-source API remains.
See the [profile walkthrough](docs/verification/profiles.md).

Phase 4 adds a shared searchable **Action** chooser for recorded keyboard shortcuts
and native default-output volume up/down/mute. Volume uses 6.25% scalar steps;
changing volume leaves mute unchanged. Main-element controls must be readable and
writable: unavailable actions are explained/disabled and their rules pass through.
Audio and shortcut sending share a bounded serial action worker, separate from the
tap run loop. The user reports the configured audio mapping and existing bindings
work after this change; all audio variants, output replacement and cancellation
still need hardware checks. See the [audio walkthrough](docs/verification/phase-4-audio.md).

**Audio** also offers **Play / Pause, Next Track and Previous Track**. These send
native system media-key down/up pairs at the HID tap from the serial action worker,
without keyboard modifiers, app-specific scripts or private MediaRemote calls.
macOS selects the recipient and its response, just as for a media key. No eligible
player or unsupported commands can mean no effect; posting cannot acknowledge
playback or promise a particular application. Current-output volume capabilities
do not gate these media keys. Construction/cancellation failures prevent the whole
pair; a begun pair always completes release. The user confirms delivery via mouse/additional buttons in different applications, including background/minimized contexts. Detailed routing, modifier/interleaving and cancellation checks remain open.
See the [media walkthrough](docs/verification/phase-4-media.md).

The **Mouse** action group adds left, right, middle and double left click at the
current global pointer position. All actions produce complete, tagged down/up pairs
through public Quartz, outside the tap callback, with no keyboard modifiers. Double
click carries click states 1 then 2; no artificial timing delay or pointer-move event.
If the target output button is already held (hardware or combined session state),
preparation fails with an error rather than synthesizing its release. That includes
mapping a held middle button to its own click: use a different trigger. Cancellation,
allocation failures and protected contexts prevent posting; a begun finite batch
finishes release. Source input already consumed is not replayed, and preparation
failure does not pause unrelated rules. The user confirms all four clicks work,
including in third-party apps (2026-10-09); exact app names/triggers were not given.
Fast pointer movement, detailed modifier/button interleaving and cancellation
remain hardware checks. Held output, dragging, back/forward and scroll output are not
implemented. See the [mouse-output walkthrough](docs/verification/phase-4-mouse-output.md).

The same chooser now offers **Windows and Applications**: close/minimize the
active window, press its full-screen button, or hide the active app through public
Accessibility APIs. Target support is checked when dispatched; Rebind itself is
excluded. Unsupported targets show an error without replaying the consumed input.
AX calls run on the serial action worker with request timeouts, focus rechecks and
cancellation before mutation. No window titles or contents are read. These actions
are implemented and unit-tested; the user confirms all four work in manual testing.
Cancellation, unsupported targets, revoked access and latency checks remain open. See the [window-action walkthrough](docs/verification/phase-4-windows.md).

Four additional window actions are implemented: Left Half, Right Half, Fill Available
Screen and Center Window (preserving size). They use public Accessibility frame
attributes on the focused ordinary window, choose its display by largest overlap
and exclude the Dock/menu bar. App size constraints may prevent a requested layout;
a partial change may remain on failure. These placements do not create macOS tile
groups. Full-screen/unsupported windows are excluded conservatively. Software
checks pass; the user confirms left/right placement and maximizing in different
applications. Centering and detailed display/constraint/cancellation checks remain
open in the [layout walkthrough](docs/verification/phase-4-window-layout.md).


The chooser also opens a selected application, activates its already running copy,
or opens an **HTTP/HTTPS address, local file or folder** in the default app. Native
system dialogs select targets. Activation never cold-launches a closed app; moved
apps/files must be selected again. Metadata preparation runs on the action worker,
with one MainActor async NSWorkspace request in flight. Pending work is cancelled
on profile/pause/capture changes; an OS-accepted request cannot be recalled. Failures
show a localized message without replaying consumed input. These actions have
software and picker/validation checks; the user confirms the requested actions work.
Detailed failure/cancellation, revoked-access and latency checks remain open. See the
[opening walkthrough](docs/verification/phase-4-opening.md).

**Automation → Run Apple Shortcut** selects an existing command from Apple's
native Shortcuts list. Rules store its UUID; renaming does not change that identity,
and a deleted command never falls back to another command with the same name.
Refresh updates the list and displayed names. Execution uses the native CLI on
the action worker, without shell code or clipboard/file input. Other output waits
while it runs. Rebind stops waiting after 60 seconds or a cancellation; this cannot
undo accepted steps or guarantee that the Shortcuts service stops the workflow.
Software tests, native listing and Russian picker checks pass; the user confirms
the requested Apple Shortcut execution works. Rename/delete, prompts, cancellation
and latency remain manual checks. See the [Shortcuts walkthrough](docs/verification/phase-4-shortcuts.md).

**Mission Control and Spaces** offers three experimental direct Dock notifications:
Mission Control, current-app windows and Show Desktop. The user confirms these
three effects work on the current setup; detailed cancellation/latency checks remain open.

Previous/next Space now posts the standard Control+Left/Right keyboard pair using
public Quartz HID-state events at the HID tap, with the secondary-Fn arrow flag.
The intended behavior is the normal system slide and first/last-desktop handling,
including Reduce Motion and the focused display. It replaces the instant Dock swipe,
which failed user acceptance: abrupt transitions and a black-screen bounce at the edge.
No gesture serialization, Space prediction or animation override remains.
The system Mission Control shortcuts must be enabled and use the standard chords;
disabled, customized or malformed overrides prevent posting and show a localized error.
The editor explains this dependency; catalog availability denotes API support,
while settings are checked on the worker at execution. System preferences are never
changed. Posting does not confirm the visual effect; the user now reports everything works well after the requested animation and
first/last-desktop retest with the existing Windows modifier remap. Exact
individual cases and timings were not restated; broader safety/display checks remain. Ordinary shortcuts and the three
Dock notifications retain their senders. Deployment remains macOS 26; the old private
26.6/27 gesture-layout gate is removed. Typed Space actions and existing rules are preserved;
schema 16 adds window layout after schema 15 media and schema 14 mouse output, and loading older schemas still never rewrites the file. See the
[Space walkthrough](docs/verification/phase-4-spaces.md) and
[third-party notice](rebind/Resources/ThirdPartyNotices.txt).

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
logging service or new permission/dependency. Basic G603 side-button collection and
paused passthrough decisions are user-verified; physical expiry, clearing, active-rule
regression and performance checks remain open.

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
schema 15 reads schemas 1–14, preserving profiles, selection, shortcut/audio/mouse/window/opening/Apple Shortcut/desktop actions,
ordinary/wheel/double/long-press/gesture rules, IDs and enabled state. Legacy rules get the default long-press threshold without rewriting
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
