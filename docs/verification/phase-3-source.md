> **Retired — user decision 2026-10-08.** This inventory/source experiment and its tests/UI were removed. Historical evidence below is retained for engineering context, not a current feature or pending walkthrough. Use [manual profiles](profiles.md); do not resume source-attribution work without a new explicit request.

# Phase 3 experimental mouse source check — 2026-10-08

Scope: SPEC §§3.2–3.3, 6–7, 9, 12; D1/D2 and S1/S2/S3.
Status: implemented diagnostic probe; software tests and Russian empty-state UI
checked. Real source identity, mouse-to-interface association and per-device rules
are **not verified or implemented**.

## Contract and limits

- Open **Input Diagnostics**, enable **Experimental mouse source check**, then
  explicitly Start. Opening alone does not collect; the checkbox starts off on
  every sheet presentation and cannot change an active session. No setting is saved.
- **Sender ID** shows only the current event's raw numeric sender in hexadecimal.
  Unknown means missing private symbols, no underlying HID event, or sender zero.
  A dash means no source lookup was requested, including derived hold/motion rows.
  There is no fallback to last active device, product name or timestamp proximity.
- The existing Quartz interception callback supplies the sampled event. Only button
  down/up/drag and wheel samples are eligible. Keyboard events/codes/text, idle
  pointer motion, coordinates, HID reports and tagged Rebind feedback are excluded.
  Data stays in the bounded in-memory diagnostic ring, never rules/files/console.
- The same 128-row ring, 20 samples per second window and 60-second session apply.
  Underlying event copying is skipped when the sampling quota/session is exhausted.
  Stop retains rows; Clear preserves quota/deadline. Close, Secure Input, capture or
  permission loss, suspension and shutdown stop/erase the session. Source collection
  never enables remapping or changes matcher resolution, suppression or output.
- A worker-owned adapter resolves `CGEventCopyIOHIDEvent` and
  `IOHIDEventGetSenderID` outside the callback; Copy ownership is balanced. These are
  **private APIs with no supported compatibility/ABI guarantee**. Their presence
  is checked dynamically; absence produces Unknown without a launch dependency.
  The opt-in mode performs an unavoidable bounded native copy synchronously;
  hardware callback latency and compatibility on macOS 26 remain unverified.
- Public CGEvent source process/user/state fields are not HID device IDs. CoreHID
  discovery does not supply a documented join key for this Quartz source. An ID
  could identify a service/receiver/transformed source rather than a physical mouse,
  and may differ from **Devices** connection IDs. No direct equality, stable identity,
  keyboard routing or wireless receiver subdevice association is assumed.

## Evidence

- Xcode 27.0 / Swift 6.4 / SDK 27.0, Apple Silicon macOS 27.0.1 (26A434).
  Deployment 26 retained; no Intel/macOS 26 execution claim.
- Standalone native metadata probe resolves both symbols on this host; a constructed
  mouse event has no sender. This does not test physical input attribution.
- `scripts/dev.sh test -resultBundlePath build/Phase3MouseSourceTests-Final.xcresult`:
  **180 tests / 27 suites / 0 failures**. Eight new test functions cover opt-in,
  source stripping, extraction quota/deadline/clock regression, unknowns, keyboard
  and feedback exclusion, unchanged category rules/down-up ownership, protected
  clearing, unsupported wheel/derived hold metadata and constructed native events.
- Debug and universal Release builds pass. Russian panel's default toggle, hint,
  source column, permission gating, empty state and Escape inspected; the rebuilt
  inspection copy has no AX/post grants. Existing three rules are loaded/paused.
  No real source collected, rules saved/toggled or permissions granted by the agent.
  Other language layout, full VoiceOver and active populated source UI remain open.

Research and dependency decisions, command logs and build validation are in PLAN.
The normal [diagnostic contract](phase-2-diagnostics.md) remains the default.

## User walkthrough

1. Run one rebuilt Xcode copy (⌘R), check its existing remapping permissions, keep
   rules paused initially. Open diagnostics, enable the experimental checkbox and
   Start. Record which physical mouse you are using, its transport and driver.
2. On G603, click/release middle and both side buttons and turn the wheel. Report
   Sender IDs for down/up and wheel, or Unknown. Repeated same-device events should
   not silently borrow another sender. A derived hold activation with a dash is normal.
3. With a second actual mouse connected at the same time, click/release the **same
   button** on each in alternation and scroll each. Compare sender IDs. Also try
   holding a button on one while clicking the other. Different/stable IDs are only
   preliminary evidence; identical/unknown values must leave per-device routing off.
4. Stop before disconnecting the G603 receiver; verify inventory disappearance
   (already user-confirmed). Reconnect, start a new explicit source session, check
   IDs again and inventory deduplication. Changing IDs are not persistent identities.
5. Test existing ordinary, 1000 ms hold and leftward rules in disposable TextEdit
   with source collection on/off. Check no duplicate output, changed timing,
   click-through or stuck source ownership. Report any difference and leave the
   experimental checkbox off if it interferes.
6. Stop/Clear/60-second idle expiry, close/reopen, sleep and loss of capture should
   behave like normal diagnostics, with no automatic collection restart. Do not
   supply passwords or typed text. High-polling performance and all fault paths
   remain hardware gates.

Next implementation depends on verified source-to-interface/physical-device
association. This probe does not expose a device selector or persist device rules.
