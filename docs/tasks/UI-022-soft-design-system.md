# UI-022: Soft design system and redesigned core screens

- Updated: 2026-10-12
- Stage: in_design
- Owner: Claude Code design chat, 2026-10-12; released at handoff
- Ownership checked: 2026-10-12 on `ca02747`, clean tree; advisory coordination, not a lock
- Owned surfaces: **Rebind - new.sketch** (all pages); DESIGN direction/source sections; SPEC §10 visual language
- Requirements: SPEC §§3.4–3.5, 4, 8, 10; phase 8
- Code baseline: `main` at `ca02747`; documentation-only changes uncommitted; no app code changed

## Outcome and scope

The user prefers the calm look of the new Sketch draft over Liquid Glass and asked for a best-practice design system built from it, to be tried in the app afterwards. This task turns the two hand-drawn Keyboard frames into reusable variables, styles and components, and redraws the core screens from them. Native adoption is a separate later step.

## Acceptance

- [x] Color Variables, shared text/layer styles and components exist for Light and Dark and are used by every screen.
- [x] Core screens rebuilt from components and reviewed through live MCP screenshots in both themes.
- [x] Direction change recorded in AGENTS, SPEC §10, DESIGN, ENGINEERING, README and PLAN.
- [x] User accepted the direction after seeing the native main window (2026-10-13).
- [ ] Remaining screens redrawn with the system (see Open checks).

## Sketch source

**Rebind - new.sketch**, saved 2026-10-12; digest and page map are in [DESIGN](../DESIGN.md#current-source-rebind---newsketch). 124 Color Variables, 68 text styles, 68 layer styles, 192 symbol sources (60 icons), 12 screens × Light/Dark. Foundations board 05 carries the principles and native mapping. The original frames are preserved on `99 · Archive`.

## Implementation and verification

Design only. Agent-observed MCP screenshots after the final edits: Keyboard, Mouse, Trackpad, Magic Mouse empty, paused/permission states, both Keyboard editors, action picker, Trackpad gesture menu, both Settings tabs, component overview and principles boards. Decisions made while building:

- Background blur was removed from control surfaces; only sidebar and menu styles keep a material. This matches the no-Liquid-Glass decision and avoids render artifacts inside components.
- Icons are vector stand-ins named after SF Symbols; `mission.control`, `escape` and `playpause` have no exact SF Symbol and need a native choice.
- Sketch has no variable modes, so components are duplicated per theme under `Light/` and `Dark/`.
- Mouse buttons render as text keycaps; gestures, wheel and movement render as trigger chips.

No build, test, app launch or hardware check was run; none applies to this change. `git diff --check` passes.

## Update 2026-10-13

Icons were replaced with real SF Symbols outlines (80 components, names equal to the symbols used in code). A brand row (logo + app name) was added to every sidebar, and page `05 · Brand` holds the new app icon, 32 pt logo and Menu Bar template. Screens stay English-only; localized duplicates are no longer planned.

## Update 2026-10-13 (later)

Screens 13–18 added: Settings Input, Language, Advanced; profile management; first-run setup; About. The titlebar strip is native, so every screen's content starts 56 pt from the top and the traffic lights use the system size.

## Update 2026-10-14: artifact audit

All 76 screens (38 × Light/Dark) were screenshot-reviewed and checked by script for clipped text, Light/Dark drift and wrong-theme components (none of the latter). Fixed: Banner and Settings Row/Status messages now wrap inside the component instead of running past its edge (screens 03, 08, 09, 13, 21 resized to fit); recording and profile-name hints wrap inside their sheets (07, 26); action fields show the action's own symbol (Mission Control, Open App, Open Web Address, Run Apple Shortcut on 19, 20, 24, 27, 28, 29); the Magic Mouse screen no longer highlights Magic Trackpad too (04); About Light text is centered like Dark (18); the submenu chevron in menu items sits at the trailing edge (33). After the fixes Light and Dark match in geometry and text. The app's `Banner` already wraps its message, so no code change was needed.

## Open checks / dependency

- User has not yet reviewed or accepted the design.
- Not yet redrawn: first-run onboarding, Settings Input/Language/Advanced, profile management, About, remaining Mouse/Magic Mouse editors and action-parameter states, compact-width variants, hover/pressed/focus specimens for every control.
- Contrast, Increase Contrast and Reduce Transparency values are design intent only; native verification is open.
- Dark overview board and several Dark screens were built by the same generator as Light but not all were individually screenshot-reviewed.
- UI-011 glass controls are visually superseded; tasks that adopted them (UI-016, UI-017, UI-019) need reconciliation when the new system is implemented.

## Review

Screens were compared against the original two frames; geometry, type and color match, with components replacing raw layers. Fixed during review: gradient and swatch linkage in shared styles, collapsed icons in stacks, clipped shadows, stretched icons on resized selectors, banner button overflow.

## Next handoff

- **Design:** after user review, redraw the remaining screens listed above using the existing components; add new components only for genuinely new patterns.
- **Code:** request “Implement the soft design system in the main window”, start with tokens (colors, type, radii, shadows) and the Keyboard list, reading components live from Sketch. Do not start before the user confirms the direction on the saved file.
