# Phase 4: Selected application, web address and file/folder actions

Scope: SPEC §5 A1/A2, §§9–12. Implemented and software-tested on 2026-10-08.
Russian configuration UI inspected; the user reports the requested opening/activation
actions work on the existing G603 setup. Exact targets/triggers and closed-app
behavior were not restated; fault/cancellation/latency checks remain open.
No new permissions or runtime dependencies.

## Execution contract

- **Open application:** choose a `.app` using the native dialog. Store its local
  path and bundle ID. Preparation validates matching bundle metadata; NSWorkspace
  opens/activates that copy without requesting a new instance or substituting
  another running copy. Rebind itself is rejected.
- **Activate running application:** same selection, but only an already running
  application with the same bundle ID and standardized path is activated. A closed
  app produces an error; it is never cold-launched by this action.
- **Open web address:** an explicit HTTP/HTTPS address with a nonempty host and no
  embedded credentials. Reject unsupported/custom schemes, incomplete addresses,
  invalid/control characters and addresses over 8192 UTF-8 bytes. Use the system
  default handler; URL queries remain local action parameters, not diagnostics.
- **Open file or folder:** native selection of a local file/folder, maximum path
  4096 UTF-8 bytes. Check existence and resolve symlinks on the action thread.
  `.app` targets belong to the app action and are rejected here. Open through the
  default OS handler, without reading contents or constructing shell commands.
- Targets moved/deleted after selection need reselection. Local paths are stored
  in schema 9; no automatic bookmark recovery, signing-identity verification or
  security bypass. Gatekeeper remains effective. These actions do not implement
  Apple Shortcuts, custom schemes, scripts, arguments or environment parameters.
- Shared matching preserves existing key/button/wheel/hold/double/pointer rules.
  A matched source stays consumed even if opening fails; a localized error appears
  without replaying the input. No launch failure pauses unrelated rules.
- Metadata runs outside the tap/UI polling callback. One claimed handoff slot and
  one retained MainActor async operation serialize opening with other output;
  the existing queue holds at most 16 waiting actions. Check active generation,
  permissions and Secure Input immediately before the native request.
- Profile/pause/edit/recording/sleep/capture changes invalidate unaccepted work.
  A request already accepted by Launch Services cannot be recalled; its eventual
  stale error cannot overwrite current state. Native completion means request/
  launch acceptance, not that a web page or document finished loading.
- Native completion has no guaranteed timeout. Gatekeeper/UI or slow mounted-file
  metadata can delay subsequent output. The capture tap and pause UI remain
  independent, and waiting work stays bounded. Actual timing/responsiveness is a
  manual gate; no measured worst-case claim or automatic duplicate retry.
- Schemas 1–8 migrate in memory, preserving profiles, selection, all earlier actions
  and rules. Load does not rewrite. Save checks the same 2 MB limit as load before
  atomic replacement; an oversized document leaves prior bytes intact.

## Software evidence

- Xcode 27.0 / Swift 6.4 / SDK 27.0, macOS 27.0.1 (26A434), Apple Silicon.
  Deployment 26 unchanged; Intel/macOS 26 execution unverified.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/WorkspaceActionsTests-Final2.xcresult`:
  **225 tests / 32 suites / 0 failures**. Twenty new functions cover metadata,
  supported/invalid parameters, directory URL/path comparison, old-schema gates,
  migration byte preservation, trigger families, large-save rollback, serialization,
  cancellation/races, revoked access, Secure Input, routing and localized failures.
  Temporary stores and injected native operations only: no live posting or launch.
- Russian UI: web search and valid/invalid field states, native TextEdit selection,
  activation hint with retained target, picker cancellation without error, project
  folder selection. Editor cancelled without saving. The inspection copy lacked
  AX/post grants; no grants, permission requests or user-configuration writes.
- Debug/universal Release and catalog/signature checks are in PLAN. Other locale
  layouts, keyboard/VoiceOver and native backend acceptance need manual verification.

- Manual test report, 2026-10-08: the requested G603 application opening/
  activation, web and file actions completed successfully. This supports successful ordinary
  execution of the requested actions. Specific apps, files/folders, addresses,
  triggers, OS and closed-app behavior were not restated; remaining walkthrough
  cases are not marked passed on this general confirmation.

## Manual checks

Use one rebuilt authorized Rebind copy. Choose disposable TextEdit documents and
an ordinary local folder; record actual OS, apps, trigger/modifiers and result.

1. Map an ordinary G603 side button to **Open application → TextEdit**. Check a
   cold launch, then an already running/hidden copy. No duplicate instance or old
   rule output; release remains normal. If multiple copies exist, check selected
   path behavior rather than relying on display name.
2. Change to **Activate running application → TextEdit**. From another app, check
   activation/unhide. Quit TextEdit and repeat: localized failure, no launch.
   A later fresh press after manually opening TextEdit should activate normally.
3. Map **Open web address → https://example.com**. Check default browser delivery
   and one request per intended activation. Try `example.com`: Save is disabled
   and the field explains the supported address format. Custom schemes remain
   unavailable; do not infer page loading from an accepted native request.
4. Map **Open file or folder** to a disposable `.txt`, then a local folder. Check
   default app/Finder. Cancel a new selection: old target remains. Rename/move a
   disposable target: the old action fails safely; reselection fixes it.
5. Check existing shortcuts/audio/window actions and a second profile. Switch,
   pause, edit or start recording while a source is held or work is pending: no
   unaccepted stale action/late error or stuck release. Already accepted opening
   may finish; do not mistake that OS limitation for successful cancellation.
6. Check sleep/session lock, Secure Input and revoked permissions with pending work
   using existing lifecycle walkthroughs. Verify input passthrough and recovery.
   If native opening waits on OS UI, check pause/emergency controls and bounded
   behavior; do not bypass Gatekeeper to finish a test. Measure output timing.
7. Relaunch with schema-9 selected profile, targets, global pause and old rules.
   Check EN/DE/FR layout, tab order and VoiceOver web-field label. Core hardware
   safety gates from earlier phases remain open even if these happy paths pass.
