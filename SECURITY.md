# Security

Rebind reads keyboard, mouse and trackpad input to match your bindings, and it needs the macOS Accessibility permission to do so. That makes security reports especially welcome.

## What Rebind does and does not do

- Bindings and settings stay in a local file on your Mac. There is no account, cloud configuration service, analytics or telemetry. The explicit Check for Updates command requests public GitHub release metadata without input, settings or device data. It never runs automatically. User-configured actions may open web addresses or run Apple Shortcuts.
- Rebind does not log a history of typed input. Text deliberately saved in an Insert Text rule is stored unencrypted in configuration, exports and backups; do not use it for passwords. The diagnostics window shows only mouse buttons and scrolling, keeps them in memory and clears them when it closes.
- Rebind pauses while macOS Secure Input is active, for example in password fields.
- Released builds are signed with the maintainer’s Apple Development certificate and are **not notarized by Apple**. If you prefer not to trust a prebuilt app, build it from source.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use **Security → Report a vulnerability** on the repository’s GitHub page when private vulnerability reporting is enabled. If that option is unavailable, ask the maintainer to enable a private reporting channel without disclosing the vulnerability publicly. Include the affected version, your macOS version and the steps to reproduce.

You can expect an acknowledgement within a week. This is a volunteer project, so fixes are made as time allows; you will be told what is planned and credited in the release notes unless you prefer otherwise.

## Supported versions

Only the latest release receives fixes.
