# Proxy Balance Mode Design

Date: 2026-07-01

## Goal

codexU should support a personal-use mode that prioritizes the user's relay/provider balance over the official Codex quota. The current official Codex view remains available as a fallback and comparison mode.

## Product Behavior

Add a source switch to the widget header:

- `中转站` / `Proxy`: default selected mode.
- `官方` / `Official`: existing Codex app-server quota mode.

In proxy mode, the main balance area shows Krill relay data first. The primary number should prefer usable package balance, then wallet balance, then a clear unavailable state if neither can be read.

The proxy view should display:

- today's request spend,
- wallet balance,
- package/subscription remaining amount and total amount when present,
- package expiration date when present,
- key-level usage summary when the logged-in web page exposes it.

The existing local token totals, trend chart, and task board stay visible in both modes.

## Quick Login Entry

Proxy mode includes a small login/open button near the balance status. It opens a lightweight in-app Krill login window backed by `WKWebView` at `https://www.krill-ai.com/app` so the user can refresh an expired Krill login session quickly.

The button must not:

- read browser cookies,
- read saved passwords,
- auto-fill credentials,
- submit login forms,
- capture or store Krill credentials.

If proxy data is unavailable because the user is logged out, the empty/error state should include the same login entry and a short message telling the user to log in and refresh.

Opening the user's external browser can be offered as a secondary convenience, but it is not the data path. codexU should not depend on Chrome's profile, cookies, or automation permissions.

## Data Sources

Official mode keeps the existing implementation:

- `codex app-server` for account and rate-limit windows,
- `~/.codex/state_5.sqlite` for local token and thread usage,
- `~/.codex/automations/**/automation.toml` for scheduled tasks.

Proxy mode uses a Krill web session owned by codexU because the relay does not expose the needed balance endpoint to API keys. The first implementation should keep this source isolated behind a `ProxyBalanceReader` so it can be replaced later if Krill exposes a proper API.

The preferred web strategy is:

- keep a hidden or background `WKWebView` using the app's persistent `WKWebsiteDataStore`,
- load `https://www.krill-ai.com/app`,
- evaluate a read-only DOM extraction script after the page settles,
- parse only visible balance and usage text,
- open a visible `WKWebView` login window only when the session is missing or expired.

The reader should produce a small structured model, for example:

- `status`: available, loggedOut, unavailable,
- `todaySpend`,
- `walletBalance`,
- `packageName`,
- `packageRemaining`,
- `packageLimit`,
- `expiresAt`,
- `keyUsage`.

## Architecture

Introduce a separate proxy balance layer instead of mixing web parsing into `CodexUsageReader`.

Suggested units:

- `BalanceSourceMode`: `proxy` or `official`, stored in `UserDefaults`.
- `ProxyBalance`: structured relay balance snapshot.
- `ProxyBalanceReader`: gathers and parses Krill balance data from the app-owned web session.
- `ProxyLoginWindowController`: presents the Krill login `WKWebView` and triggers a refresh after login.
- `UsageSnapshot`: gains optional `proxyBalance`.
- `UsageWidgetView`: renders either proxy or official balance summary based on the selected mode.

The UI should continue to refresh with the existing refresh button. Proxy read failures should not block official quota, local SQLite stats, or task board reads.

## Error Handling

Proxy mode should distinguish:

- logged out or login expired,
- browser/page not available,
- page structure changed,
- no proxy balance data found,
- unsupported environment.

The user-facing message should be short and actionable. The login/open button appears for logged-out and unavailable states.

Official mode keeps current app-server and SQLite diagnostics.

## Testing

Add focused tests for parser behavior before implementation:

- parses Krill personal-center balance text into wallet and package values,
- parses usage-stat text into today's spend and package usage,
- returns `loggedOut` when login prompts or missing account data are detected,
- keeps official snapshot behavior unchanged when proxy parsing fails,
- persists and restores the selected source mode.

The parser should be testable from static text/HTML fixtures so the main logic does not require a live browser session.

## Non-Goals

- No credential storage.
- No cookie or browser profile extraction.
- No automatic login.
- No API-key scraping from the Krill page.
- No publishing-grade generic relay support in this first pass; this is optimized for the user's Krill setup.
