# Changelog

## 0.1.6

- Fixed WidgetKit registration by preserving the widget extension sandbox entitlement during signing.
- Added a read-only sandbox exception so the system widget can read the main app's local snapshot.

## 0.1.5

- Added a native macOS WidgetKit widget for proxy balance, weekly quota, package quota, wallet balance, and today's usage.
- Added a local widget snapshot file written by the main app so the system widget does not run WebView or read Codex state directly.
- Added `codexu://open` and `codexu://login` deep links for opening the main app and the Krill login window from the widget.

## 0.1.4

- Added Chinese and English UI text support.
- Default language now follows the system time zone: Chinese for China/Hong Kong/Macau/Taiwan time zones, English otherwise.
- Added a top bar `中 | EN` language switch that persists the manual selection.

## 0.1.3

- Added the app icon to the widget header.
- Moved account status into a right-side pill next to the plan badge.
- Updated the README screenshot for the new header layout.

## 0.1.2

- Added local desktop widget UI for Codex quota, token usage, trend, and task board.
- Added `Command + U` foreground/desktop layer toggle.
- Added DMG packaging, checksum generation, signing hooks, and notarization helper.
- Added local data source probe command.
