# Trackpad feasibility probe

Standalone developer tool for Phase 5 / SPEC §3.4 and T1. It is **not part of
Rebind.app** and does not enable gesture rules. Requires full Xcode, Swift 6.2+
and macOS 26/27. The first build downloads the pinned packages.

From the repository root, availability-only check (the default):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run --package-path tools/TrackpadProbe TrackpadProbe --check
```

This calls only the framework availability function: no device creation,
contact callback, start or stop. `true` is not proof that contact capture works.

For a deliberate hardware check, unlock the Mac and run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run --package-path tools/TrackpadProbe TrackpadProbe --capture --seconds 20
```

During these 20 seconds, place and lift 3 and 4 fingers, then try light single
taps, double taps and physical clicks separately. Ordinary macOS gestures remain active; use a harmless desktop.
Capture defaults to 20 seconds; accepted range is 1–30. Share the printed summary
with the trackpad model and macOS version. `frames=0` means acquisition has not
been established. A pressure change does **not** prove physical-click detection.

If Subsurface reports the default device as `other`, the ordinary mode refuses
capture. For explicit acquisition diagnostics on that unclassified device:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run --package-path tools/TrackpadProbe TrackpadProbe --capture-default --seconds 30
```

This does not establish that the device is a trackpad. On the current built-in
device, Subsurface reports `other` although `built_in=true`; the initial unattended run received zero frames. The subsequent user-run
30-second check received **1010 frames**, counts 0–4, no rejected frames and no
reported nonconsecutive frame IDs. This confirms contact acquisition on that
built-in device; it does not verify recognition, lossless delivery or physical clicks. It selects only the same
default device, permits the unknown category, and still refuses a classified
Magic Mouse. No inventory, source attribution, family allowlist or production
support is added. The source category and built-in boolean are printed;
no unique identifiers are included. Availability alone cannot distinguish missing
hardware from a missing native symbol, and `other` may reflect an unknown family
or failed metadata lookup. Report actual frames before drawing conclusions.

The tool uses only one default multitouch device. It prints at most 64 contact-count
transitions and one aggregate JSON report: frame count, rejected frames, count
transitions, observed finger counts/states, peak pressure and nonconsecutive frame
IDs. It neither prints nor persists coordinates, contact/device identifiers,
absolute timestamps, session identity or text. Scribe logging is disabled before any framework call. Subsurface starts the
private framework in verbose mode, which can still print native initialization
messages (observed: hardware family and sensor-grid dimensions). No guarantee
of completely silent native output; inspect it before sharing a full transcript. Raw contacts live transiently in the upstream latest-frame
stream and are discarded after aggregation. Passive modes do not request permissions, post events, seize devices, change
system preferences or activate haptics. The separate explicit action-test mode
below can post one balanced Command-W pair.

Secure Input/console/lock checks precede capture and each consumed frame, with a
100 ms polling watchdog. The lock key is private and compatibility-limited;
polling can be delayed and is not an instantaneous security boundary. There is no
automatic restart after a protected session. Sleep/wake, callback teardown,
permissions, private ABI and device compatibility still require hardware checks.
Oversized contact arrays end capture as incompatible; upstream pointer/count
validation remains an audited limitation, not solved by this check.

Subsurface uses `bufferingNewest(1)`, so intermediate frames may be lost. The
sequence counter is diagnostic only: empty frames lack a frame ID, rollover is
reported as a discontinuity, and this does not prove lossless delivery. Future
recognition must cancel uncertain candidates. Contact observation does not prove
source-event suppression or freedom from double effects with system gestures.

Tests (pure argument/aggregation/report behavior; no contact capture):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test --package-path tools/TrackpadProbe
```

## Short-contact candidate check

Capture now also prints `short_contact_candidate={...}` and final counts for 3/4
fingers. Try three light single taps with three fingers, then three with four
fingers, with pauses between taps; do not press to click. Then hold fingers for
one second and try a small swipe. Report which actions you made and the candidate
lines/final counts. No actions are dispatched and native gestures remain active.

