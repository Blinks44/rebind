#!/bin/bash
# Package with an existing identity; key creation is never part of a release.
set -euo pipefail
exec python3 - "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" <<'PYTHON'
#!/usr/bin/env python3
"""Build with an existing signing identity; never create keys or install a service."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

APP_ROOT = Path(sys.argv[1])
OUTPUT = APP_ROOT / "build" / "release"
# dev.sh honours the same override, so the packaged app is the one just built.
DERIVED_DATA = Path(os.environ.get("REBIND_DERIVED_DATA", APP_ROOT / "build" / "DerivedData"))
KEYCHAIN = os.environ.get("REBIND_SIGN_KEYCHAIN")
# Pin the existing shared development certificate; never silently change signer.
IDENTITY = os.environ.get("REBIND_SIGN_IDENTITY", "69D383553450694A1E9D78650B3FC6E69446BD4F")


def run(*args, quiet=False):
    result = subprocess.run([str(a) for a in args], stdout=subprocess.PIPE if quiet else None,
                            stderr=subprocess.PIPE if quiet else None)
    if result.returncode:
        # Never echo command arguments: keychain commands contain credentials.
        detail = result.stderr.decode(errors="replace").strip() if quiet and result.stderr else ""
        raise RuntimeError(f"{Path(str(args[0])).name} failed (exit {result.returncode})" + (f": {detail}" if detail else ""))
    return result.stdout


def signing_identity():
    args = ["security", "find-identity", "-p", "codesigning"]
    if KEYCHAIN:
        args.append(KEYCHAIN)
    output = run(*args, quiet=True).decode()
    # Self-signed identities may be excluded by -v; exact fingerprint authentication is
    # performed by codesign/native fixture checks, without adding system trust exceptions.
    found = {fingerprint for fingerprint, name in re.findall(r'\d+\) ([A-Fa-f0-9]{40}) "([^"\n]+)"', output)
             if name == IDENTITY or fingerprint.lower() == IDENTITY.lower()}
    if len(found) != 1:
        raise RuntimeError(
            "Expected exactly one signing identity. Import the existing certificate AND private key "
            "from its .p12 backup into Keychain Access. Preserve the "
            "original signing identity. No new certificate was created.")
    return next(iter(found))


def normalize_bundle_permissions(bundle):
    # Xcode/ditto can preserve owner-only modes from an earlier build. Distribution
    # must allow system services and other users to read code and its signing metadata.
    for path in [bundle, *bundle.rglob("*")]:
        if path.is_symlink():
            continue
        mode = path.stat().st_mode
        path.chmod(0o755 if path.is_dir() or mode & 0o111 else 0o644)


def write_appcast(dmg, version):
    # Sparkle signs the finished DMG with the EdDSA key in the login keychain (generate_keys).
    # The appcast is uploaded with the DMG; the app reads it from the latest GitHub release.
    tool = DERIVED_DATA / "SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast"
    if not tool.exists():
        raise RuntimeError("Sparkle tools are missing; run scripts/dev.sh resolve")
    appcast = OUTPUT / "appcast.xml"
    # generate_appcast appends to an existing feed. Each release publishes its own appcast with
    # only its DMG, so an earlier local build must never be listed as an available update.
    appcast.unlink(missing_ok=True)
    release = f"https://github.com/Blinks44/rebind/releases/download/v{version}/"
    with tempfile.TemporaryDirectory(prefix="rebind-appcast-") as staging:
        shutil.copy2(dmg, staging)
        run(tool, "--download-url-prefix", release,
            "--full-release-notes-url", f"https://github.com/Blinks44/rebind/releases/tag/v{version}",
            "--link", "https://github.com/Blinks44/rebind", "-o", appcast, staging, quiet=True)
    return appcast


def main():
    # This command creates public app artifacts, never private signing keys.
    os.umask(0o022)
    if not shutil.which("create-dmg"):
        raise RuntimeError("Install create-dmg once with: brew install create-dmg")
    fingerprint = signing_identity()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    log = OUTPUT / "build.log"
    with log.open("w") as stream:
        result = subprocess.run([str(APP_ROOT / "scripts" / "dev.sh"), "release", "-quiet", "CODE_SIGNING_ALLOWED=NO"], stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f"Release build failed; inspect {log}")
    destination = OUTPUT / "Rebind.app"
    if destination.exists():
        shutil.rmtree(destination)
    run("ditto", DERIVED_DATA / "Build/Products/Release/Rebind.app", destination)
    sign = ["codesign", "--force", "--options", "runtime", "--timestamp=none", "--sign", fingerprint]
    if KEYCHAIN:
        sign.extend(["--keychain", KEYCHAIN])
    # Sparkle is the only embedded framework. Fail rather than silently adding
    # library-validation exceptions if that bundle contract changes.
    frameworks = destination / "Contents/Frameworks"
    sparkle = frameworks / "Sparkle.framework"
    if list(destination.rglob("*.dylib")) or sorted(frameworks.iterdir()) != [sparkle]:
        raise RuntimeError("Review nested dynamic code signing before packaging this bundle")
    normalize_bundle_permissions(destination)
    # Hardened runtime library validation needs Sparkle signed by the app's identity, inside out
    # (https://sparkle-project.org/documentation/sandboxing/#code-signing).
    current = sparkle / "Versions/Current"
    run(*sign, current / "XPCServices/Installer.xpc", quiet=True)
    run(*sign, "--preserve-metadata=entitlements", current / "XPCServices/Downloader.xpc", quiet=True)
    run(*sign, current / "Autoupdate", quiet=True)
    run(*sign, current / "Updater.app", quiet=True)
    run(*sign, sparkle, quiet=True)
    run(*sign, destination, quiet=True)
    for path in [destination, *destination.rglob("*")]:
        if path.is_symlink():
            continue
        mode = path.stat().st_mode
        if not mode & 0o004 or (path.is_dir() and not mode & 0o001):
            raise RuntimeError("Packaged app must be readable by system services and other users")
    run("codesign", "--verify", "--strict", "--deep", destination, quiet=True)
    import plistlib
    info = plistlib.loads((destination / "Contents/Info.plist").read_bytes())
    version = str(info["CFBundleShortVersionString"])
    build = str(info["CFBundleVersion"])
    if not all(re.fullmatch(r"[A-Za-z0-9._-]+", item) for item in [version, build]):
        raise RuntimeError("Invalid version/build for package filename")
    dmg = OUTPUT / f"Rebind-{version}-{build}.dmg"
    with tempfile.TemporaryDirectory(prefix="rebind-dmg-") as staging:
        run("ditto", destination, Path(staging) / "Rebind.app")
        run("create-dmg", "--overwrite", "--volname", "Rebind",
            "--volicon", destination / "Contents/Resources/AppIcon.icns",
            "--background", APP_ROOT / "scripts/dmg/background.tiff",
            "--window-size", "660", "420", "--icon-size", "128", "--text-size", "13",
            "--icon", "Rebind.app", "170", "210", "--hide-extension", "Rebind.app",
            "--app-drop-link", "490", "210", "--no-internet-enable", dmg, staging)
    run(*sign, dmg, quiet=True)
    run("codesign", "--verify", "--strict", dmg, quiet=True)
    run("hdiutil", "verify", dmg, quiet=True)
    run("shasum", "-a", "256", dmg)
    appcast = write_appcast(dmg, version)
    print(f"Signing certificate: {fingerprint}")
    print(f"Package: {dmg}")
    print(f"Appcast: {appcast}")
    print("No app installed or permissions changed.")
    print("This artifact is signed but not notarized. Clean-Mac installation remains unverified.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError) as error:
        print(f"Preparation stopped: {error}", file=sys.stderr)
        sys.exit(1)

PYTHON
