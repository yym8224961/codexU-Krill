# Codex usage and remaining limit notes

Date checked: 2026-06-29.

## Official model

Codex has two materially different accounting paths:

- ChatGPT sign-in: Codex usage follows the ChatGPT workspace, plan, RBAC, retention, and residency settings. The plan exposes usage limits and credits through ChatGPT/Codex account surfaces.
- API key sign-in: Codex usage follows the OpenAI Platform organization and standard API token pricing.

Official Codex pages used:

- https://developers.openai.com/codex/pricing
- https://developers.openai.com/codex/auth
- https://developers.openai.com/codex/app-server
- https://developers.openai.com/codex/cli/slash-commands
- https://developers.openai.com/codex/app/settings

## Account remaining limit

The stable-looking local path is Codex app-server JSON-RPC:

1. Start `codex app-server` over stdio.
2. Send `initialize` with `capabilities.experimentalApi = true`.
3. Send `initialized`.
4. Call:
   - `account/read`
   - `account/rateLimits/read`
   - `account/usage/read`

The generated schema for the installed Codex 0.142.3 runtime includes:

- `GetAccountRateLimitsResponse`
- `RateLimitSnapshot`
- `RateLimitWindow`
- `GetAccountTokenUsageResponse`
- `AccountTokenUsageSummary`

`account/rateLimits/read` returns rolling windows as percentages, not absolute token quota numbers. On this machine it returned:

- primary window: 300 minutes
- secondary window: 10080 minutes
- each window has `usedPercent` and `resetsAt`

So this widget computes account remaining limit as:

```text
remainingPercent = 100 - usedPercent
```

That is a real account-limit percentage from Codex, but it is not an absolute number of turns, messages, or tokens.

## Local token usage

Codex keeps local thread inventory in `~/.codex/state_5.sqlite`. The `threads` table has a `tokens_used` column. This widget uses it for local historical usage:

- lifetime: sum of all `threads.tokens_used`
- today: sum where `threads.updated_at` is after local day start
- last 7 days: sum where `threads.updated_at` is in the current local 7-day window

This is useful for local activity tracking, but it is not the authoritative remaining account quota. A thread can be updated later, so daily grouping is an approximation based on last update time.

## What this widget intentionally avoids

- It does not read `~/.codex/auth.json` token values.
- It does not call private ChatGPT web endpoints directly.
- It does not parse full Codex logs. Logs can include `response.completed` token counts, but they are noisy and may contain sensitive prompt/tool data.

## Current implementation choice

The widget displays both kinds of data separately:

- Account limit remaining: from `account/rateLimits/read`
- Local token usage: from `threads.tokens_used`

If app-server is unavailable, the widget falls back to SQLite-only mode and marks account-limit data as unavailable.
