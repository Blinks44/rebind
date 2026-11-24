#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <version> <dmg-sha256>" >&2
  exit 1
fi

version="$1"
sha256="$2"

if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "error: invalid version: $version" >&2
  exit 1
fi

if ! [[ "$sha256" =~ ^[0-9a-fA-F]{64}$ ]]; then
  echo "error: invalid sha256: $sha256" >&2
  exit 1
fi

sha256=$(printf '%s' "$sha256" | tr '[:upper:]' '[:lower:]')

cat <<CASK
cask "rebind" do
  version "${version}"
  sha256 "${sha256}"

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
CASK
