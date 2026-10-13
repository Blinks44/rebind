# INPUT-009 — Held output, excluded apps, wider action catalog and rule management

- Updated: 2026-10-13.
- Stage: `awaiting_verification`.
- Owner: Released (code agent, 2026-10-13 session).
- Requirements: SPEC §§2, 3.3, 4, 5, 9 (additions dated 2026-10-13).
- Code baseline: `main` `99b2ad6`; uncommitted on top; no agent commit.

## Outcome

User request 2026-10-13, after a feature-gap review: implement the proposed missing standard functionality. One schema step (**34**) carries all of it.

- **Held output.** A press rule on a key or mouse button can "Repeat While Held": a keyboard shortcut is one key-down, repeats at the system key-repeat rate and one key-up on release; volume, brightness and scroll actions repeat through the ordinary queue. Up to four outputs can be held at once; a tap released before the worker runs becomes one ordinary pulse.
- **Excluded apps.** Settings → Input lists apps in which Rebind leaves all input alone while they are in front (keyboard, mouse and trackpad). Pause state is unchanged; the emergency chord still works.
- **Catalog.** Do Nothing, Pause Rebind, Next/Previous Profile; Copy, Paste, Cut, Undo, Redo, Select All; Insert Text; Next/Previous/New/Reopen Tab, Zoom In/Out; three screenshot commands; top/bottom halves, four quarters and Move Window to Next Display.
- **Rules.** Duplicate a rule, copy it to another profile, and give it a note that replaces the category caption and is searchable.
- **Wheel under a held button.** A new mouse input type, Button + Wheel: hold a middle or extra button and turn the wheel; the rule runs on every wheel step (shared 100 ms limit). Using the wheel means the hold is neither a click nor a gesture; a hold without the wheel is still the button's click, even after movement when the button has no gesture rules.
- **Settings and feedback.** Mouse gesture distance (short 30 / standard 50 / long 90 points) replaces the fixed threshold; the Menu Bar menu shows the last action error.

## Implementation notes

- `HeldOutput` state lives in the mailbox. Every path that already cleared the queue (configure, pause, edit, record, suspend, capture loss, Secure Input, system transition, stop, excluded app in front) marks a pressed key released; the worker posts that release before its Secure Input/permission guards, and again after its loop and in `AppModel.stop()`. A key that was never pressed is dropped without output. A button that also has pointer gestures cannot hold an output (same ambiguity rule as hold/double press).
- Exclusion is `State.isMatching` (`enabled` and not in front of an excluded bundle identifier), fed from `NSWorkspace.didActivateApplicationNotification` on the main actor. The tap callback reads one extra field under the lock it already takes.
- Named commands are `ActionKind.fixedShortcut` entries stored as ordinary `.shortcut` actions, so they need no migration; recording the same chord by hand shows the command's name.
- Insert Text posts tagged Unicode key events built before any is posted, at most 20 UTF-16 units each and split on character boundaries. Text is user-authored configuration (1–500 characters, no control characters) stored unencrypted; the editor says so. It is blocked under Secure Input like every other output.
- Pause from a rule reuses the emergency-pause path; profile steps are applied by `AppModel.refresh`, which owns storage.

## Verification

Agent-observed 2026-10-13, macOS 27.0.1 / Xcode 27: `apps/rebind/scripts/dev.sh test` passes with 732 Swift Testing tests in 102 suites, including new suites `ControlActionTests`, `HeldOutputTests`, `ButtonScrollTests`, `ExcludedApplicationTests`, `CatalogActionTests` and `RuleManagementTests` and extended window-layout geometry/executor tests. Injected and pure tests only: the app was not launched and no synthetic input was posted to the system.

## Open checks

- [ ] Running app: every new control (hold toggle, note field, excluded-apps card, gesture distance, copy-to-profile menu) in Light/Dark and all six languages; none has been seen rendered.
- [ ] Held shortcut on hardware: arrows/Delete repeat, a game or push-to-talk hold, release after pause, sleep, lock and quitting Rebind while held.
- [ ] Excluded app: switch into and out of a listed app with keyboard, mouse and trackpad rules; full-screen games.
- [ ] Insert Text in native, Electron and terminal apps; non-Latin text and emoji.
- [ ] Named commands, screenshots, quarters and Move to Next Display (two displays) on hardware.
- [ ] Translations of the new strings (DE/FR/ES/Simplified Chinese) by fluent readers.
- [ ] Wheel under a held button on hardware: G603 side buttons with volume or tab actions, free-spinning wheels, click after an unused hold.
- [ ] Copy review 2026-10-13 was done by the agent, not by fluent readers; the German, French, Spanish and Chinese wording still needs one.
- [x] Sketch screens 29–33 (Light/Dark), saved 2026-10-13: Button + Wheel editor, Repeat While Held with the note field, Input settings with gesture distance and excluded apps, Insert Text, and the binding options menu. Open: the Insert Text action shows a placeholder icon because `text.cursor` is not yet in the Sketch icon set.

## Not done from the same review

Update check (waits for the GitHub repository, PLAN item 4), a click under a held button, trackpad presets with modifiers, modifier-only and dual-role keys, haptic feedback, a paused Menu Bar icon (needs a drawn asset), starter rule sets, single-profile export, diagnostics report, triple press and scroll/pointer tuning.

## Next handoff

User: try the new rule options on the built app and report what works. Code agent: "continue the feature-gap work" resolves to the list above. Design agent: the remaining undrawn states are listed in Open checks.
