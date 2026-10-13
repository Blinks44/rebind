#!/bin/bash
# Builds a Release copy of Rebind, signs it with one stable certificate and
# packages it for GitHub Releases: a disk image when `create-dmg` is installed
# (brew install create-dmg), otherwise a zip.
#
# Rebind is not notarized (that needs the paid Apple Developer Program), so macOS
# blocks the first launch until the user allows it in System Settings. Signing
# every release with the SAME certificate still matters: macOS ties the
# Accessibility permission to the signature, and a stable signature lets the
# permission survive updates.
#
#   apps/rebind/scripts/release.sh                 # uses the "Rebind Release" certificate
#   REBIND_SIGN_IDENTITY="Other Name" apps/rebind/scripts/release.sh
set -euo pipefail

app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
identity="${REBIND_SIGN_IDENTITY:-Rebind Release}"
products="$app_root/build/DerivedData/Build/Products/Release"
output="$app_root/build/release"

if ! security find-identity -v -p codesigning | grep -Fq "$identity"; then
    cat >&2 <<EOF
No code-signing certificate named "$identity" was found in your keychain.

Create it once (it is free and stays on your Mac):
  1. Open Keychain Access → Certificate Assistant → Create a Certificate…
  2. Name: $identity · Identity Type: Self-Signed Root · Certificate Type: Code Signing
  3. Tick "Let me override defaults" and set the validity to 3650 days; accept the other defaults.
  4. Export the certificate with its private key (.p12) and keep the backup safe:
     losing it means every user must grant Rebind's permissions again after the next update.
EOF
    exit 1
fi

# Build without Xcode signing, then sign the finished bundle ourselves so the
# result does not depend on a development team or a provisioning profile.
"$app_root/scripts/dev.sh" release -quiet CODE_SIGNING_ALLOWED=NO

app="$products/Rebind.app"
codesign --force --options runtime --timestamp=none --sign "$identity" "$app"
codesign --verify --strict --deep "$app"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Contents/Info.plist")"
mkdir -p "$output"

if command -v create-dmg >/dev/null; then
    # A disk image with the app, an Applications shortcut and an arrow between them.
    archive="$output/Rebind-$version-$build.dmg"
    staging="$(mktemp -d)"
    trap 'rm -rf "$staging"' EXIT
    ditto "$app" "$staging/Rebind.app"
    rm -f "$archive"
    create-dmg --volname "Rebind" --volicon "$app/Contents/Resources/AppIcon.icns" \
        --background "$app_root/scripts/dmg/background.tiff" --window-size 660 400 \
        --icon-size 128 --icon "Rebind.app" 170 190 --app-drop-link 490 190 \
        --hide-extension "Rebind.app" --no-internet-enable "$archive" "$staging" >/dev/null
    codesign --force --timestamp=none --sign "$identity" "$archive"
else
    echo "create-dmg is not installed (brew install create-dmg); packaging a zip instead." >&2
    archive="$output/Rebind-$version-$build.zip"
    rm -f "$archive"
    ditto -c -k --keepParent "$app" "$archive"
fi

echo
echo "Signed with: $identity"
codesign -d -r- "$app" 2>&1 | grep designated
echo "Archive:     $archive"
echo "SHA-256:     $(shasum -a 256 "$archive" | cut -d' ' -f1)"
