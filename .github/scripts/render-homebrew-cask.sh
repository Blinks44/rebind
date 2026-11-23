#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version required (without leading v)}"
SHA256="${2:?sha256 required}"

cat <<EOF
cask "rebind" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/Blinks44/rebind/releases/download/v#{version}/Rebind.dmg"
  name "Rebind"
  desc "Remap keys, mouse buttons, trackpad gestures, and Logitech controls"
  homepage "https://rebind.moduix.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :sequoia

  app "Rebind.app"

  zap trash: [
    "~/Library/Application Support/Rebind",
    "~/Library/Caches/blinks44.rebind",
    "~/Library/Preferences/blinks44.rebind.plist",
    "~/Library/Saved Application State/blinks44.rebind.savedState",
  ]

  caveats <<~EOS
    Rebind is open-source software and is not notarized by Apple.
    If Gatekeeper blocks the first launch, clear the quarantine attribute:
      xattr -dr com.apple.quarantine /Applications/Rebind.app
    Rebind also asks for Accessibility permission on first launch.
  EOS
end
EOF
