# Publishing Rebind

Maintainer checklist for a public GitHub DMG release and the website. Run commands from the repository root unless stated otherwise. Packaging, source commits, GitHub publication and website deployment are separate operations. Nothing here has been published automatically.

## 1. Finish the candidate

Preserve the [successful general tester report](verification/release-candidate.md#tester-report--2026-10-20). For copy-only changes, repeat affected language/layout checks and a short smoke pass instead of the whole gesture inventory. Resolve or explicitly disclose remaining [release gates](PLAN.md#release-gates), particularly minimum macOS 26 execution, accessibility coverage and same-signer update preservation. Do not claim Intel has been tested when it has not.

Export your configuration before replacing the installed app. Use the shared pinned **Apple Development** certificate for the current local candidate; export its encrypted private-key backup off-device and keep its password separately. The previous Rebind Release backup is a different identity. See [SIGNING](SIGNING.md).

Review the intended source changes and commit them before making a public tag. A tag must identify all source changes included in the tested package, rather than an older HEAD. Do not include local output, personal configuration or private signing files in the commit.

## 2. Set the version and build

In Xcode, choose the **rebind** app target → **General** → **Identity**. For the first stable release use **Version 1.0.0**, with a new **Build** number greater than 1. Keep Debug and Release values consistent; the current signing-alignment candidate is 1.0.0 (3); the copy audit prepared 1.0.0 (2), and the prior candidate is 1.0 (1). Do not change the bundle identifier or signing identity.

Source now uses **1.0.0 (9)**: three-step first run and Sparkle updates ([REL-005](tasks/REL-005-onboarding-and-updates.md)) on top of the window-action repair in build 8 ([FIX-002](tasks/FIX-002-window-action-compatibility.md)). After required checks, agents run `apps/rebind/scripts/release.sh` for every completed app change set and report the verified DMG path for manual installation. Packaging does not install or publish. Agents must increment Build for every new app change set before final verification/handoff under AGENTS; rebuilds of the same changes do not increment it again. For later candidates, increment Build again and use the resulting filename below. Use a stable release tag matching the marketing version: **v1.0.0**. Sparkle compares the **build number** (`CFBundleVersion`): every published update needs a build larger than all earlier published builds, and a user-visible release also gets a new marketing version (for example 1.0.1) and tag. Builds before 9 have only the old manual checker and must be replaced by hand once. Drafts and prereleases are ignored by the app and the website.

For the remaining permission-preservation check, build/install two distinct builds with the same certificate, bundle identifier and Applications location, incrementing the build number. Confirm rules/profiles and actual Accessibility access survive. The self-signed build 1/2 → shared Apple Development build 3 change is a signer transition and may require a fresh grant; it does not test same-signer updates. Use two subsequent Apple Development builds to verify permission preservation.

## 3. Build the distributable

```sh
apps/rebind/scripts/dev.sh test
apps/rebind/scripts/release.sh
```

`release.sh` signs and verifies the app and DMG, verifies image integrity, prints the archive path and SHA-256 and writes `appcast.xml` (the Sparkle feed, EdDSA-signed with the [update signing key](SIGNING.md#update-signing-key)) next to the DMG. It does not install or publish. Install `create-dmg` if needed (`brew install create-dmg`); missing create-dmg now stops packaging, keeping one DMG workflow. Resolve a missing signing identity by restoring its original backup, not generating a replacement.

For version 1.0.0 and build 3, the output is `apps/rebind/build/release/Rebind-1.0.0-3.dmg`. Use the actual filename if your build number differs. Create a checksum file in the same folder:

```sh
cd apps/rebind/build/release
shasum -a 256 Rebind-1.0.0-3.dmg > SHA256SUMS.txt
shasum -a 256 -c SHA256SUMS.txt
```

Test the packaged copy, record its hash/version/OS/device and make no source changes after that final build without rebuilding/rechecking affected areas. Older 1.0/1 hashes in task history do not identify this new artifact.

Current Apple Development candidates are for local testing; public customer distribution is not verified. Do not present the steps below as evidence of supported distribution signing or publish merely because packaging passes.

## 4. Prepare the GitHub release

On [Blinks44/rebind Releases](https://github.com/Blinks44/rebind/releases), choose **Draft a new release**. Select the matching tag at the reviewed, pushed source commit. Use title **Rebind 1.0.0** and adapt [the prepared notes](releases/1.0.0.md), including the actual tested platforms and limitations. Attach the DMG, `SHA256SUMS.txt` and `appcast.xml` as release assets, then **Save draft**. The app reads `releases/latest/download/appcast.xml`, so every stable release must carry its own appcast; its download URL already points at `releases/download/v<version>/<dmg>`, so keep the tag and DMG filename unchanged. GitHub’s automatic source-code archives do not replace the DMG.

Review version, target commit, filenames and checksums before publishing. For a stable release, leave **This is a pre-release** off and set it as the latest release. Publish only after the candidate gates are resolved or accurately limited. If immutable releases are enabled, attach every asset while still a draft. See [GitHub’s release instructions](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

A pre-release is appropriate for unclosed release gates, but it will not appear through the current automatic latest-release lookup. Link that preview explicitly rather than presenting it as a stable app update.

## 5. Check the download and updates

Download the DMG from the published release and verify it against `SHA256SUMS.txt`. Open/install that downloaded copy through the normal macOS path. For this signed, non-notarized candidate, follow [Apple’s Open Anyway instructions](https://support.apple.com/en-us/102445) after the initial blocked launch; do not disable Gatekeeper.

Check launch, saved rules, real permission status and a short binding smoke test. **Check for Updates…** should report that the newest version is installed. The first end-to-end update needs two published Sparkle builds: install the older one, publish the newer one and confirm that Rebind offers, downloads, verifies, installs and relaunches it with rules and Accessibility access preserved. Do not republish different bytes under the same version/asset name: issue a new version and checksum.

## 6. Publish the site and support links

The website now points to `Blinks44/rebind` and `https://rebind.moduix.dev`. It discovers the latest stable release with a DMG and caches the result for up to 10 minutes. Until a suitable release exists or if GitHub is unavailable, Download stays disabled.

From `apps/website`, run:

```sh
pnpm build
pnpm preview
```

Check `/`, `/ru`, `/de`, `/fr`, `/es`, `/zh`: language navigation, actual Download target, FAQ limits, small-screen text and keyboard demo. `preview` is local. When the DMG and support wording are ready, use **pnpm deploy** from that folder to publish to Cloudflare. This requires your Cloudflare account access; deployment is a separate explicit action.

Enable GitHub private vulnerability reporting as described by [GitHub](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository) (Settings → Advanced Security → Private vulnerability reporting); confirm the **Security → Report a vulnerability** route exists. Keep the public bug template, [security policy](../SECURITY.md), [changelog](../CHANGELOG.md) and release notes current. Do not announce broader hardware or platform support than the evidence permits.
