# Phase 4 — System media keys

Scope: SPEC §5 playback actions / A1/A2, §§2, 6–7, 9–12. Implemented with software
checks; **happy-path real-player delivery is user-confirmed** (2026-10-09): mouse/additional-button actions work in different applications, including minimized/background contexts. Exact applications/rules/OS were not restated. No player controlled by the agent; detailed routing/interleaving/cancellation/platform checks remain open.

## Contract

- Shared searchable Audio group: Play / Pause, Next Track, Previous Track. Every
  existing supported trigger/activation can choose the same typed MediaAction;
  no recorded output shortcut or audio-volume capability required.
- Public AppKit `NSEvent.otherEvent` → Quartz CGEvent, IOKit auxiliary-control
  subtype 8 and media codes 16/17/18. Low byte of data1 is zero (no repeat), next
  byte is NX_KEYDOWN/NX_KEYUP, high word is the code; data2 is -1. Legacy phase
  flag bits are retained, all Command/Control/Option/Shift/Fn flags absent.
  This system-media encoding convention needs real OS/player verification;
  native API availability alone does not guarantee delivery on every OS.
- Private-state source, zero local suppression interval, existing synthetic tag,
  complete down/up construction before any posting. At the HID tap, outside the
  UI and capture callback. No media state, titles, application names, queue or
  playback content captured; no extra global monitor or private MediaRemote API.
- Existing worker checks actual posting permission/Secure Input and current
  generation; sender rechecks after preparation. Cancellation/allocation failure
  before the first event means no output. A begun pair always sends its release.
  No synthetic hold, repeated seeking, delay, modifier transitions or restoration.
- macOS chooses the player and its response, which may differ from the frontmost
  app. Next/previous follows the chosen player's media-key semantics (including
  possible restart-current-track behavior). An eligible player and a supported
  command are required; with no receiver or command there may be no effect.
  CGEvent posting has no player acknowledgement. Do not claim a missing receiver
  is detectable or auto-select/launch Music, Spotify or another player.
- Preparation failures get a localized media-specific error; unrelated rules
  remain active and consumed source input is not replayed. No new permission,
  dependency, helper, script, root, preference change or player activation.
- Schema 15 reads 1–14 and keeps all profiles/selection/IDs/actions/activation
  fields. No read-time rewrite; save after a successful user edit. Media payload
  disguised as any older schema (including inactive profiles) is rejected.

## Software verification

Commands/counts/toolchain and research/license decisions are recorded in PLAN.md.
Tests construct real native events without posting, inspect their NSEvent round-trip,
exact codes/phase/repeat/payload/flags/tag/source, and inject output for pair/tap,
allocation failure, cancellation and release completion. Matcher/worker/migration
tests cover exact modifiers, input families, synthetic feedback, no audio-device
requirement, serial output, non-pausing errors, protected contexts, lifecycle and
all-profile byte retention until save. No global media output or real user-store writes.

## Manual check

1. Restart one rebuilt authorized Rebind. In a test profile, map a spare button/key
   to Audio → Play / Pause. Start harmless content in your normal player, invoke
   the rule once, then again: expect pause/resume, one response per activation.
2. Use a playlist with several items for Next/Previous Track. Compare with physical
   media keys if available. Previous may restart the current item according to the
   player. Try a background player and a browser/native player separately; name
   the apps and OS/build when reporting results. No promise all browser pages handle it.
3. Use modifier+button input, double/hold, wheel and cardinal gestures. Verify one
   media action per recognition, intact physical modifier state/ordinary bindings,
   and no fast-forward/rewind hold after release. Check rapid activations and
   simultaneous physical media-key use; synthetic/hardware hold interleaving remains
   unverified and Rebind does not maintain a physical media-key state monitor.
4. With no active player and multiple eligible players, compare macOS routing; no
   forced player selection. Stop/pause/edit/profile/record before queued output,
   and check sleep/Secure Input/permission loss without unexpected late playback.
5. Reopen/save/relaunch existing mouse/Space/audio rules and the new media rules.
   Other locales/VoiceOver, macOS 26/Intel and detailed cancellation/latency remain
   manual gates; compiled code and injected posting are not proof of real playback.