The pure recognizer requires a neutral frame before starting, 30–250 ms total
contact time, finger formation within 80 ms, at least 15 ms at the peak count,
≤2% normalized per-finger movement, and release within 80 ms of the first lift.
It rejects changed identities, re-added fingers, duplicate IDs, invalid numeric
metadata, missed frame IDs, backwards time and within-stroke inter-frame intervals over 50 ms. Idle silence
between consecutive native frame IDs does not invalidate a new stroke.
These provisional tolerances need hardware tuning. An empty upstream array lacks
native time/frame identity: it cancels an active candidate rather than completing
one with invented timing. Session end/cancellation clears contact origins.

This is **a short-contact candidate, not a confirmed tap**. Physical clicks may
produce candidates; pressure is reported without a click threshold. Double taps,
corners, modifier chords, palm rejection, click separation, suppression and action
production mapping are not implemented here. The separate one-shot action test
below is not a production recognizer. No tap rules have been added to Rebind.app.
Normalized contact origins and transient IDs are held only in bounded memory to
reject movement; printed candidate data contains only finger count, duration in
milliseconds and peak pressure, never coordinates or identifiers. At most 64
candidate lines and 64 contact-count transitions are printed per session.

## Passive mouse-button / contact comparison

To check light taps and physical clicks separately, use the explicit combined mode:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run --package-path tools/TrackpadProbe TrackpadProbe --capture-clicks-default --seconds 30
```

On a harmless empty desktop, do three light taps with three fingers, then three
physical clicks with three fingers; repeat with four fingers. Pause between each
sequence and do not touch the external mouse. System clicks still act normally.
Share the candidate lines and the final `mouse_button_observation` lines, observer
status/counters and capture-ended reason. A created observer alone is not proof
of button delivery. If macOS refuses observation, the command ends with
`mouse-observation-unavailable` and an explanation; no permission-request API is
called. Input Monitoring may need to be granted to the launcher (for example
Terminal) and that launcher restarted, but tap creation can also fail for other
reasons. Permissions/preferences are never changed by the tool.

The combined mode now prints `contact_observation` records instead of plain
`contacts=...`. Contact transitions, candidates and button records all contain
`elapsedMilliseconds` from the **same local receipt-clock origin**. This makes
the live candidate/contact lines and final button lines comparable even though
they are printed at different times. Wait for `capture_ended` and the full mouse
report before sharing; the final report is explicitly flushed. Ordinary contact
capture modes retain their previous output without these relative times.
Combined-mode transition output is capped at 128 instead of 64 so the requested
twelve tap/click attempts can fit; candidate output remains capped at 64 and the
button buffer at 128. Aggregate counts still include omitted output.

These times measure receipt in the contact consumer or button callback, not
physical gesture onset. Scheduling/stream buffering can delay the contact
consumer. No attempt is made to equate private contact time with Quartz time,
attribute a source or classify a delayed button as a tap/physical click. Sub-
millisecond order is lost by truncation. A receipt before the origin omits the
time field rather than underflowing; no absolute clock origin is serialized.

This mode uses a public session-level **listen-only** Quartz tap. Its mask contains
only left/right/other button down/up; keyboard, text, flags, scroll, drag and pointer
motion are excluded. Events are never modified/suppressed, posted, retained or
copied. The callback extracts only phase, numeric button and pressure; Rebind's
existing synthetic tag is ignored, while other synthetic events may still appear.
A checked-Sendable Mutex buffer reserves 128 records, retains the earliest 128,
counts overflow and prints records only after capture has stopped. No coordinates,
key codes, modifiers, sender/process/device identifiers or absolute timestamps in
its report. Unknown/stale contact count is omitted from JSON; zero means a recent
neutral frame, not missing data.

`nearbyContacts` is the most recently **consumed** count, only if its observation
clock is not in the future and it was updated within 50 ms of the button callback.
Both use the same local uptime clock; private native-contact timestamps are not
assumed equivalent to Quartz timestamps. Async stream/consumer delays and native
callback ordering can still make this proximity misleading. It is not physical
source attribution, exact click-contact matching, a pressure threshold, a
suppression backend or tap/click exclusivity. Native tap-to-click and another
mouse can produce identical button events. Candidates remain independent and can
still appear for a physical click; no gesture actions are dispatched.

A dedicated native thread owns the port/source/run loop, joined through a checked
continuation. Task cancellation requests bounded-loop stop without clearing the
completed normal report. Disable/invalid port ends capture without restart;
protected session clears records/contact timing. Protection is polled outside the
callback at nominal 20 ms, plus the existing 100 ms capture watchdog, and may be
delayed. Callbacks only update preallocated bounded state; encoding/printing and
session queries occur outside them. Stop/teardown/recovery and real click delivery
are still hardware gates, even with passing software tests.

The user's previous short-contact transcript contained exactly three 3-finger
candidates (128/136/128 ms, pressure 54/74/70) followed by three 4-finger candidates
(128/136/152 ms, pressure 49/60/39), matching the requested light-tap sequence.
The later supplied fragment showed no extra candidates; the final report and exact
hold/movement cases were omitted. This confirms the reported light-tap subset,
not physical-click exclusion or all negative cases.

The subsequent user-run comparison ended at the time limit with an installed
observer, 18 button records (nine down/up pairs), no record overflow, three
3-finger candidates and two 4-finger candidates. The first three pairs had
`nearbyContacts=0`; the next three downs had 3 contacts and the final three downs
had 4. This verifies passive button delivery for that run, not physical source
or tap/click separation. The aggregate reported a count of 5 and one frame-ID
discontinuity; exact cancellation attribution was not captured. The original
report lacked a shared timeline, so no delayed-system-click cause is established.

## One-shot four-finger action test

The latest user-run 20-second timed comparison received 515 frames with no
rejected frames, discontinuities or button overflow. The 3-finger candidate
ended at 4777 ms, followed by left down at 4789 (+12 ms) and up at 4805 (+28 ms),
both with zero nearby contacts. This is consistent with a delayed native
post-tap click, but timing does not prove its physical source or cause. The
4-finger candidate ended at 10078 ms with no corresponding button pair in that
run. Other left-button pairs began while 3/4 contacts were active and lasted
1318/1776 ms. These match the requested tap3/click3/tap4/click4 sequence; the
user did not separately relabel each attempt. This verifies shared receipt
timing on the reported built-in device, not universal tap/click discrimination.

A new **explicit action mode** allows a narrow T1 feasibility check. It uses the
same pinned contact adapter and passive button observer, then posts **at most
one Command-W pair**. It never suppresses native input or enables Rebind rules.
Command-W may close a window in some apps: use a disposable browser tab.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run --package-path tools/TrackpadProbe TrackpadProbe --test-four-finger-close --seconds 20
```

