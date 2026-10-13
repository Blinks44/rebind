# Permission gate correction — 2026-10-08

Scope: Phase 1 onboarding/hardware gate; SPEC §7 and S2. User hardware: Logitech
G603 via LIGHTSPEED, with G HUB installed (confirmed by the user).

## Cause and correction

The previous UI and worker required AX trust plus separate Quartz listen and
post preflights. [Apple DTS](https://developer.apple.com/forums/thread/828052)
explains that Accessibility already grants listening and posting. The current
active session tap does not need a separate Input Monitoring grant. This corrects
the capture-specific permission requirement; future HID paths must check their
own requirements. No TCC bypass or change to the specification is involved.

UI and worker now share actual AX/post checks. Listen preflight remains an
informational status and never becomes true merely because a request was clicked.
Actual tap creation still has to succeed. The user later supplied screenshots
showing AX granted while post preflight stays false; AX alone is not treated as
proof of synthesis access. A dedicated Allow Event Sending button now requests
`CGRequestPostEventAccess` explicitly and the editor reports this missing stage. The redundant listen request is removed;
its absence is explained. Explicit Accessibility requests open the correct settings
pane when access remains unavailable. Finder reveal uses the running bundle URL.

## Verified

- Debug and universal Release build successfully using `apps/rebind/scripts/dev.sh`.
- 73 tests in 12 suites pass, including permission-policy and staged-consent regressions.
- Release signature verification passes; 77 translated keys have EN/RU/DE/FR text (plus the unchanged product-name entry).
- Native Russian UI displays Accessibility **not granted**, Input Monitoring
  **not required**, complete explanations and the Finder button. No input recorded,
  binding saved, shortcut posted or permission granted in this session.

The earlier inspected build showed AX missing. Subsequent user screenshots show
AX granted and post preflight unavailable. A separate synthesis request is now
provided. The user subsequently confirms that it worked and that G603 middle/side
recording yields Mouse Buttons 3/4/5. This establishes successful setup and capture
for this user-tested subset; the user then confirmed Control + Button 4 → Command+A in TextEdit and plain
Button 4 behavior. Broader safety/lifecycle and other trigger modes remain unverified.
UI automation timed out during the Finder reveal attempt; do not count that button,
System Settings fallback, exact prompt sequence or revocation as verified from
that automation attempt. The later user report independently confirms capture.

## Subsequent user-confirmed result

- G603 via LIGHTSPEED with G HUB: middle Button 3, sides Buttons 4 and 5.
- Permission flow and actual mouse recording work according to the user.
- Control + Button 4 → Command+A in TextEdit and plain Button 4 behavior are
  subsequently user-confirmed. Full suppression/release and safety/lifecycle
  checks remain open; this result does not verify the new long-press mode.

## User-assisted checks still required

1. Launch `build/DerivedData/Build/Products/Debug/Rebind.app` after the final build.
   In Accessibility, enable this copy; Show App in Finder should reveal its location
   for the + button if it is missing. Refresh/relaunch if macOS asks. Keep the same
   launch path and avoid another ad-hoc rebuild during this walkthrough.
2. If AX is granted but event sending is not, click Allow Event Sending. Handle
   any macOS prompt yourself and refresh/relaunch if requested. Confirm the
   permission panel disappears once AX and actual post access are available,
   even without a separate Input Monitoring entry. If it stays visible,
   report the status text; do not blindly reset TCC.
3. Follow [Phase 1](phase-1.md) using a disposable document and harmless shortcut.
   Middle and side recording is now confirmed (3/4/5); check Control + Button 4
   → Command+A externally and unmapped plain Button 4 behavior. Exact G HUB
   mappings remain unreported. LIGHTSPEED and installed G HUB are user-confirmed. Do not infer button count from physical controls:
   DPI and underside connectivity controls may not produce ordinary mouse events.
4. Check normal unmatched behavior, suppression/release, pause, permission loss
   and explicit retry. Then follow wheel and double-press checklists.

Historical scope note: physical-device inventory/attribution was withdrawn on
2026-10-08; Phase 3 now concerns manual profiles. The current native first-run
and permission UI is covered by [2026-10-11 implementation evidence](permissions-native.md);
the older checks above retain their original tested scope.
