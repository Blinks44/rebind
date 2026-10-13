# Security

Rebind reads keyboard, mouse and trackpad input to match your bindings, and it needs the macOS Accessibility permission to do so. That makes security reports especially welcome.

## What Rebind does and does not do

- Bindings and settings stay in a local file on your Mac. There is no account, network service, analytics or telemetry.
- Typed text is never stored or logged. The diagnostics window shows only mouse buttons and scrolling, keeps them in memory and clears them when it closes.
- Rebind pauses while macOS Secure Input is active, for example in password fields.
- Released builds are signed by the maintainer with a self-signed certificate and are **not notarized by Apple**. If you prefer not to trust a prebuilt app, build it from source.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use **Security → Report a vulnerability** on the repository's GitHub page (private vulnerability reporting). Include the affected version, your macOS version and the steps to reproduce.

You can expect an acknowledgement within a week. This is a volunteer project, so fixes are made as time allows; you will be told what is planned and credited in the release notes unless you prefer otherwise.

## Supported versions

Only the latest release receives fixes.
