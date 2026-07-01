# codexU-Krill

codexU-Krill is a personal macOS usage widget for Codex users who primarily care about their Krill proxy balance. It keeps Krill balance, official Codex quota, local token usage, today's task board, and a native WidgetKit widget in one small desktop app.

![codexU-Krill desktop widget screenshot](docs/screenshot.png)

## Highlights

- **Krill first**: opens in `Proxy` mode by default and shows wallet balance, today's spend, weekly quota, package quota, expiration, and API key usage summary.
- **Official quota still available**: the top `Proxy | Official` switch keeps the original Codex 5-hour and 7-day quota view one click away.
- **Progress bars for quotas**: weekly and package quota are rendered as compact progress bars.
- **Quick login**: if the Krill session expires, open the in-app Krill login window from either the main app or the system widget.
- **Native WidgetKit widget**: add `codexU` to Notification Center or the desktop. Small shows balance and quota progress; medium adds wallet, today spend, and local tokens.
- **Local Codex stats**: reads local Codex state for today, last 7 days, lifetime tokens, and today's task board.
- **Desktop-friendly**: the main window stays on the desktop layer by default, with `Command + U` to bring it forward.
- **Chinese and English UI**: language follows the system time zone by default and can be switched manually.

## Install

Download the Apple Silicon build from Releases:

[Download the latest DMG](https://github.com/yym8224961/codexU-Krill/releases/latest)

Steps:

1. Open `codexU-0.1.6-mac-arm64.dmg`.
2. Drag `codexU.app` into `Applications`.
3. Open codexU from `Applications`.
4. If macOS blocks the app, go to **System Settings > Privacy & Security** and click **Open Anyway**.

After the first launch, the main app writes the local snapshot used by WidgetKit. You can then add `codexU` from macOS **Edit Widgets**.

## Usage

- `Command + U`: toggle between desktop layer and foreground layer.
- Menu bar gauge icon: same foreground toggle.
- `Proxy | Official`: switch between Krill proxy balance and official Codex quota.
- `中 | EN`: switch interface language.
- Refresh button: refresh official quota, local stats, task board, and Krill balance.
- Login button: open the in-app Krill login window; close the window after signing in to refresh.
- System widget: click the widget to open the main app. If the session expires, click `Login` to open the Krill login window.

## Data Sources And Privacy

codexU-Krill processes data locally:

- Krill proxy balance: visible text from the signed-in Krill page inside codexU's own `WKWebView`.
- WidgetKit widget: local snapshot written by the main app at `~/Library/Application Support/codexU/widget-snapshot.json`.
- Official Codex quota: local `codex app-server` account and rate-limit data.
- Local token usage: `~/.codex/state_5.sqlite`.
- Today's task board: local Codex threads plus enabled automations metadata.

It does not:

- read Chrome or Safari cookies,
- read saved browser passwords,
- store or upload Krill credentials,
- auto-fill or submit login forms,
- upload Codex threads, usage, account data, or proxy balance.

## Requirements

- macOS 14 or later.
- Apple Silicon Mac for the default release DMG.
- A local Codex installation that has been used at least once, so `~/.codex/state_5.sqlite` exists.
- Krill mode requires signing in through codexU's in-app Krill login window.
- Official mode requires a signed-in local Codex account for quota data.
- Xcode Command Line Tools for building from source.

## Build From Source

```sh
make build
```

Run:

```sh
make run
```

Inspect local data source output:

```sh
make probe
```

Package a DMG:

```sh
make release
```

Example artifacts:

```text
dist/codexU-0.1.6-mac-arm64.dmg
dist/codexU-0.1.6-mac-arm64.dmg.sha256
```

## FAQ

### Why does the system widget say "Open codexU to refresh"?

The WidgetKit widget does not run WebView or read Codex data directly. Open the main app once so it can refresh and write the local widget snapshot.

### Why can't I find codexU in the system widget gallery?

Make sure you installed `0.1.6` or later, then open codexU once from `/Applications`. Version `0.1.5` lost the Widget extension sandbox entitlement during packaging, so macOS did not register it in the widget gallery.

### Why use an in-app Krill login window?

Krill does not expose the required account-balance data through API-key permissions. This fork reads visible balance text from codexU's own `WKWebView` session, without touching browser cookies or saved passwords.

### Is this an official OpenAI product?

No. codexU-Krill is a personal fork and local macOS utility for viewing Krill proxy balance and local Codex usage.

### Does it support Intel Macs?

The default release is arm64. Intel Macs can build from source or package with:

```sh
TARGET_TRIPLE="x86_64-apple-macos14.0" make release
```

## License

MIT. See [LICENSE](LICENSE).
