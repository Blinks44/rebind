# Rebind

Native macOS input remapping application, currently at repository preparation.
The existing SwiftUI starter screen is unchanged. No input interception,
permissions onboarding, remapping, or gestures have been implemented.

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

The test target imports Swift Testing and `@testable import rebind` to verify
the infrastructure. It intentionally contains **zero behavioral tests**.
Add meaningful matcher, lifecycle, and persistence tests with their features;
an empty successful runner is not evidence of product correctness.

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

Before validating real input permissions, configure a suitable existing Apple
Development identity/team in Xcode and keep bundle identity and launch location
stable. Ad-hoc rebuilds can invalidate TCC grants. Developer ID signing and
notarization require real credentials before distribution. The preparation
session does not grant permissions or reset TCC. Future onboarding must check
actual Accessibility/Input Monitoring state and request only needed access.

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
