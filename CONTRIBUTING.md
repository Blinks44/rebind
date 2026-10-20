# Contributing to Rebind

Thanks for your interest. Rebind is a small, free macOS app maintained in spare time; clear reports and focused changes help the most.

## Reporting a problem

Open an issue and include:

- your Rebind version/build from **About Rebind**;
- your macOS version and Mac model (Apple silicon or Intel);
- the input device involved (keyboard, mouse model, built-in trackpad, Magic Trackpad or Magic Mouse);
- what you did, what you expected and what happened;
- whether Rebind shows a warning in **Settings → Permissions**.

For a support report, use **Settings → Advanced → Copy Report**. Do not attach your configuration or backups to a public issue. Never paste passwords or other private text. Rebind does not record what you type, and a report does not need it. For security problems, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Proposing a change

For anything larger than a small fix, open an issue first so the approach can be agreed before you spend time on it. Rebind deliberately stays small: one manually selected profile, curated gesture presets, no telemetry and no accounts.

## Building and testing

You need full Xcode with a Swift 6.2+ compiler and a macOS 26+ SDK.

```sh
apps/rebind/scripts/dev.sh build
apps/rebind/scripts/dev.sh test
```

The test run opens a Rebind window for a few minutes while layout tests render; leave it open. See the [development guide](docs/DEVELOPMENT.md) for details.

## Pull requests

- Keep one topic per pull request and describe how you checked it. Say plainly what you could not test, for example hardware you do not own.
- Follow the existing style: Swift 6 strict concurrency, SwiftUI/AppKit, no new dependencies without discussion.
- Anything on the input path must stay synchronous and bounded; read [docs/ENGINEERING.md](docs/ENGINEERING.md) before touching the event tap or the matcher.
- User-facing text goes into the String Catalogs in every supported language. If you cannot translate one, say so in the pull request.
- Add or update tests for behavior you change.

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
