# INPUT-012: Controlled Magic Mouse contact observation

- Updated: 2026-10-16.
- Stage: `awaiting_verification`.
- Owner: Released; production recognition/native coexistence work next.
- Owned surfaces: standalone `apps/rebind/tools/magic-mouse-probe.swift`, affected state/evidence.
- Baseline: `main`, probe changes uncommitted; app engine unchanged.
- Requirements: SPEC §3.5 G1/G2, PLAN Magic Mouse research gate.

## Outcome

The standalone probe accepts `--guided` for seven separate 8-second observation windows with 3-second preparation prompts: one-finger tap, two-finger tap, rest, physical click, double click, scroll and three/four contacts. `--rest` runs only a 12-second rest window after a 5-second touch/lift preparation and 3-second countdown. It reports per-window frame/contact counts and completed contact sequences (peak count, duration, centroid movement and sampled button state), last contact count and boundary-skipped frame count. No event suppression/output, app rules or permission changes. Existing numeric-duration mode remains available.

Completed sequences now receive a provisional one/two-finger tap verdict or rejection reason, plus per-window candidate/rejection totals. `--self-test` verifies classification and boundary behavior without opening a device. All guided runs now include the initial touch/lift preparation.

## Evidence and limits

- [Initial user hardware evidence and registration fix](../history/2026-10.md#2026-10-16-magic-mouse-probe-start-diagnostics): 1,219 valid frames on macOS 27.0.1 (26A434), one/two contacts observed. This does not establish recognized gestures.
- Agent checks: Xcode Swift compiler typecheck passes. Temporary injected checks pass for phase-boundary exclusion, duration, peak count, movement across count transitions, sampled button flag, reset and 256-sequence capacity. No app build: only standalone tool changed.
- Callback remains synchronous, lock-protected with bounded sequence storage, no console/file I/O or actor hops. Reports print on the main thread. Context remains retained until process exit because callback quiescence is undocumented.
- Movement is the largest centroid displacement within an unchanged-contact-count segment, in normalized sensor units; opposite finger movements can cancel and changing finger identities/count can hide movement. Button state is session-wide, polled every 10 ms and sampled on contact frames; short clicks can be missed. Recent completed sequences are retrospectively marked clicked for 60 ms after release. This is provisional diagnostic classification, not a production click filter or gesture recognizer.
- Each window requires an observed zero-contact baseline before a complete sequence can start, including a neutral state observed before the window. Unknown or active boundary state excludes the first contact sequence until release; skipped frame counts make this visible. Unfinished sequences and invalid frames do not become completed taps. Contact counts alone do not prove selective native-gesture cancellation.

## Next

The updated guided classification run met its bounded observed candidate/negative expectations (see below); no identical rerun is required before independent engineering. Next evaluate production recognition with per-contact motion/identity validation, reliable button activity and discontinuity handling, native coexistence, and a focused audit of the app adapter's Boolean callback-registration declaration. Native Smart Zoom/Mission Control settings/effects and mouse model/transport remain unknown. Three/four-finger contacts are observed but outside this prototype's candidate pool. Do not infer a release preset pool from this single run.

## Diagnostic classification — 2026-10-16

- Probe-only qualification: complete neutral-to-contact-to-neutral sequence, peak one/two fingers, duration 20–200 ms, normalized centroid displacement ≤0.025, peak count sustained at least 20 ms, no observed button during contact or the sampled 60 ms interval after release. Unfinished/boundary-skipped/invalid sequences cannot become candidates. These are provisional thresholds from the named sample, not release guarantees or SPEC changes.
- Reuse decision: existing `TrackpadTapSequence` is tied to the curated trackpad gesture pool, which excludes these one/two-finger single taps; it is unchanged. The probe labels its existing aggregate summaries rather than adding a capture dependency. The 60 ms exclusion interval follows existing `TrackpadTapGate`. Prior candidate/license audit remains [touch-library-audit](../research/touch-library-audit.md); attempted refresh of the pinned MagicBind GitHub page failed with a cache miss. No third-party code copied, package installed, or new capture mechanism added.
- Verification: `xcrun swift … magic-mouse-probe.swift --self-test` passes **44 checks**. They cover duration/motion/count/button exclusions, reported tap/scroll/click summary fixtures, a button 12 ms after release, preserved neutral baseline, active boundary exclusion and invalid-input cancellation. Summary fixtures are not raw-frame replay or new hardware evidence. Compiler typecheck and `git diff --check` pass. No app build/launch or remapping execution.
- Native event cancellation, double-tap arbitration, per-contact identity/travel, stale/gapped frame rejection and disconnect recovery are not implemented by this diagnostic classifier. Do not promote it into the app as a safe production recognizer.

### Classified guided hardware report — 2026-10-16

User-supplied output on the established family 112 setup: seven windows, 1,156 frames total, zero invalid; every window ends at last_contacts=0.

| Window | Result |
| --- | --- |
| One-finger taps | Four candidates, 89–137 ms, movement 0.002–0.006; eight boundary-skipped frames. An initial excluded contact is consistent with the arming guard; not a production four-of-five accuracy result |
| Two-finger taps | Five candidates, 112–180 ms, movement 0.002–0.006; zero skipped |
| Rest | One 3,331 ms three-contact sequence, rejected as too long; zero candidates |
| Physical clicks | Five sequences, all button-marked/rejected; zero candidates |
| Double clicks | Two contact sequences (not click-pair counts), both button-marked/rejected, including a 191 ms sequence; zero candidates |
| Scroll | Seven sequences, 237–787 ms, movement 0.085–0.278; all rejected by duration; zero candidates. This run alone does not exercise movement-only rejection; earlier injected/summary fixtures do |
| Three/four contacts | One three-contact and one four-contact hold, 1,396/1,294 ms; both rejected by duration; zero candidates |

This establishes diagnostic classification for these observed attempts only. Rest/click/scroll negative windows produced no candidates; broad false-positive rates, actual action delivery, double-tap conflicts, reconnect and native coexistence remain unverified. No new source change or test/build rerun for this evidence update; document links reviewed and `git diff --check` passed.

## Guided hardware report — 2026-10-16

User-supplied output, macOS 27.0.1 (26A434), external family 112, surface 5152×9056. Seven windows total 1,194 frames, zero invalid. This is standalone observation, not production recognizer acceptance.

| Window | Observed completed sequences |
| --- | --- |
| One-finger taps | Five, peak 1, 22–101 ms, movement 0.002–0.007, no button observed |
| Two-finger taps | Five, peak 2, 112–134 ms, movement 0.001–0.005, no button observed |
| Rest | Nine, peaks 3/4, 124–248 ms, movement 0.001–0.015; one button-down sequence. Does not resemble the requested continuous five-second rest; execution vs device fragmentation unresolved |
| Physical clicks | Four completed, peak 1, 180–270 ms, button observed in all. First attempt may have armed the phase; not evidence of four-of-five production delivery |
| Double clicks | Six contact sequences, peak 1, 135–404 ms, button observed in all; contact sequences are not click-pair counts |
| Scroll | Nine, peak 1, 101–799 ms, movement 0.082–0.245, no button observed |
| Three/four contacts | Twelve, ten with peak 3 and two with peak 4, 123–212 ms, movement 0.001–0.013, no button observed |

The named tap and scroll windows separate in movement in this sample; click durations overlap tap durations across the broader sample, so duration alone is insufficient. Four simultaneous contacts are now observed on this mouse; four-finger recognition/reliability remains unverified. The rest window prevents a false-positive-safety claim. No new code/test/build run for this evidence-only update; local document links reviewed and `git diff --check` passed.

### Repeated rest window

User subsequently supplied Phase 3 output: 147 frames, zero invalid; zero-contact=9, one=1, two=2, three=135. The user confirmed resting three fingers, matching the predominant contact count. No completed contact sequences, one unfinished sequence at phase end. This run does not show the earlier repeated completed short sequences. It does not establish five-second contact duration or successful release: the report contains no duration for unfinished sequences, and the ordering of the histogram's zero frames is unknown. Lift timing remains unreported. Do not infer firmware fragmentation, a recognizer pass or a release failure from this aggregate alone.

Further user run: released after four seconds; 137 frames, zero invalid, three-contact=135 and zero-contact=2, no completed or unfinished sequence reported. This is consistent with the probe excluding the entire first sequence while waiting for a neutral baseline, but frame order was not logged, so the aggregate alone cannot prove that explanation.

Code inspection/reproduction found a probe defect: reset discarded the already observed neutral baseline, although idle devices need not deliver a fresh empty frame at GO. Reset now preserves only a known neutral baseline; active/unknown states still require release. Invalid frames clear that baseline. Added `--rest`, last contact count and skipped frame diagnostics. Xcode Swift typecheck passes; temporary injected regression checks pass for a neutral boundary followed by a four-second three-contact hold/release, exclusion of active-boundary contacts, and unknown-baseline exclusion. Guided hardware verification of this correction remains open; no production engine change.

Corrected `--rest` user run: 147 frames, zero invalid; zero-contact=6, two=1, three=140; last_contacts=0, boundary_skipped_frames=0. One completed sequence, peak=3, duration=2,819 ms, movement=0.002, no button observed. This confirms one continuous observed three-contact sequence followed by neutral release, without the prior boundary omission or repeated short completed contacts. The measured 2.819 seconds is not the instructed four seconds; actual placement/release timing was not independently measured. This single trial does not establish general false-positive safety, production gesture recognition or native coexistence. Evidence-only update; no test/build rerun.
