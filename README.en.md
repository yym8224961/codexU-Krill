# codexU

codexU is a macOS desktop widget for tracking proxy balance, OpenAI Codex / ChatGPT Codex quota, token usage, and today's task status. It keeps the information you check most on the desktop, so you can quickly see remaining balance, reset times, and daily work progress.

![codexU desktop widget screenshot](docs/screenshot.png)

## Who It Is For

- Developers who use OpenAI Codex, Codex CLI, or the Codex desktop app every day.
- Users of Krill or similar proxy providers who want their proxy wallet, package quota, and daily spend first.
- ChatGPT Pro / Team users who want a quick view of Codex 5-hour quota, 7-day quota, token usage, and reset times.
- macOS users who want to check Codex status without repeatedly opening a browser or terminal.

## Features

- Defaults to proxy balance mode, with a top `Proxy | Official` switch for the official Codex quota view.
- In proxy mode, reads codexU's own Krill web session and shows wallet balance, package balance, today's request spend, and API key usage summary.
- Provides a quick login button in proxy mode, opening an in-app Krill login window when the session expires.
- Shows remaining and used Codex quota for the 5-hour and 7-day windows, including reset times.
- Summarizes token usage for today, the last 7 days, and lifetime totals with a 7-day trend.
- Builds a daily task board from local Codex threads and enabled Codex automations.
- Groups work into active, pending, scheduled, and done columns.
- Stays on the desktop layer by default, with `Command + U` foreground toggle.
- Includes a native macOS WidgetKit widget for Notification Center or the desktop, showing proxy balance plus weekly and package quota progress.
- Supports Chinese and English UI text. The default language follows the system time zone, and the top `中 | EN` switch can override it.
- Reads data locally and does not upload usage, threads, or account data to a third-party service.

## Keyboard Shortcuts

- `Command + U`: toggle the widget between desktop layer and foreground layer.
- Menu bar gauge icon: same toggle as `Command + U`.
- Top `中 | EN` switch: switch between Chinese and English. Manual selection is kept for the next launch.
- Top `Proxy | Official` switch: switch between proxy balance and official Codex quota. Proxy mode is the default.
- Proxy-mode login button: opens the in-app Krill login window; close it after signing in to refresh.
- System widget: add `codexU` from **Edit Widgets**. Click the widget to open the main app; when the session expires, the widget's `Login` link opens the main app's Krill login window.
- Refresh button: immediately refresh quota, token usage, trend, and task board.
- Close button: quit the widget.
- Drag anywhere on the widget background to reposition it.

## First Install: Privacy & Security

codexU is distributed outside the Mac App Store. On first launch, macOS may block it until you manually allow it:

1. Open `codexU.app` once. If macOS says it cannot be opened, cancel the dialog.
2. Open **System Settings > Privacy & Security**.
3. In the **Security** section, click **Open Anyway** for `codexU.app`.
4. Confirm with Touch ID or your password, then click **Open**.

You can also right-click `codexU.app` in Finder and choose **Open**, then confirm the same security prompt.

codexU needs access to local Codex data under `~/.codex/`. If macOS asks for file or folder access, allow it so the widget can read local usage, threads, and automation metadata.

Proxy mode uses codexU's own `WKWebView` to open the Krill web app and read visible balance text. codexU does not read Chrome cookies, saved browser passwords, or automatically fill or submit login forms.

The WidgetKit widget only reads the local snapshot written by the main app at `~/Library/Application Support/codexU/widget-snapshot.json`. It does not run WebView, read `~/.codex/`, or store login credentials. On first install, or after the main app has not been opened for a while, the widget may show `Open codexU to refresh`.

## Requirements

- macOS 14 or later.
- A local Codex installation.
- Proxy mode requires signing in through codexU's in-app Krill login window.
- Official mode requires a signed-in Codex account for quota data.
- Codex must have been used at least once so `~/.codex/state_5.sqlite` exists.
- Xcode Command Line Tools for building from source.

## Build From Source

```sh
make build
```

Run the app:

```sh
make run
```

Install to `/Applications`:

```sh
make install
```

Inspect the data source output:

```sh
make probe
```

## Package A DMG

```sh
make release
```

Release artifacts are written to `dist/`, for example:

```text
dist/codexU-0.1.5-mac-arm64.dmg
dist/codexU-0.1.5-mac-arm64.dmg.sha256
```

For Developer ID signing and notarization, see [DISTRIBUTION.md](DISTRIBUTION.md).

## Data Sources

- Proxy balance: visible text from the signed-in Krill web page inside codexU's own `WKWebView`.
- System widget: local snapshot file written by the main app.
- Account and quota: `codex app-server` JSON-RPC methods `account/read`, `account/rateLimits/read`, and `account/usage/read`.
- Local token usage: `~/.codex/state_5.sqlite`.
- Today's board: unarchived and archived Codex threads in the local SQLite database.
- Scheduled tasks: enabled automation metadata under `~/.codex/automations/**/automation.toml`.

Current Codex quota APIs expose rolling-window percentages and reset times, not absolute account quota sizes. See [RESEARCH.md](RESEARCH.md) for the data model and fallback behavior.

## FAQ

### Is codexU an official OpenAI product?

No. codexU is an unofficial local macOS utility for reading local Codex app-server responses and local `~/.codex/` data.

### Does codexU upload my Codex threads, usage, or proxy data?

No. codexU reads Codex quota, local SQLite usage, automation metadata, and visible Krill balance text locally. It does not upload that data to a third-party service.

### Does codexU read my Chrome login session?

No. Proxy mode does not read Chrome cookies, browser local storage, or saved passwords. The quick login entry opens codexU's own in-app Krill login window.

### Why does codexU show remaining percentage instead of absolute quota?

The current local Codex API exposes rolling-window usage percentages and reset times, not absolute quota sizes. codexU therefore shows remaining percentages for the 5-hour and 7-day windows.

### Does codexU support Intel Macs?

The default release is an Apple Silicon / arm64 DMG. Intel Macs can build from source, or you can package from a compatible toolchain with `TARGET_TRIPLE="x86_64-apple-macos14.0"`.

## License

MIT. See [LICENSE](LICENSE).
