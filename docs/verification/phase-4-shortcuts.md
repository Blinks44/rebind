# Phase 4: Apple Shortcuts

Scope: SPEC §5 A1/A2, §§9–12. Implemented and software-tested on 2026-10-09.
Native listing was probed on this Mac; no user command was executed by the agent.
The user confirms the requested command execution works (2026-10-09); exact
workflow/trigger were not restated. Workflow prompts and cancellation remain manual gates.
No runtime dependency, private API or permission grant was added.

## Execution contract

- **Automation → Run Apple Shortcut:** explicitly select an existing command from
  a native Picker. Refresh calls `/usr/bin/shortcuts list --show-identifiers`.
  Store UUID and a display-name snapshot; execution passes only `run` and UUID as
  separate Process arguments. Names never become options, shell code or a fallback
  lookup. Refresh updates a renamed selection by UUID. A missing saved selection
  is retained and explained; deletion requires selecting another command.
- Listing runs outside MainActor and input callbacks, with task cancellation and
  a ten-second waiting limit. The bounded UTF-8 result is at most 256 KiB / 4096
  rows; names must be nonempty, at most 512 UTF-8 bytes and free of control
  characters. Invalid output or duplicate IDs produces an error, not a guessed
  partial list. Only names/IDs needed for selection are read; no command contents.
- Execution uses the existing serial action worker. Standard input is `/dev/null`;
  output/error are discarded. No clipboard/file payload, custom environment,
  arguments, shell, automatic retry or captured workflow results. A workflow can
  still perform its own configured actions and request its own permissions through
  Shortcuts; Rebind does not approve those prompts.
- A running CLI has a 60-second waiting limit. The worker checks cancellation,
  Secure Input and posting permission every 20 ms while waiting. Pause, profile,
  editing, recording, suspension or engine stop invalidate the dispatch. On
  cancellation/error/timeout, terminate only the owned CLI child, allow 250 ms
  for exit, then SIGKILL if necessary and reap it. No process-group termination.
- These are client waiting limits, **not hard OS latency bounds or a guarantee
  that the Shortcuts service cancels accepted work**. Process launch/termination
  can take additional time; accepted effects cannot be rolled back. UI text
  explicitly describes stopping the wait. Other output waits behind the active
  action, with at most 16 waiting actions; the input tap and pause UI are separate.
- A current failure shows a localized error and does not replay consumed source
  input or pause unrelated rules. Cancellation ignores stale errors. Source-release
  ownership and unmatched passthrough retain the existing matcher contract.
- Schema 10 reads schemas 1–9, preserving profile/rule IDs, selection, pause and
  earlier actions without rewriting on load. A new action disguised in an older
  schema is rejected, including inactive profiles. Saving remains atomic with the
  existing 2 MB document limit.

## Software evidence

- Xcode 27.0 / Swift 6.4 / SDK 27.0, macOS 27.0.1 (26A434), Apple Silicon.
  Deployment remains 26; Intel/macOS 26 execution is unverified.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/AppleShortcutsTests-Final3.xcresult`:
  **243 tests / 35 suites / 0 failures**, including 18 new test functions. Tests
  cover parsing/identity/limits, literal UUID arguments, old-schema migration and
  byte preservation, input families, serial dispatch, progress/error routing,
  cancellation generations, revoked posting and Secure Input.
- Process tests run benign `/usr/bin/printf`, `/bin/cat`, `/usr/bin/false`,
  `/bin/sleep` and `/usr/bin/yes` fixtures: literal argv, EOF/no input, discarded
  output, failure, cancellation, timeout and output-cap termination. No shell,
  real global posting, user workflow or user-store mutation in these tests.
- A read-only native listing returned status 0 and two UUID-suffixed rows. Only
  byte/row counts were reported; names/content were not printed or recorded here.
- Debug and universal x86_64/arm64 Release builds pass. Both signatures verify;
  Release is ad-hoc signed with Hardened Runtime, no added entitlements, minimum
  macOS 26.0. Russian UI inspected after an initial window lookup failure: catalog,
  two loaded commands, unsaved selection, refresh retaining selection and readable
  wrapped hint. Save stays disabled without a trigger. Editor cancelled and copy
  quit; user schema-9 two-profile file hash remained unchanged. No permission
  request/grant or workflow invocation. Other locales/VoiceOver/tab order remain
  unverified. See PLAN for final logs.

## Manual checks

Manual test report, 2026-10-09: the configured side-button action executed
the Apple Shortcut notification test successfully. This supports the requested execution
happy path, not rename/delete, prompts, timeout or cancellation. The agent did not
observe the actual output; specific workflow/trigger were not restated.

Use one rebuilt authorized Rebind copy. Record OS, chosen test workflow, physical
trigger/modifiers and observed result. Use a harmless disposable workflow.

1. In Apple's Shortcuts create **Rebind test** containing only **Show Notification**
   with a fixed test message. Run it manually first; handle its own normal permission
   prompts yourself. In Rebind choose Automation → Run Apple Shortcut, refresh,
   select it, and map an ordinary G603 side button. Expect one notification per
   activation, normal release and no old rule output.
2. Rename the disposable command. Refresh/Reopen its rule: updated display name,
   same UUID, successful activation. Relaunch with the saved rule and chosen
   profile; check old shortcut/audio/window/opening rules still work.
3. Delete only the disposable test command. The existing rule reports it missing;
   triggering reports failure. A newly created same-name command must not run
   unless explicitly reselected. Never delete a valuable workflow for testing.
4. For cancellation, optionally create a second disposable workflow containing
   Wait then Show Notification. While it runs, pause or switch profiles; the client
   waiting indicator clears and stale errors do not appear. Shortcuts may still
   finish accepted steps. Check input passthrough, release and emergency controls.
5. Optionally test a disposable wait over 60 seconds: localized timeout/failure
   and subsequent output recovery, no automatic rerun. Test prompt/error behavior
   with harmless workflows; do not grant unrelated access just to finish a test.
6. Exercise hold/double/wheel/pointer activation, bounded queue, Secure Input,
   permission loss, sleep and stop using existing walkthroughs. Measure actual
   responsiveness. Inspect EN/RU/DE/FR wrapping, keyboard operation and VoiceOver.
   Happy-path success does not close these safety/latency gates.
