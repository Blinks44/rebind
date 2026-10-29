<p align="center">
  <img src="docs/images/app-icon.png" alt="Rebind app icon" width="128" height="128">
</p>

<h1 align="center">Rebind</h1>

<p align="center">
  Remap keys, mouse buttons and trackpad gestures to shortcuts and macOS actions.<br>
  Free, open source, native on macOS 15+.
</p>

A native macOS utility for mapping keyboard and mouse input to shortcuts and system actions. Create a binding, choose its trigger and action, and keep it running from the menu bar while you work in other apps.

Rebind runs on **macOS 15 and later**, with SwiftUI/AppKit and a calm, soft native design built on a shared design system. Rules stay on your Mac; no account, cloud backend or analytics are required.

**Status:** version 1.3. Keyboard and mouse remapping is the stable core; trackpad and Magic Mouse gestures are experimental. Testing so far has been on Apple silicon with macOS 27, plus a macOS 15 virtual machine. The [capability matrix](docs/CAPABILITIES.md) lists what has been tried on real hardware.

## Repository layout

| Path | Contents |
| --- | --- |
| `apps/rebind/` | The macOS app: Xcode project, sources, tests, the `scripts/dev.sh` build script and developer tools |
| `apps/website/` | The project website: TanStack Start/React 19 on Vite, moduix, six-language Paraglide and Cloudflare Workers ([README](apps/website/README.md)) |
| `docs/` | Specification, design notes, roadmap, current state and verification records |
| `AGENTS.md`, `.agents/` | Instructions and skills for coding and design agents |

## Features

**Triggers**

- Keyboard keys and shortcuts; middle and extra mouse buttons, with Command, Control, Option and Shift.
- Press, double press and hold. A hold binding can also send a shortcut on a short press.
- Mouse wheel steps, a held button plus movement in four directions, and a held button plus the wheel.
- Trackpad taps with three or four fingers, double taps, clicks with two to four fingers and corner taps, each optionally with one held modifier key. The built-in trackpad and an external Magic Trackpad have separate bindings.
- Experimental Magic Mouse taps with one, two or three fingers, one-finger taps on the left or right half, a physical three-finger click and two-finger scroll up/down. Each supports one optional held modifier and the shared action catalog. Native Smart Zoom and Mission Control may also respond to repeated taps.

**Actions**

- Keyboard shortcuts, kept pressed and repeated while the trigger is held if you choose; named commands such as Copy, Paste, Undo, Back, Forward, tab and zoom commands and screenshots.
- Hold Command, Option, Control or Shift from a mouse button or key.
- Insert text, mouse clicks and scrolling, or do nothing to switch a key off.
- Windows: halves, quarters, fill, center, move to the next display, close, minimize, full screen, next and previous window.
- Apps and system: open, activate or quit an app, previous app, open a file, folder or web address, Apple Shortcuts, Mission Control and desktops, volume, media keys, display brightness, sleep and lock.
- Rebind itself: pause, next and previous profile.

**Everything else**

