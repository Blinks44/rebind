> **Retired — user decision 2026-10-08.** This inventory/source experiment and its tests/UI were removed. Historical evidence below is retained for engineering context, not a current feature or pending walkthrough. Use [manual profiles](profiles.md); do not resume source-attribution work without a new explicit request.

# Phase 3 HID inventory — 2026-10-08

Scope: SPEC §§3.2–3.3, D1/D2, 6–7, 10–12.
Status: implemented metadata discovery; native enumeration and Russian UI/Refresh
inspected on macOS 27.0.1. The user confirms receiver disappearance on unplug;
reconnect and individual button capabilities remain unverified. No per-device rules or touch gestures enabled.

## Contract

- **Devices** in the sidebar shows live HID interfaces matching keyboard/keypad,
  mouse/pointer or trackpad usages. Public CoreHID delivers connection/removal
  notifications. Discovery runs once per application lifetime, independent of
  window closure and the Quartz engine; Refresh cancels/restarts discovery.
- Names/manufacturer, VID/PID, transport and connection ID come from the native
  interface metadata. Missing names have a localized fallback. Duplicate match
  notifications replace metadata for the same live ID. Identical models and
  separate interfaces remain separate; removed interfaces disappear from the list.
- A wireless receiver can expose mouse and keyboard interfaces and hide its mouse
  model. A connected receiver does not prove its wireless mouse is switched on.
  Trackpad classification requires explicit HID usage/collection metadata; a name
  alone does not enable trackpad or Magic Mouse gestures.
- Declared HID button usages come from individual input-element metadata when
  available, with public IOKit registry element descriptions as a fallback. Sparse
  IDs above #5 are supported. Output/feature/collection elements and array selectors
  are not presented as individual input buttons. Collection-only, absent or empty
  descriptions are **unknown**, not “0 buttons”. Complete input-element metadata
  without button usages can report that no button usages are declared.
- HID usage numbers are not Quartz button codes and do not guarantee remappable
  events. The existing recorder/diagnostics verifies actually delivered input;
  no button picker or attribution is inferred from this inventory.
- Connection IDs are transient interface identifiers, not persistent physical
  identities. No serial numbers or inventory files are collected. Discovery never
  changes bindings, their schema or global enabled state; only category-wide rules
  remain available. Stream failure clears stale connected rows and exposes Retry.
- No explicit device-open/seize calls, input subscription, report/value requests, event
  synthesis, permission request, binary report-descriptor parser, private API,
  extra tap, helper or third-party package. Metadata work runs outside MainActor;
  the synchronous event callback is unchanged. Stop/cancellation rejects stale
  updates and releases the owned native monitor.

## Evidence

- Xcode 27.0 / Swift 6.4 / SDK 27.0; Apple Silicon macOS 27.0.1 (26A434).
  Deployment 26 retained; no macOS 26/Intel runtime claim.
- Metadata-only native probes and app UI show six interfaces: Apple Internal
  Keyboard / Trackpad keyboard and pointing/trackpad interfaces, plus mouse and
  keyboard interfaces for Logitech USB Receiver **046D:C539** and **046D:C545**.
  Neither product ID has been independently tied to the user's G603 here.
- Individual CoreHID elements are empty, IOHID matching elements nil, public registry
  element descriptions collection-only on the inventoried host. Cause unconfirmed;
  no extra access requested. The UI correctly reports unknown button descriptions.
- Russian native Debug screen renders live metadata and explanations; Refresh
  produces six rows again without duplicates. Existing three mouse rules remain
  loaded/paused; inspection copy has no AX/post grants. The viewer works without
  those grants. No physical unplug/replug, gesture capture or output performed.
- `scripts/dev.sh test -resultBundlePath build/Phase3HIDTests-Final.xcresult`:
  **172 tests / 26 suites / 0 failures**, including 13 new pure metadata/catalog tests.
  These validate descriptor filtering, unknowns, sparse IDs, nesting, duplicate
  matches/models, reconnect identity separation, clearing and label bounds. They
  do not validate the native stream, real disconnect or actual remappable buttons.
- Final `scripts/dev.sh build` and `scripts/dev.sh release` succeed; Release contains
  arm64/x86_64, strict/deep signature verification and privacy/project lint pass.
  Logs `/tmp/rebind-hid-{doctor,tests-final,build-final,release-final}.log`; test
  result `build/Phase3HIDTests-Final.xcresult` is ignored. PLAN records research,
  known system warnings, translation validation and remaining checks.

## User hardware result — 2026-10-08

The user reports that the inventory works correctly and the receiver disappears
when unplugged, using the previously reported G603 LIGHTSPEED/G HUB setup. This
verifies the removal happy path. Exact receiver VID/PID association, reconnect
deduplication, ID stability, sleep and button capabilities were not separately
reported. Source attribution remains a separate [experimental check](phase-3-source.md).

## Remaining manual checks

1. Removal happy path is user-confirmed. For remaining checks run one rebuilt Xcode copy (⌘R). Open **Devices**, note the Logitech receiver
   interfaces and IDs. Unplug only the G603 LIGHTSPEED receiver: its corresponding
   rows should disappear automatically, while unrelated devices remain.
2. Reconnect it: interfaces should return once each. IDs may change. Confirm saved
   rules remain present; with the running copy's actual remapping permissions,
   repeat ordinary/hold/leftward G603 rules in disposable TextEdit.
3. Check closing/reopening the window, repeated Refresh, sleep/wake and reconnect
   while rules paused/active. Discovery must not duplicate rows or alter pause state.
4. When available, check Bluetooth keyboards/mice, exposed trackpad and Magic Mouse
   interfaces. Do not infer touch-gesture support from their presence.
5. On hardware exposing individual button elements, compare declared HID usages
   against real recorder/Quartz events, including an observable button above #5 and
   G HUB/onboard-profile transformations. Keep unavailable metadata as unknown.
6. Test two actual mice for source attribution separately before adding any physical
   device scope. Same-model IDs, reconnect/restart stability and offline device-bound
   rules remain future gates; enumeration does not establish routing or suppression.
7. Inspect EN/DE/FR layout, minimum window size, keyboard navigation/VoiceOver, stream
   failures and long-running background resource behavior.
