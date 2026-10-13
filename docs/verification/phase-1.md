# Phase 1 verification

Scope: SPEC §§2, 3.1–3.2, 4, 5 (shortcut output), 6–9, 11–12;
K1/K2, M1/M2, R1, A2, S1/S2/S3. These walkthroughs are **pending**
unless a result is explicitly recorded below.

## Observed in this session

Host: macOS 27.0.1 (26A434), Apple Silicon, Xcode 27.0 / Swift 6.4.
The exact Debug bundle at `build/DerivedData/Build/Products/Debug/Rebind.app`
was launched and inspected through native accessibility and screenshots.
Russian main window, keyboard/mouse categories, permission guidance, empty
list, add-binding sheet, disabled recording/save without permissions and
Escape cancellation were observed. Closing the window left the same app
process running. No Accessibility or Input Monitoring grants were given;
no global tap, physical remap or injected action was manually verified.

## User hardware result: 2026-10-08

After the event-posting consent correction, the user confirms the permission flow
works and records Logitech G603 middle **Mouse Button 3**, sides **Mouse Buttons
4 and 5**. Transport: LIGHTSPEED; G HUB installed. This establishes real mouse
recording for those controls, not external shortcut delivery or source suppression.
The current UI conversion implies Quartz indexes 2/3/4; HID usages and per-device
attribution have not been measured. No button beyond #5 was reported.

The user subsequently confirmed Control + Button 4 → Command+A works in TextEdit
and plain Button 4 retains its previous behavior. This meets the minimum external
remap evidence on the tested G603 setup. Physical keyboard, held/repeated source,
release symmetry, original-event leakage, pause/restart/background and protected
contexts still need the full walkthrough; Phase 1 is not entirely verified.

## Supported implementation subset

- Category-wide physical ordinary key, middle/extra mouse button, exact
  Command/Control/Option/Shift set → one balanced shortcut pulse per press.
- Quartz button index + 1 is the human-readable button label; Button 4 is
  index 3. There is no fixed maximum button enum. Only events actually
  delivered by Quartz can be recorded. Primary/secondary buttons are deferred.
- Repeats and drags belonging to a suppressed press are swallowed until
  release. Long-press activation is described in the [hold walkthrough](phase-2-hold.md).
  Held output, modifier-only keys, Caps Lock, Fn, click counting,
  gestures are deferred. Wheel support is described separately in the
  [Phase 2 walkthrough](phase-2-wheel.md). Events carrying the secondary-Fn flag
  pass through rather than matching a chord with that flag silently removed.
- Output uses a private CGEventSource and explicit modifier flags on key
  down/up, without synthesizing modifier key-downs. It therefore owns no
  long-lived synthetic held states. Verify recipient behavior with physical
  modifiers held; consumers requiring modifier transitions may differ.
- The tap runs on a dedicated CF run loop; a queue capped at 16 outputs is
  drained between callbacks (up to roughly 20 ms handoff delay under normal
  load). Overflow passes the source through. No latency/load claim is made.
- A disabled tap fails open and requires deliberate retry. Permissions are
  checked periodically. Secure Input suspends interception/output; no typed
  string, clipboard or Unicode payload is read from incoming events.
- Editing suspends mappings. Recording is explicit, cancels on Escape or
  app deactivation, and never executes an output shortcut while recording.
- New configurations start paused. Atomic version-4 JSON (reading versions 1/2/3) lives at
  `~/Library/Application Support/Rebind/configuration.json`. An unreadable,
  invalid or future-version file is preserved and locks editing. Recovery
  controls, further migrations and import/export remain Phase 7 work.

## Physical walkthrough to finish Phase 1

Record Mac model, OS build, keyboard/mouse model and connection, OEM driver,
signing identity/bundle path, keyboard layout, permission states and results.
Use a disposable document in a foreground application such as TextEdit.

1. Grant Rebind Accessibility using its permission UI. A separate Input Monitoring
   grant is not required by the current active Quartz tap; see [the correction](permissions.md).
   Return and refresh; relaunch if macOS asks. Check actual status, not the
   fact that a button was clicked. Keep the same signed bundle/launch path.
2. Record Control+Option with an ordinary physical key; record Command+A
   as output, save, and enable bindings. In the disposable document, verify
   one Select All action and no leaked source event. Check the configured
   chord, plain key, an extra Shift modifier, opposite modifier press order,
   held source/repeat, rapid presses, and changed physical modifier order.
3. Record Control+Mouse Button 4 → Command+A. Verify mapped down/drag/up
   suppression, one output, and normal behavior of unmapped plain Button 4.
   Repeat with another observable button above Button 5, if present.
4. Pause while holding a mapped source, release it, resume, and use normal
   keyboard/mouse input. Check menu-bar Pause, emergency ⌃⌥⇧⌘ Escape, and
   quit. Verify no leaked release, extra output or stuck state.
5. Close the main window while enabled, test mapping in the foreground app,
   and reopen with Open Rebind in the menu bar. Quit/relaunch and verify rules
   and global enabled state reload. Closing-window process survival alone
   does not prove background remapping.
6. Revoke permissions, test passthrough and visible status, restore them and
   retry. Test Secure Input/password focus without collecting or logging
   password content, tap disable, sleep/wake and session lock/unlock.
7. Switch keyboard layout; physical codes must remain stable and labels must
   follow the selected layout. Check physical source modifiers do not alter
   output flags or become stuck. Verify menu bar and editor with keyboard
   navigation/VoiceOver; check EN/DE/FR layouts separately.

No real trackpad, Magic Mouse or two-device attribution result follows from
this slice. Do not advance Phase 1's end-to-end exit criterion on unit tests.
