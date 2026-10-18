# Native gesture suppression: scoped feasibility refresh

Date: 2026-10-12. Baseline `main` / `59f5754` plus UI-016 editor changes. This is a source/API review, **not a hardware suppression experiment**. No input mechanism, dependency, OS preference or permission was changed.

## What the current engine can suppress

`EventTapWorker` installs an active session Quartz tap and returns `nil` when the bounded mailbox owns a matched keyboard/conventional mouse/wheel event. The installed macOS 27 SDK's `CGEventTypes.h` callback contract explicitly permits deleting an event this way. Unmatched/synthetic/protected-context events retain existing passthrough and down/up safeguards. This establishes a software mechanism, not interception of every system shortcut: a system action handled before the session tap or in a protected context may remain unavailable.

The isolated `NativeTrackpadDevice` contact callback returns `Void`, copies accepted contact metadata to the bounded buffer and starts its own observer with mode 0. There is no event-replacement/deletion channel in this adapter. Stopping that observer stops Rebind's observation; it does not establish cancellation of macOS recognition. The current tap presets must retain general native-gesture coexistence guidance. After-release primary Touch clicks are a narrow Quartz-event exception described below.

## Refreshed sources and evidence limits

- Apple's [event monitoring guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html): a global NSEvent monitor cannot change/prevent normal delivery; a local monitor can cancel only dispatch inside its own application. Adding a global gesture monitor is not a suppression solution.
- Apple's [Zoom guide](https://support.apple.com/en-euro/guide/mac-help/mchl779716b8/mac): three-finger double tap belongs to the optional trackpad Zoom setting. Existing conditional recovery guidance is appropriate. Turning that setting off is a user-controlled workaround, not Rebind event suppression.
- [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport): current README exposes global default-device touch observation, macOS 15+/tools 6.2/Xcode 26.2+ and an MIT license link. It does not document suppression. Current manager-page fetch did not establish the relevant callback source/maintenance revision; prior pinned ABI/license audits remain in [DEPENDENCIES](DEPENDENCIES.md). No code/binary copied or installed. Swift Package Index search did not yield independently verified suppression/compatibility evidence.
- Apple CGEventTap/CGEventType web pages required JavaScript and their Markdown links failed in this browser tool. The installed Apple SDK callback contract and the actual adapter/tap were inspected instead; no claim of a complete current online API audit.

## Decision and next gate

Do not add guessed private gesture-event numbers, blanket event suppression, driver/device seizing or automatic preference writes. No safe, selective system-gesture suppression route is established for current Trackpad presets. This is a limitation of the verified implementation, **not proof that every possible macOS architecture is incapable of suppression**.

A future bounded acquisition/coexistence probe must identify the exact native conflict and a cancellable representation early enough to prevent it, then test matched-only filtering, unaffected scrolling/clicks/system navigation, pause/revocation/recovery and latency on named macOS/hardware. Reconcile a successful capability decision before adding suppression. Until then, offer the existing conditional settings guidance or an alternative preset; do not remove the warning or change real settings automatically.

## Broader source audit follow-up

The [2026-10-12 touch-library audit](touch-library-audit.md) subsequently retrieved pinned OpenMultitouchSupport manager/listener source, metadata and full MIT license, closing the fetch limitation above for that snapshot. Eleven additional candidates were reviewed at the stated evidence depth. Real limited Quartz scroll filtering exists in CalmMouse; MagicBind's mouse tap is listen-only. No reviewed candidate establishes selective cancellation of the full native Trackpad/Magic Mouse gesture pool. This updates source coverage without changing the current engine or hardware evidence.

## Three-finger after-release clicks — 2026-10-18

[INPUT-013](../tasks/INPUT-013-trackpad-review-fixes.md#three-finger-native-clicks-and-selector-alignment--2026-10-18) adds matched-only primary-click replacement to the existing active Quartz path, using a completed, stationary, continuous three-finger stroke and the public AppKit Touch subtype. Existing callback fixed slots and native/event activity gates are retained; no new capture dependency or private gesture event number. The first tap's primary click is also replaced when a double rule is waiting. This does not cancel Look Up, Zoom, native drags pressed during contact or arbitrary system gestures, and subtype does not establish physical-device attribution. Physical/mixed-device coexistence is awaiting verification. Sources, bounded tests and reuse decision are in the task.
