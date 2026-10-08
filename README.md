# Rebind

Native macOS input remapping application. Phase 1 now implements a native
Quartz keyboard/middle-or-extra-mouse-button → shortcut slice, interactive
recording/editing, exact modifiers, pause/emergency bypass, permission status,
menu-bar lifecycle and atomic local configuration. **Physical remapping is not
yet hardware-verified.** Gestures and per-device rules are not implemented.

The UI is translated into English, Russian, German and French using a String
Catalog and the system language. Manual language selection remains planned.
See the [Phase 1 verification walkthrough](docs/verification/phase-1.md) for
supported limits and checks needed before claiming end-to-end support.

Requirements and roadmap: [SPEC](docs/SPEC.md), [PLAN](docs/PLAN.md),
[agent instructions](AGENTS.md). Design references remain in `docs/references/`.

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
versioned configuration. Tests do not post global input or start the event tap;
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

New installations start paused with no bindings. Record a key or middle/extra
mouse button and an output shortcut, save, then enable bindings. Output fires
once per press; repeats/held output, Caps Lock, Fn and modifier-only sources
remain deferred. Escape cancels recording. Pause is available in the menu bar
or with ⌃⌥⇧⌘ Escape while capture is active. The main window may close without
quitting the app. Settings are stored at
`~/Library/Application Support/Rebind/configuration.json`; a corrupt or future
file is preserved and locks editing instead of being overwritten.

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
