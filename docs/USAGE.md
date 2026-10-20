# Using Rebind

Rebind assigns actions to keys, mouse buttons and supported touch gestures. It runs locally and keeps working when you close its window. The current touch features are experimental; see [supported subsets and limits](CAPABILITIES.md).

## Start with one binding

1. Install the app in Applications and open that copy. For a downloaded build blocked by macOS, follow [first-launch instructions](../README.md#install).
2. Allow Rebind in **System Settings → Privacy & Security → Accessibility**. Return to Rebind and check the status. If event sending is still unavailable, choose **Allow Event Sending** and follow the displayed instructions.
3. Choose **Keyboard**, **Mouse**, **Trackpad**, **Magic Trackpad** or **Magic Mouse**. The two trackpad categories have independent bindings.
4. Choose **Add Binding**. Record a key/shortcut or middle/extra mouse button. For a touch device, select a complete gesture. Recording a trigger or output shortcut does not run its action. Escape cancels recording.
5. Choose an action, complete any required fields, save, and enable bindings. New configurations start paused.

A binding works in all apps unless you select one in the editor. An app-specific binding replaces an all-app binding with the same trigger while that app is in front. Profiles switch manually; naming a profile after a mouse does not restrict it to that mouse.

## Useful starting points

- **Control + Mouse Button 4 → Select All** leaves plain Button 4 unchanged.
- **Button 4 + Wheel Up/Down → Increase/Decrease Volume** changes volume while the button is held. A click without scrolling still works normally.
- **Control + Option + Left/Right Arrow → Left/Right Half** moves the active window. Some apps restrict window sizes; full-screen windows must leave full screen first.
- **Three-finger Magic Mouse click → Middle Click** replaces that physical click. Rest three fingers on the surface and press; it is different from a light tap.
- A keyboard **Hold** binding can send one shortcut on a short press and run its chosen action after the hold threshold. Use its **Short press** field. Do not create separate press/double/hold bindings for the same input: they conflict.

## Taps, clicks and macOS gestures

A **tap** is a light touch followed by lifting your fingers. A **click** physically presses the surface. Trackpads have 12 presets per category. Magic Mouse has six: one/two/three-finger taps, three-finger click and two-finger scroll up/down. There are no swipe, pinch or rotation presets.

Touch capture uses a private macOS interface and may change after system updates. Overlapping macOS gestures can also respond. Rebind explains the relevant setting; change it yourself or choose another gesture. It never changes system gestures automatically. Magic Mouse scroll directions follow your fingers, independently of Natural Scrolling. A recognized stroke performs one action instead of scrolling; unclear starts retain native scrolling.

## Pause and recover

Choose **Pause** in the Rebind menu or turn bindings off in the window. While input capture is active, **Control + Option + Shift + Command + Escape** is the emergency pause shortcut. Pausing keeps your rules. If both app icons are hidden, open Rebind from Applications or Spotlight to reach its window.

If a binding does not work:

1. Check that bindings are on, the correct profile is selected, and the binding is enabled for the app in front. Check **Settings → Input → Excluded Apps**.
2. Check **Settings → Permissions**. Enable the running Rebind copy and reopen it if macOS requests that. Password fields can enable macOS Secure Input; leave the field before testing again.
3. For a mouse, check **Settings → Devices** for a competing vendor app. Quit that app and retry if it controls the same buttons. Available settings and battery readings depend on the model and connection.
4. For touch, reconnect the device, lift all fingers, and allow capture to start. Check the native gesture guidance. A disconnected device’s saved rules remain editable.
5. If needed, use **Settings → Advanced → Copy Report** and [report a bug](https://github.com/Blinks44/rebind/issues/new/choose) with steps, version/build, macOS and device model. Do not post your configuration or backups publicly. [Security problems need a private report](../SECURITY.md#reporting-a-vulnerability).

## Backups, updates and privacy

**Settings → Advanced** exports/imports a full backup. Import and reset ask before replacing current data; imported bindings start paused. Export a backup first. Profiles can also be exported/imported individually. **Show Backups** reveals up to 10 different configurations loaded at launch; these are local recovery copies, not an off-device backup or a daily schedule.

**Rebind → Check for Updates** checks GitHub only when selected. It opens the release page on request; download the DMG, quit Rebind and replace the app in Applications. It does not install updates itself. macOS may ask for first-launch approval or renewed access after a signing change.

Rebind does not keep a typing history or send analytics. Settings and rules stay on your Mac. Text you deliberately save in **Insert Text** is stored unencrypted in the configuration and its backups: do not use it for passwords. User-configured web/Shortcuts actions may access the network; the manual update check sends no rule, input or device data.