After the capture cue, switch to that disposable tab, release all keys/buttons,
wait at least three seconds from the cue, and make one light four-finger tap.
The action waits 500 ms after release to check for delayed button events. It
ends after one posting attempt, including a failed final guard; no retry.
Share the full final report and whether exactly one tab closed, with any native
extra effect. `four_finger_shortcut_posted=true` means the pair was posted,
**not** that an app received it or that T1 passed. Agent tests do not run this mode.

The mode requires macOS 26/27, a built-in default device (including the explicitly
unclassified family), Accessibility and event-posting access for this launcher,
and an installed/enabled passive button observer. Existing Rebind grants do not
necessarily authorize a Terminal-launched executable. Permission preflight is
read-only; no requests or settings changes are made. Refusal ends with guidance.
The default/check/help and all `--capture*` modes remain passive.

If the action mode refuses permission, it now reports `accessibility_trusted`
and `event_posting_allowed` separately. The previously reported combined error
could not tell which was absent. For an **explicit permission request**, run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run --package-path tools/TrackpadProbe TrackpadProbe --request-test-access
```

This requests only the next missing permission: Accessibility first, then event
posting if AX is already trusted. It creates no device or event observer and
never posts input. The AX prompt is asynchronous; the tool stays alive and
rechecks actual grants for up to 30 seconds. Request return values do not imply
consent. A grant does not automatically start the action test.

Allow the launcher shown by macOS (often Terminal) in **System Settings → Privacy
& Security → Accessibility**. If macOS does not repeat a prompt after denial,
open that pane manually. Quit/reopen the launcher after granting and run the
request command again if the next permission is still missing; only when both
statuses are true run the four-finger test separately. Rebind's grant is not a
substitute. This native prompt/restart path is not hardware-verified yet. No
permission requests are made by other modes, polling or agent verification.


The action mode now prints up to 64 `four_finger_action` decisions, using the
same relative receipt clock: `waiting` after arming, `rejected` with a gate reason,
and `cancelled` with a reason such as `button-event`, `new-contact`, `frame-gap`,
`foreground-changed`, `observer-unavailable` or `late-poll`. No coordinates,
contact/frame IDs, app names or PIDs are included. Final sending additionally
prints `four_finger_shortcut_result`: `posted` or the failed final guard (session,
permission, held modifier/button/W, event creation or foreground). Posting still
has no delivery acknowledgement. Missing `four_finger_shortcut_posted` means no
posting attempt reached the final sender; candidate lines alone never imply output.

The user's next 20-second action run passed the access gate and received five
4-finger candidates, but ended at the time limit without any posting attempt.
An erroneous unconditional reset on a subsequent empty frame was found in the
orchestration; it is fixed and covered by pure sequence/empty-tail regression
checks. The prior report did not record cancellation reasons, so the exact cause
of each dropped candidate cannot be assigned retrospectively. Reported frame-ID
gaps and rapid new contacts remain legitimate cancellation conditions; do not
weaken those guards to force output. The next user-run check confirmed successful delivery: one 176 ms four-finger
candidate (pressure 45) at 5256 ms, one posted pair and `shortcut-posted` stop.
All 27 frames were accepted with no reported frame discontinuity or button
overflow; the only two button events preceded the contact sequence. The user
confirms the requested effect. This verifies that standalone happy path, not
universal click exclusion, absence of every native extra effect, lifecycle
safety or gesture rules in Rebind.app.

A completed, otherwise qualified four-finger candidate is eligible only after
an observed neutral state and the initial three-second arming period. Any
observed button during the stroke or 500 ms settling period, new contact,
changed foreground application, observer failure/record overflow, protected
session, invalid metadata, discontinuous frame IDs or regressed native/receipt
time cancels pending output. An empty native array establishes neutral count
and cancels an unfinished recognition stroke, without inventing a native release
timestamp. After a candidate has already completed on a valid timestamped release,
subsequent empty neutral arrays preserve its pending 500 ms button check. Buttons,
new contacts, observer failure and the other cancellation guards still apply. A poll over
100 ms late drops output. Three-finger candidates never arm this action.

The final sender rechecks permission, console/Secure Input/lock, foreground PID,
held modifiers, mouse buttons and W. It prepares tagged down/up events through a
private-state Quartz source and posts both to that same regular foreground
process with public `CGEvent.postToPid`. No keyboard events are intercepted and
no process identities are logged; the target PID is held only in memory. App focus is sampled at the candidate and every nominal
10 ms while pending; this is not instantaneous focus-change detection or a
window/tab identity guard. The observer cannot establish physical source, and a
later native click or a change after final checks is still possible. A button-free
500 ms interval is a conservative test condition, **not proven click exclusion**.
The intentionally delayed diagnostic sender and private adapter are not approved
for production. System gesture conflicts, actual delivery, sleep/wake/teardown,
3-finger separation, doubles, corners and modifier combinations remain hardware
gates. Rebind.app has no gesture rule UI or runtime integration yet.

## Reviewed dependencies

Preserve `Package.resolved`; do not update dependencies without another audit.
The production integration choice remains open.

| Package | Reviewed version | License / purpose |
| --- | --- | --- |
| [Subsurface](https://github.com/mrkai77/Subsurface/tree/88eb16b0a6f7a44a898cecff9e283298aa413936) | `88eb16b0a6f7a44a898cecff9e283298aa413936` | Apache-2.0; private MultitouchSupport contacts. Tools 6.2, macOS 13+. Active, latest commit 2026-09-30 at review. |
| [Scribe](https://github.com/SenpaiHunters/Scribe/tree/658180864653457ce201917200bac67ee3eeac87) | `658180864653457ce201917200bac67ee3eeac87` | BSD-3-Clause; required by Subsurface, accessed directly to disable logging. Tools 6.0, macOS 13+. Latest commit 2026-01-23 at review. Upstream requires mutable `main`, locked here. |
| [SwiftSyntax](https://github.com/swiftlang/swift-syntax/tree/602.0.0) | `602.0.0`, `4799286537280063c85a32f09884cfbca301b1a1` | Apache-2.0 with Runtime Library Exception; Scribe's build-time macro dependency. Swift toolchain project, not a runtime touch API. |

Full upstream license texts are retained in [Licenses](Licenses).
Upstream source/macros/manifests were inspected; no external setup scripts run.
Private APIs, callback locking/quiescence, latest-frame buffering and the logging
macro dependency prevent treating this successful build as production approval.