- Named profiles with manual selection; duplicate a binding, copy it to another profile, give it a note; export and import single profiles or a full backup.
- Bindings for all apps or for one app, which then replaces the general binding with the same trigger there.
- Excluded apps, such as games and virtual machines, with bindings and smooth scrolling switched off separately.
- Reverse vertical and horizontal scrolling separately, speed up the wheel, smooth scrolling set per mouse, adjustable mouse gesture distance.
- Logitech mice: SmartShift wheel mode and sensitivity, pointer resolution (DPI), high-resolution wheel, battery charge, and the gesture button as a trigger; kept per model and restored when the mouse connects; a warning while a vendor app such as Logi Options+ or G HUB may take over the mouse.
- Automatic backups of the last 10 different configurations loaded at launch, plus full export/import and individual profile files.
- Runs from the menu bar with a paused state you can see, optional Dock icon, launch at login and an emergency pause shortcut.
- Updates through [Sparkle](https://sparkle-project.org): Rebind checks once a day (or on **Check for Updates**), shows what changed and asks before installing a signed update.
- English, Russian, German, French, Spanish and Simplified Chinese.

Profiles apply to input categories rather than individual physical devices. Not available: Caps Lock and Fn remapping, Magic Mouse swipes/holds, trackpad swipes, pinch and rotation, and the Logitech thumb wheel as a trigger (it scrolls sideways as usual). Trackpad and Magic Mouse touch capture rely on a private macOS interface and are experimental; macOS gestures stay active, so the system may respond to the same tap. Much of the feature set is verified by automated tests only; see the [capability matrix](docs/CAPABILITIES.md) for what has been tried on real hardware.

## Requirements

- macOS **15 or later**.
- Full Xcode with a **Swift 6.2+ compiler** and a **macOS 26+ SDK** to build from source.
- The Accessibility permission, which Rebind asks for on first launch.

Rebind is a universal app. It has been run on Apple silicon with macOS 27 and in a macOS 15 virtual machine, where the app and keyboard and mouse bindings work. Trackpad and Magic Mouse gestures on macOS 15, macOS 26 and Intel Macs have not been tested yet.

## Install

Rebind is signed by the maintainer but **not notarized by Apple**, so macOS blocks the first launch until you allow it. The "Source code" archives on the Releases page are not installers; download the DMG.

1. Download [Rebind.dmg](https://github.com/Blinks44/rebind/releases/latest/download/Rebind.dmg) from the latest release and open it.
2. Drag **Rebind** onto the **Applications** folder, then open it from there. macOS shows a warning that it could not verify the app; close the warning.
3. Open **System Settings → Privacy & Security**, scroll down to the message about Rebind and click **Open Anyway**, then confirm.
4. Rebind opens and guides you through the one permission it needs, **Accessibility**.

Later versions arrive through the built-in updater. If macOS asks for Accessibility access again after an update, turn Rebind off and on in that list. See also [Apple’s first-launch instructions](https://support.apple.com/en-us/102445).

If you would rather not trust a prebuilt app, build it yourself from this repository (below).

## Build and run

From the repository directory:

```sh
apps/rebind/scripts/dev.sh doctor
apps/rebind/scripts/dev.sh run
```

`doctor` reports the selected toolchain and project targets. `run` builds Debug and opens `Rebind.app`. The script selects full Xcode per process without changing your system's `xcode-select` setting.

Alternatively, open `apps/rebind/rebind.xcodeproj` in Xcode, select the **rebind** scheme and run with **⌘R**. Local development builds can use **Sign to Run Locally**; rebuilds may require renewing macOS permission grants.

To build a Release app:

```sh
apps/rebind/scripts/dev.sh release
```

The result is `apps/rebind/build/DerivedData/Build/Products/Release/Rebind.app`. To package a release for other people, use `apps/rebind/scripts/release.sh` (see the development guide). See the [development guide](docs/DEVELOPMENT.md) for toolchain overrides, tests and signing details.

## First launch

1. Open Rebind. New configurations start paused with no bindings.
2. Follow the first-run guide (or **Settings → Permissions**) to open **System Settings → Privacy & Security → Accessibility** and turn on Rebind. Relaunch it if macOS asks.
3. If Accessibility is on but Rebind still cannot send events, choose **Allow Event Sending** and check the status again.
4. Pick an input category, add a binding with a trigger and an action, save it and turn bindings on.

For example, map **Control + Mouse Button 4 → Command+A** or assign a long press on an extra mouse button to a shortcut. Unmatched inputs retain normal system behavior.

Pause from the menu bar whenever needed. While bindings are on, **⌃⌥⇧⌘ Escape** pauses them immediately. Rebind does not need Input Monitoring; the few actions that need another permission explain it where you set them up.

## How it works

The selected profile supplies the active bindings. A global Quartz event tap captures supported keyboard/mouse input and a bounded matcher decides whether to pass it through or trigger an action. Actions run separately from the synchronous event callback; synthesized events are tagged to prevent feedback loops. The experimental trackpad path uses an isolated private multitouch adapter.

Configuration is stored locally at `~/Library/Application Support/Rebind/configuration.json` using versioned JSON and atomic writes. Rebind does not keep a history of what you type. Text you deliberately save in an Insert Text action is part of your unencrypted local configuration and backups; do not store passwords there. Secure Input and permission/lifecycle checks guard recording and dispatch.

Input processing makes no network requests and sends no analytics. The update check downloads the public appcast from GitHub Releases once a day (turn it off in **Settings → General**) or when you choose **Check for Updates**; it sends no bindings, input, device or system data. Opening a website or running an Apple Shortcut follows the action you configure.

## Technology

| Area | Stack |
| --- | --- |
| Language and UI | Swift 6 language mode, SwiftUI, AppKit, Observation |
| Input | Core Graphics / Quartz Event Services, owned Core Foundation run loop |
| Actions | Accessibility, NSWorkspace, Core Audio, IOKit, native Shortcuts CLI |
| Mice | IOKit HID, Logitech HID++ 2.0 through the vendored HIDPP package |
| Storage and localization | Codable/JSON, atomic local files, String Catalogs |
| Tests | Swift Testing with an Xcode-hosted test target |
| Build and assets | Xcode, SF Symbols, Sketch, Icon Composer |

The app uses two Swift packages: [Sparkle](https://sparkle-project.org) 2.10.0 for updates and the vendored local `HIDPP` package (`apps/rebind/Packages/HIDPP`). Some experimental trackpad/Dock/lock paths and the high-resolution wheel adjustment use private macOS APIs and may break after macOS updates. [Third-party notices](apps/rebind/rebind/Resources/ThirdPartyNotices.txt) document credited sources.

## Acknowledgements

Rebind builds on the work of these open-source projects. Each is credited with its license in [ThirdPartyNotices.txt](apps/rebind/rebind/Resources/ThirdPartyNotices.txt), which the app also shows under About.

- [Sparkle](https://github.com/sparkle-project/Sparkle) (MIT): signed in-app updates.
- [LinearMouse](https://github.com/linearmouse/linearmouse) (MIT): the vendored `HIDPP` package for Logitech HID++, the approach of the smooth scrolling glide, and scaling the HID event attached to a scroll event so that reversing works on high-resolution wheels.
- [Solaar](https://github.com/pwr-Solaar/Solaar) (GPL-2.0): its HID++ feature documentation informed the SmartShift and device name payloads. Reference only; no code was copied.
- [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) (MIT): media key events, the screen lock entry point and window raising were checked against it.
- [spacekit](https://github.com/cehbz/spacekit) (MIT): the Control+Arrow events for switching desktops.
- [Sanne](https://github.com/anandghegde/sanne) (MIT): the corner regions for one-finger corner taps.
- [Subsurface](https://github.com/mrkai77/Subsurface) (Apache-2.0): the private multitouch signatures and contact layout used by the trackpad adapter were compared with it.

## Documentation

- [User guide](docs/USAGE.md): setup, everyday examples, conflicts and recovery.
- [Release guide](docs/RELEASING.md): versioning, signed DMG, GitHub assets and website publication.
- [Development guide](docs/DEVELOPMENT.md): build, tests, signing and detailed local setup.
- [Capabilities](docs/CAPABILITIES.md): implementation status, verified subsets and limitations.
- [Specification](docs/SPEC.md) and [roadmap](docs/PLAN.md): product requirements and remaining work.
- [Documentation index](docs/README.md): design, architecture conventions, verification and contributor/agent workflow.
- [Contributing](CONTRIBUTING.md), [security policy](SECURITY.md), [code of conduct](CODE_OF_CONDUCT.md) and [changelog](CHANGELOG.md).

## Author

Rebind is made by Sergey V. Follow [@TheBlinks182 on X](https://x.com/TheBlinks182) for updates and new releases.

## License

Rebind is released under the [MIT License](LICENSE): you may use, change and redistribute it, including in forks, as long as the copyright notice and the license text stay with every copy. Bundled third-party notices are in [ThirdPartyNotices.txt](apps/rebind/rebind/Resources/ThirdPartyNotices.txt).
