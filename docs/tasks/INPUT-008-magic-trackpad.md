# INPUT-008: External Magic Trackpad section

- Updated: 2026-10-13.
- Stage: `awaiting_verification`.
- Owner: Released (code agent, 2026-10-13 session).
- Requirements: SPEC §3.4 (Magic Trackpad verified separately), §10; user request 2026-10-13: the same functionality as the built-in trackpad with its own sidebar entry.
- Code baseline: `main` `64dadc3`; uncommitted on top; no agent commit.

## Outcome and scope

A **Magic Trackpad** sidebar section with its own rules list. It offers the same twelve gesture presets, action catalog and editor as the built-in trackpad. A rule belongs to one surface: the same gesture can do different things on the built-in and the external trackpad. This is a category of input, not physical-device inventory: any connected external trackpad-shaped surface is "the Magic Trackpad"; no names or serial numbers are read.

## Implementation

- `DeviceScope.magicTrackpad`; trackpad triggers are valid in either trackpad scope. `MatchKey.isMagicTrackpad` keeps the two rule sets apart. Schema **32** guards older files.
- `NativeTrackpadDevice` loads the private framework once and serves two kinds. The built-in adapter is unchanged in behavior. The Magic Trackpad adapter picks the first external surface that is wider than tall (a Magic Mouse is taller than wide), identified by its multitouch device ID; a device that disconnects is retired, and a reconnecting one gets a new adapter.
- `TrackpadCapture` runs one independent pipeline (device, session, revision) per surface and rescans for the external device every 2 s while its rules exist.
- `TrackpadRuntime.isMagicTrackpad`, `trackpadRuntime(magicTrackpad:)`, a second `TrackpadClickFilter`; a click is resolved by the surface whose fingers explain it.
- UI: sidebar entry (`hand.tap`), list title, editor scope caption; strings in EN/RU/DE/FR. Sketch: the sidebar item on every screen and screen 21 (Light/Dark).

## Verification

Agent-observed 2026-10-13, macOS 27.0.1 / Xcode 27, software evidence only: new `MagicTrackpadTests` (separate rules per surface, spoofed surface refused, click resolved by the surface holding the fingers, scope validity and schema guard); complete suite passes. All nine private symbols, including `MTDeviceGetDeviceID` and `MTDeviceCreateList`, resolve on this system and the built-in device reports a non-zero ID. **No Magic Trackpad was connected**: discovery, the wider-than-tall rule, contact frames, reconnection and every gesture are unverified on hardware.

## Open checks

- [ ] Built-in trackpad still works after the adapter refactor (regression on hardware).
- [ ] Magic Trackpad is found within ~2 s of connecting; all preset groups work; rules of the two surfaces stay separate.
- [ ] Disconnect/reconnect, sleep/wake, and a Magic Mouse connected at the same time (must not be taken for a trackpad).
- [ ] Tap to click and click rules on the external surface, including its Force Touch click behavior.

## User follow-up — 2026-10-19

User reports the external trackpad tested and working like the built-in one, with overall behavior satisfactory. Exact artifact, model/settings and a preset-by-preset matrix were not supplied. This confirms the exercised general external behavior; remaining specifically enumerated timing/reconnect/sleep/click-safety/platform checks above are not automatically closed. Do not ask to repeat the entire external smoke pass.

## Next handoff

Retain the supplied general external-trackpad acceptance; focus on the remaining named checks only if affected or required for final release. Keyboard-navigation repair is UI-024; bounded gesture additions are INPUT-015.
