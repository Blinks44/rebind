# UI-008 — Advanced configuration backup foundation

- Updated: 2026-10-11.
- Stage: `done`; bounded storage foundation only. Advanced UI/runtime acceptance remains separate.
- Owner: Unassigned; `/root` completed/released the bounded storage foundation on 2026-10-11.
- Ownership checked: `main` / `b453d8d`; UI-007 was independently in design during this foundation task and is now released. No Sketch edits or shared catalog changes by this storage task.
- Owned surfaces: new ConfigurationBackup and tests, bounded ConfigurationStore codec/read reuse, this record and scoped evidence/index updates.
- Requirements: SPEC §§9, 12, 15.12; PLAN Phase 7.
- Baseline: `main` / `b453d8d` plus preserved General/Input/Language/design changes; no agent commit.

## Outcome and scope

Prepare validated, bounded local JSON backups for Settings → Advanced. Reading a backup stages a migrated immutable configuration and counts without replacing current storage or activating rules. Export serializes the existing validated configuration. Reuse schema 24, migrations and atomic writes. Native file panels/confirmation/replacement/reset and diagnostics UI depend on UI-007's released design handoff; they are not claimed by this foundation.

## Acceptance

- [x] Current configuration roundtrips without loss of profiles, IDs, selected profile, rules, activation, flags or language/setup preferences.
- [x] Legacy backups migrate in memory; future/corrupt/oversized/invalid/conflicting files are rejected without rewriting source or current storage.
- [x] File reads are bounded before decoding; normal storage and backup validation use one codec.
- [x] Meaningful Swift Testing and native main-window checks/build pass; document exact evidence and limits.

## Design dependency

Dependency resolved 2026-10-11: UI-007 saved/reviewed and released Screens 48–69 with behavior and EN/RU/DE/FR copy in Sketch Foundations. Read the current live source directly through MCP via DESIGN; no separate visual manual or PNG package is required. This storage foundation remains independent of native UI and transaction acceptance.

## Next handoff

Native integration subsequently landed in [UI-007](UI-007-advanced-settings.md); [current evidence](../verification/advanced-settings-native.md) supersedes the earlier next-step recommendation. The foundation remains done; full export/reset/import/restored-binding runtime and accessibility acceptance remain open in UI-007.

## Implementation, checks and review

ConfigurationBackup and bounded ConfigurationStore reuse implemented; [source digests, scope and checks](../verification/advanced-backup-foundation.md). Full suite: **553 tests / zero failures**, Debug build passes, no runtime geometry warnings in the non-inspected run. Temporary AppKit probes removed before final checks. No real backup/reset/import/remapping or Sketch edit/commit. Final source review confirms shared validation/migration and atomic writes; unsupported sources remain unchanged. Native UI and replacement/reset transactions are explicitly outside this completed foundation and remain the next slice.
