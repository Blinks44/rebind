# Phase 4 — Native Space shortcuts

Scope: SPEC §5 A1/A2, §§6–7, 9–12, 2026-10-09.

**Acceptance correction:** the user confirms the instant Dock swipe moves Spaces,
but rejects its abrupt transition and black-screen bounce beyond the final desktop.
That mechanism failed acceptance and has been removed, together with its private
IOHID serialization and layout tests. Historical research/build evidence remains in
PLAN. The three direct Dock notifications have user-confirmed happy paths.
**The user now reports everything works well (2026-10-09), in response to the
requested native animation/both-direction/first-and-last-desktop retest.** Exact
individual cases, display configuration and timings were not restated; the agent
did not observe the effects or post global input. This verifies the user-reported
happy path, not every modifier/lifecycle/display/platform combination.

## Mechanism and limits

- Post a balanced Control+Left/Right arrow down/up pair from a public Quartz
  `hidSystemState` source at `cghidEventTap`. Previous attempts used session posting,
  including the one with a HID-state source. Both events have exactly Control and
  secondary-Fn flags, zero autorepeat and Rebind's synthetic tag. Inherited low/high
  Option/Command bits are overwritten. No flagsChanged/modifier key transitions,
  held-key restoration, Dock swipe or private Space setter.
- macOS receives its own standard hotkey and owns animation, Reduce Motion,
  first/last-Space boundaries and focused-display selection. No Space inventory,
  custom boundary logic, screen selection, animation timing or cursor warp.
  This intended behavior is backed by upstream evidence, not current Rebind hardware
  verification. Quartz posting has no effect acknowledgement.
- Recipe checked against pinned MIT spacekit source; bundled notice replaces the
  removed noswoosh/iss notices. No Go binary, helper, daemon, extra capture tap,
  package, root/SIP change or new permission. Deployment remains macOS 26; the
  previous private gesture gate to 26.6/27 is no longer applicable. Actual macOS 26,
  Intel and other-tool interaction remain unverified.
- Read `AppleSymbolicHotKeys` through public CFPreferences on the existing action
  worker before construction, never in the event callback or mailbox lock. Its
  preference schema/IDs 79/81 are undocumented. Missing overrides use macOS defaults;
  enabled entries without a value use their default; an explicit value must be a
  standard matching arrow with Control (with or without the secondary-Fn bit).
  Disabled/custom/malformed entries fail without posting an app shortcut. Rebind
  never enables/reassigns a hotkey. Customized chords are not supported in this slice.
- Catalog availability denotes Quartz API support; the editor explains the system
  shortcut dependency. Execution checks settings and shows a translated error on
  preparation failure. Consumed source input is not replayed and unrelated rules are
  not emergency-paused. No promise of live preference refresh; restart after changes
  during this walkthrough.
- Build both events before any posting, recheck generation, posting permission and
  Secure Input immediately before the pair. Once down is posted, always finish up.
  No suspension, queue hop or modifier-state restoration between the two events.
  Existing tag guard prevents Rebind's own synthetic events entering matching.
- Typed Space actions and existing user rules are unchanged. Schema 14 now also adds
  mouse output and reads schema 13 without rewriting. Earlier migrations
  preserve IDs, profiles, triggers/source modifiers, selection and global pause;
  retired output chords stay retired. Loading never rewrites the configuration.
  Ordinary ShortcutSender and the three direct Dock notifications are unchanged.

## Software evidence

The current commands, counts, toolchain, signatures, catalog completeness and
user-store hash check are recorded in PLAN. Tests use event construction and injected
posting only: exact HID source/Control+Fn flags/arrow pair/tag, tap location, default
and rejected preference entries, cancellation before/after preparation, allocation
failures, finishing key-up, schema/migration/byte preservation and worker regressions.
They do not prove visual animation, edge behavior, physical modifier safety or delivery.

## Manual retest

1. Quit the old copy and launch one rebuilt authorized Rebind. Existing previous/next
   rules require no recreation. Keep Command/Option remapping and G HUB as they are.
   Confirm physical Control+Left/Right switches Spaces; these Mission Control system
   shortcuts must be enabled and standard.
2. From a middle desktop, test both G603 mappings. Compare the slide with physical
   Control+arrow. At the first desktop repeatedly press previous; at the last desktop
   repeatedly press next. Expected: the same native boundary response, no transition
   into a black screen, no focus loss or app text navigation. Test an empty neighbour,
   a full-screen Space, rapid alternation and multiple displays if available.
3. Compare Reduce Motion behavior with the physical shortcut. Try left/right held
   Control/Option/Command and release during switching; check ordinary typing and
   shortcuts afterwards. Natural Scrolling must not affect direction in this path.
4. Check pause/edit/profile/recording/sleep/Secure Input/permission loss cancellation,
   three direct Mission Control actions and ordinary bindings. Optional disabled or
   custom system-shortcut test: after restarting, expect an error and no keyboard
   shortcut sent into an app. Restore settings yourself before the ordinary retest.
5. Record OS/build, target apps/displays, exact results and responsiveness. The user
   has confirmed the requested happy-path retest; do not generalize that to every case.
   Updated editor layout, other locales, VoiceOver, macOS 26 and Intel remain manual.
