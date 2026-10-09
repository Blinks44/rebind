# Phase 4 — Ordinary window placement

Scope: SPEC §5 Windows and applications / A1/A2, §§6–7, 9–12.
Implemented and software-tested; **left/right placement and maximizing are user-confirmed** (2026-10-09). The user reports different applications, left/right halves, maximizing and minimizing; exact apps/rules/OS and maximize/full-screen distinction were not restated. Centering and detailed display/constraint/cancellation checks remain open.
The agent did not move/resize windows or start a global remapping engine.

## Contract

- Shared Windows and Applications catalog offers Left Half, Right Half,
  Fill Available Screen and Center Window. Center preserves the existing size;
  fill uses usable display area and does not enter full screen. No output chord
  is recorded. All currently supported input/activation families use typed dispatch.
- Public AX reads focused application/window, owner PID, role/subrole, minimized
  state and position/size only. No titles, text or typed input retained/logged.
  Reject Rebind itself, nonstandard/minimized/foreign/read-only/unavailable windows.
  Center requires writable position but not writable size.
- Choose the display with the largest positive intersection with the current
  window frame (stable input order breaks ties). No pointer-based selection or
  automatic fallback from an offscreen window. Use NSScreen.visibleFrame to exclude
  Dock/menu bar; operate in desktop points, with primary-display top converting
  Cocoa coordinates to AX coordinates. Negative display coordinates are supported.
  Halves meet without a gap even at an odd width. Center rejects oversized windows.
- MainActor captures value-only display snapshots at startup, display notifications
  and the existing 0.5-second refresh. The serial worker accepts snapshots no older
  than two seconds, rechecking expiry/geometry before every write. A screen change
  noticed during the action cancels it. Changes between screen refreshes are still
  possible; topology/Dock/inset transitions require manual checks. Display refreshes
  do not reset unrelated rules/held-input state or queued actions.
- AX position/size calls stay off UI/event-tap threads, bounded by the existing
  450 ms request budget and at most 150 ms per call. Recheck generation, Secure
  Input, actual posting access, trust, focused app/window and minimized state
  before each mutation; recheck cancellation after potentially blocking reads.
- Resizing writes size, position, then size again because the first resize can be
  constrained at the old position. Center writes only position. Immediate frame
  readback within one point means performed; this is not an animation-completion
  acknowledgement. App minimum size/position restrictions or asynchronous changes
  can prevent the requested frame, producing a localized failure.
- Separate AX writes are not atomic: a resize/move can remain if a later call fails
  or cancellation occurs. Stop immediately, without retries, rollback, activation,
  synthetic shortcut/menu fallback or forcing the app's minimum size. Other rules
  remain active; the consumed source is not replayed.
- No private AXFullScreen/AXEnhancedUserInterface/minimum-size attribute. Ordinary
  standard writable windows are required. As a conservative full-screen safeguard,
  reject a window covering its entire display (one-point tolerance). This can also
  reject an ordinary oversized/full-display window; unusual full-screen AX layouts
  are not universally identifiable through this geometry check. Exit full screen
  before using these actions. This is independent placement, not macOS coupled
  tile groups, Stage Manager/Space management, moving to another monitor, restore
  history or adjustable custom layouts.
- Schema 16 loads schemas 1–15 without rewriting until successful user edit.
  Existing actions/profile selection/modifiers/activation are retained. New payloads
  in old schemas (including inactive profiles) and unknown cases fail validation.

## Software evidence — 2026-10-09

`WindowLayoutGeometryTests`, `WindowLayoutExecutorTests`, `WindowLayoutActionTests`:
24 new functions; full **326 tests / 45 suites / 0 failures** in
`build/WindowLayout-Final2.xcresult`. Geometry covers odd halves, usable area,
size-preserving center, crossing/tied/negative-coordinate displays, Cocoa conversion,
invalid/offscreen/full-display targets and snapshot freshness. Local synchronous AX
fakes cover ownership/permission/support, read-only dimensions, bounded mutation
sequence, minimum-size clamping, focus/trust changes and cancellation at every write
or during focus reads. Injected worker tests cover routing, non-pausing errors,
freshness/geometry/lifecycle invalidation and unrelated queue retention. Temporary
stores verify schema-15 byte retention until save and old-schema/inactive rejection.

Debug and universal Release builds, toolchain and signing checks are recorded in
PLAN.md. No real windows were used by these tests; app-specific AX support, visual
layout, event delivery and latency are manual gates.

## Manual check

1. Restart one rebuilt authorized Rebind copy. In a test profile map a spare G603
   button to Windows and Applications → Left Half. Focus an ordinary Finder,
   TextEdit/editor or browser window: expect its left half on the same display,
   clear of the Dock/menu bar. Try Right Half and Fill Available Screen separately.
   Fill should keep an ordinary window and not create a full-screen Space.
2. Resize the window manually, then Center Window: expect unchanged dimensions
   and centered position within usable display area. Try a nonresizable ordinary
   window if available. Repeat all four actions, and record apps/OS/rules used.
3. If another display is available, try it to the left/above/below the primary,
   a window crossing displays, differing scales and changed Dock placement. Expect
   the display containing the largest portion of the window; no move to the pointer.
   Disconnect/rearrange a display and check queued requests/ordinary bindings.
4. Try a window with a large minimum width, a dialog, fullscreen window, minimized
   window and app with no usable window. Expect refusal or a localized constraint
   error; a partially accepted placement may remain. Don't expect a coupled native
   tile group or resizing of another window.
5. Check modifier+button/hold/wheel/cardinal gestures, old clicks/media/Spaces and
   profile/rule reload. Exercise pause/edit/profile/record/sleep, protected input and
   permission loss safely; no late retargeting, stuck input or unintended window.
   An accepted write cannot be recalled. Hardware latency, visual layout in all four
   locales/VoiceOver, macOS 26 and Intel remain unverified.
