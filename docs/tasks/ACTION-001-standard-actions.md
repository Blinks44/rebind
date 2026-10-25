# ACTION-001: More standard actions in the shared catalog

- Updated: 2026-10-24
- Stage: planned
- Owner: unassigned
- Ownership checked: 2026-10-24 on `main` after `f961b3b`
- Owned surfaces: `Actions/ActionKind.swift`, `Model/MediaAction.swift`, `Actions/CoreAudioOutput.swift`, action editor catalog, `Localizable.xcstrings`; Sketch only if the catalog menu specimen needs new groups
- Requirements: SPEC §5 (A1/A2), §11
- Code baseline: `main` at `f961b3b`; no code changed

## Outcome and scope

Add simple, reliable actions the catalog still lacks (review 2026-10-24 against `ActionKind`):

- Named fixed shortcuts, same mechanism as Copy/Paste and stated in the editor: Spotlight (⌘Space), Force Quit window (⌥⌘Esc), Emoji & Symbols (⌃⌘Space), Show/Hide Dock (⌥⌘D), Hide Others (⌥⌘H), Look Up (⌃⌘D), and front-app commands Quit (⌘Q), New Window (⌘N), Find (⌘F), Reload (⌘R), Save (⌘S). Spotlight/Emoji depend on macOS shortcut settings; the editor says so.
- Apps (the macOS 26 Launchpad replacement): opens `/System/Applications/Apps.app` (present on macOS 27.0.1; Launchpad.app is absent).
- Fast-forward / Rewind media keys (`NX_KEYTYPE_FAST` / `NX_KEYTYPE_REWIND`).
- Toggle microphone mute on the default input device via Core Audio, hidden when the device has no settable mute.

Not in scope (user decision 2026-10-24): audio output cycling, display sleep, move to previous display, window size restore; Notification Center, Control Center, Stage Manager, Focus and Dark Mode (no public API; Run Shortcut already covers them).

## Acceptance

- [ ] Each new entry has a real execution path, availability gating and the existing error reporting (A1); no feedback loop (A2).
- [ ] Schema/migration handled if stored payloads change; older files keep loading.
- [ ] Six-language names and editor descriptions; catalog search finds them.
- [ ] Tests for mapping/encoding and microphone availability; full `dev.sh test`; build bump and `release.sh` package; hardware check of each action on the user's Mac.

## Next handoff

Code: add the fixed-shortcut entries first (lowest risk), then Apps, the two media keys and microphone mute.
