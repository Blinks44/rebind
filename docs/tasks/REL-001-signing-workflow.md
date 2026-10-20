# REL-001: Consistent persistent signing workflow

- Updated: 2026-10-20
- Stage: awaiting_verification (current key backup and runtime update checks)
- Owner: app engineering; implementation complete, verification handoff
- Baseline: main at e070ec9 with existing touch/UI work preserved
- Owned surfaces: apps/rebind/scripts/release.sh, signing docs and this task record only

## Outcome

Both repositories now pin the same existing Apple Development certificate (public fingerprint 69D383553450694A1E9D78650B3FC6E69446BD4F) for installed local test candidates. One release.sh builds/copies/signs/verifies a branded DMG in build/release; no automatic key generation, signer fallback, ZIP fallback, signer-specific output or cross-repository dependency. Existing self-signed keys/backups remain intact; historical results below describe that earlier workflow, superseded for current candidates. Current-key backup and same-signer installed-update checks remain open. Apple Development is not notarized customer distribution acceptance.

## Acceptance and next action

Shell syntax and exact-name/self-signed/missing/ambiguous/substring fixture checks passed. Actual missing-identity invocation stopped before building (exit 1).

On 2026-10-19 the user confirmed there had been no previous Rebind releases. Created the first Rebind Release Code Signing identity in the default user keychain, without changing system trust. Temporary private key/PKCS#12 files were removed after import. Full signed packaging passed. No application code, running app permissions or rules changed. Backup/build/reinstall instructions: [SIGNING](../SIGNING.md).

Inventory review: retain dev.sh, release.sh and the DMG background artwork; each is used. Monny's redundant release wrapper was folded into its release script. Signed package and encrypted .p12 restore/signing verification passed. Next: user copies the private backup off-device and keeps its password separately.

## Final verification — 2026-10-19

Release build and strict app/DMG signature verification passed. Artifact: apps/rebind/build/release/Rebind-1.0-1.dmg; SHA-256 de4736423a5dad77370602fa87822d475d77127e0366f53f931eec69b8f827b2. hdiutil integrity verification also passed. Signer: first Rebind Release identity, fingerprint C72270FF16289C3C8C568B199BED4B4342D3EE69. Existing unrelated source deprecation warnings remain; no source changes were made for this task. Shell syntax, documentation links and git diff --check passed. No app launch, permission change or release publication. Encrypted backup/restore was completed in the follow-up below.

## Verified backup and simple recovery — 2026-10-19

Exported only the exact Rebind identity into encrypted Rebind.p12 in Documents/DeveloperSigning outside both repositories. The password was supplied through a hidden local dialog and is not stored in Git, logs or the backup folder. Imported the backup into an isolated temporary keychain, matched the original fingerprint, signed a copied test executable and verified the signature. Temporary keychain removed; original identity retained. Monny's original key was also migrated and both backups verified. No permanent backup tooling was added. SIGNING.md now contains the same short build/test/release/reinstall workflow as Monny. Remaining user action: off-device backup and separate password storage.


## Shared development signing alignment — 2026-10-20

User explicitly requests one release/install workflow for Monny and Rebind after Monny's local recovery. Owner: current app engineering task; scope is release.sh, build numbers and signing/release documentation. Preserve unrelated edits, app code, design and all existing private keys. Both scripts now pin the same existing Apple Development certificate, use readable public bundle modes and build/release as their only packaging directory. No signing fallback or key creation, extra config file, shared cross-repository dependency, helper installation or permission reset. Monny keeps its native helper security fixtures. Rebind changes signer for the first time, so its existing self-signed installation is not a same-signer update test. Build/package verification is recorded below; Apple Development remains a local test route, not notarization or verified customer distribution.


## Unified default pipeline verified — 2026-10-20

Ordinary apps/rebind/scripts/release.sh, with no identity/output overrides, succeeds using the pinned existing certificate. Artifact apps/rebind/build/release/Rebind-1.0.0-3.dmg; SHA-256 **7441eda84b2465b1d89e8543097bbdccf24e6ad5a97a2681f93c9bbd2d2a023a**. Release build, strict app/DMG signatures and image integrity pass. Independently mounted read-only and ditto-extracted copies retain readable/traversable public modes, valid strict signatures, Hardened Runtime, actual Team ID and expected version/build. Exact-name/fingerprint/missing/substring/ambiguous selector fixtures and shell/Python syntax pass. No new app logic tests: only packaging/signing and build metadata changed; earlier app test results remain dated evidence. No key export or new key, publication, trust change, global permission reset or input/charging command.

Rebind uses the same public-permission normalization and DMG-only dependency check; no extra helper verification script is needed. Before final installation, the Applications copy and production configuration were absent; no existing configuration was overwritten or backup falsely claimed. Installed build 3 in Applications, strict-verified its signature and confirmed the installed executable is running. CUA reports cgWindowNotFound for Rebind, so first-run Accessibility, window, rule delivery and configuration preservation are not claimed. No permission grant/remapping executed by the agent. User opens Rebind, grants Accessibility if required and checks a short smoke scenario. Subsequent development-signed builds must provide the same-signer update test; the old self-signed build 1/2 transition is distinct.


## Current shared identity backup exported — 2026-10-20

User explicitly requests a backup beside the previous exports. Keychain Access My Certificates selects the existing Apple Development identity associated with its private key and exports PKCS#12 to Documents/DeveloperSigning/AppleDevelopment.p12. The resulting file is nonempty (3334 bytes); OpenSSL's empty-password MAC check is rejected. File permissions are restricted to 0600, containing directory remains 0700. No export password is entered/read/stored by the agent, no plaintext key or new identity is created. Old Monny.p12/Rebind.p12 remain unchanged. A second export reaches an existing-file warning and is cancelled, avoiding replacement. Folder README distinguishes current/shared from historical identities and contains no passwords.

This verifies local file creation and rejection of an empty password, not full restore or private-key signing. No password is available to perform that test and it is not requested in chat. User retains the password separately, copies the backup off-device and can perform an isolated restore/signing check later. No application build/runtime/permission changes accompany the backup. No private material or local backup is added to Git.

## Update follow-up — 2026-10-20

Tester reports the subsequent update preserves working configuration/access. Exact old/new build hashes are unspecified; retain as tester evidence. Current Apple Development signing remains the chosen testing route; Developer ID is not planned now. Another-Mac installation and current-key restore/off-device backup remain separate. Menu-opening repair is in [FIX-001](FIX-001-wheel-and-window-regressions.md); publication/site deployment deferred until remaining checks.
