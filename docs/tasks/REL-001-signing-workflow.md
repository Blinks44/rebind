# REL-001: Consistent persistent signing workflow

- Updated: 2026-10-23
- Stage: awaiting_verification (another-Mac/current-signature installation remains open)
- Owner: Unassigned; implementation and local verification released
- Scope: persistent signer selection, release.sh, signing/recovery documentation; no input behavior
- Current handoff: [SIGNING](../SIGNING.md), [STATE](../STATE.md) and the [release queue](../verification/release-candidate.md)

## Outcome and remaining acceptance

Rebind uses one pinned existing Apple Development identity, exact fingerprint/name selection, readable public bundle modes and DMG-only `build/release/` output. Missing/ambiguous identities fail closed; no automatic key generation, trust changes, fallback signer, ZIP fallback or cross-repository script dependency. Preserve the signer and bundle identity for subsequent updates. Apple Development is a non-notarized local testing route, not verified customer distribution.

Tester reports subsequent update preservation (October 20; exact old/new builds unspecified) and current-key restore/off-device backup completion (October 21). Another-Mac/current-signature installation and an identified published Sparkle update remain in the release queue. No old build-3 smoke request remains current.

## Historical self-signed pipeline — 2026-10-19

At baseline `e070ec9`, exact-name/fingerprint/self-signed/missing/ambiguous/substring fixtures and shell syntax pass; missing identity stops before building. First Rebind Release identity was created after confirming no earlier releases; temporary private material removed after keychain import. Release app/DMG signatures and image integrity pass for historical `Rebind-1.0-1.dmg`, SHA-256 `de4736423a5dad77370602fa87822d475d77127e0366f53f931eec69b8f827b2`. Old public signer fingerprint: `C72270FF16289C3C8C568B199BED4B4342D3EE69`.

Encrypted PKCS#12 backup was restored in an isolated temporary keychain; original fingerprint and test-executable signing verified. Temporary keychain removed. No password/private material stored in Git. This self-signed identity was superseded October 20; its backup is not the current recovery source.

## Shared development signing alignment — 2026-10-20

Monny and Rebind aligned on the same existing Apple Development certificate, while keeping standalone release scripts. Current public fingerprint/expiry and recovery procedure are in SIGNING. Rebind’s self-signed build 1/2 → development-signed build 3 is a signer transition; any regrant during it cannot prove a same-signer update defect.

## Unified default pipeline verified — 2026-10-20

Default `apps/rebind/scripts/release.sh` passes Release build, strict app/DMG signatures and image integrity. Historical `apps/rebind/build/release/Rebind-1.0.0-3.dmg`: SHA-256 `7441eda84b2465b1d89e8543097bbdccf24e6ad5a97a2681f93c9bbd2d2a023a`. Read-only mounted/ditto-extracted copies retain readable/traversable modes, Hardened Runtime, expected Team ID/version/build and valid signatures. Selector and shell/Python syntax fixtures pass.

Build 3 installed and executable running verified. CUA could not capture its window, so that observation alone did not establish Accessibility/input/configuration preservation. Later tester acceptance is separate above. No key/trust/global-permission change or publication accompanied packaging.

## Current shared identity backup exported — 2026-10-20

Current private-key identity exported through Keychain Access as encrypted PKCS#12 outside the repositories. Nonempty file, empty-password MAC rejection and owner-only modes verified; no password read/logged by the agent. This established export, not restore. Tester subsequently reports isolated restore/signing verification and off-device copy complete (October 21); password remains separately managed. No private material belongs in Git.

## Next

Use the current package from STATE for any new authorized verification, preserve reported update acceptance and close only the remaining identified distribution/platform cases. Do not reinstall an obsolete historical package merely to repeat a completed smoke check.
