# Proxy Balance Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a personal-use proxy balance mode for codexU, defaulting to Krill relay balance with an in-app login entry and preserving the official Codex quota view.

**Architecture:** Keep parsing and source selection separate from the existing Codex app-server reader. Add a testable `ProxyBalance` parser, a `WKWebView`-backed reader/login surface, and a header mode switch that changes the balance overview while leaving local token stats and the task board intact.

**Tech Stack:** Swift, AppKit, SwiftUI, WebKit, UserDefaults, shell-based Swift parser tests, existing Makefile DMG packaging.

---

## File Structure

- Create `Sources/CodexUsageWidget/ProxyBalance.swift`: pure Foundation models and parser for Krill visible text.
- Create `Tests/ProxyBalanceParserTests.swift`: executable Swift assertions for parser behavior and source-mode persistence helpers.
- Modify `Sources/CodexUsageWidget/main.swift`: load proxy balance snapshots, add mode switch, render proxy balance UI, open login window, and wire WebKit reader.
- Modify `Makefile`: compile all Swift source files, link WebKit, and add a parser test target.
- Modify `README.md` and `README.en.md`: document proxy mode and login behavior after implementation.

### Task 1: Parser Model And Tests

**Files:**
- Create: `Sources/CodexUsageWidget/ProxyBalance.swift`
- Create: `Tests/ProxyBalanceParserTests.swift`
- Modify: `Makefile`

- [ ] **Step 1: Write the failing parser tests**

Create `Tests/ProxyBalanceParserTests.swift` with:

```swift
import Foundation

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual != expected {
        fputs("FAIL: \(message). Expected \(expected), got \(actual)\n", stderr)
        exit(1)
    }
}

func assertClose(_ actual: Double?, _ expected: Double, _ message: String) {
    guard let actual, abs(actual - expected) < 0.0001 else {
        fputs("FAIL: \(message). Expected \(expected), got \(String(describing: actual))\n", stderr)
        exit(1)
    }
}

let personalCenterText = """
今日请求花费
$8.44
套餐$8.47 · 余额$0.00
钱包余额
$0.00
轻享月卡
订阅 #7927
剩余 14 天
到期时间
2026-07-15 21:20:55
本周额度
剩余$554.47 / $600.00
月额度
剩余$1154.47 / $2400.00
"""

let balance = ProxyBalanceParser.parse(text: personalCenterText, sourceURL: "https://www.krill-ai.com/app")
assertEqual(balance.status, .available, "status")
assertClose(balance.todaySpend, 8.44, "today spend")
assertClose(balance.walletBalance, 0.0, "wallet balance")
assertEqual(balance.packageName, "轻享月卡", "package name")
assertClose(balance.packageRemaining, 1154.47, "package remaining prefers largest usable package window")
assertClose(balance.packageLimit, 2400.0, "package limit")
assertEqual(balance.expiresAtText, "2026-07-15 21:20:55", "expires text")

let loggedOut = ProxyBalanceParser.parse(text: "登录 注册 邮箱 密码", sourceURL: "https://www.krill-ai.com/app")
assertEqual(loggedOut.status, .loggedOut, "logged out status")

let apiKeysText = """
Key 费用 请求 Tokens 最近使用 创建时间 状态
Codex nb_TlaEZ $2703.8759 26,486 3,334,841,642 2026-07-01 09:38:57 2026-06-14 21:22:24 正常
5 keys
合计费用 $2856.8138
请求 28,175
Tokens 3,481,064,985
"""

let keyUsage = ProxyBalanceParser.parse(text: apiKeysText, sourceURL: "https://www.krill-ai.com/app/keys")
assertClose(keyUsage.keyUsage?.totalCost, 2856.8138, "key total cost")
assertEqual(keyUsage.keyUsage?.requestCount, 28175, "key request count")
assertEqual(keyUsage.keyUsage?.tokenCount, 3_481_064_985, "key token count")

print("ProxyBalanceParserTests passed")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `rtk make test`

Expected: fail because `test` target and `ProxyBalanceParser` do not exist yet.

- [ ] **Step 3: Implement minimal parser models**

Create `Sources/CodexUsageWidget/ProxyBalance.swift` with:

```swift
import Foundation

enum ProxyBalanceStatus: String, Equatable {
    case available
    case loggedOut
    case unavailable
}

struct ProxyKeyUsage: Equatable {
    let totalCost: Double?
    let requestCount: Int?
    let tokenCount: Int64?
}

struct ProxyBalance: Equatable {
    let status: ProxyBalanceStatus
    let sourceURL: String?
    let todaySpend: Double?
    let walletBalance: Double?
    let packageName: String?
    let packageRemaining: Double?
    let packageLimit: Double?
    let expiresAtText: String?
    let keyUsage: ProxyKeyUsage?
    let message: String?
}
```

Implement `ProxyBalanceParser.parse(text:sourceURL:)` as pure text parsing for the Krill snippets above.

- [ ] **Step 4: Add Makefile test target**

Change `SOURCES` to include all app Swift files, link WebKit, and add:

```make
TEST_BUILD_DIR := .test-build
TEST_SOURCES := Sources/CodexUsageWidget/ProxyBalance.swift Tests/ProxyBalanceParserTests.swift

.PHONY: test

test:
	rm -rf "$(TEST_BUILD_DIR)"
	mkdir -p "$(TEST_BUILD_DIR)"
	swiftc $(TEST_SOURCES) -o "$(TEST_BUILD_DIR)/proxy-balance-tests"
	"$(TEST_BUILD_DIR)/proxy-balance-tests"
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `rtk make test`

Expected: `ProxyBalanceParserTests passed`.

### Task 2: Proxy Reader And Login Window

**Files:**
- Modify: `Sources/CodexUsageWidget/main.swift`
- Modify: `Makefile`

- [ ] **Step 1: Write a failing compile check for missing WebKit wiring**

Run: `rtk make build`

Expected after adding references but before implementation: fail with missing WebKit reader/window types.

- [ ] **Step 2: Add WebKit imports and reader types**

Add `import WebKit` to `main.swift`.

Add `ProxyBalanceReader` that:

- owns a hidden `WKWebView`,
- loads `https://www.krill-ai.com/app`,
- waits briefly for JavaScript-rendered content,
- evaluates `document.body.innerText`,
- parses the text with `ProxyBalanceParser`,
- returns `.loggedOut` when login text is detected,
- returns `.unavailable` when navigation or evaluation fails.

- [ ] **Step 3: Add visible login window**

Add `ProxyLoginWindowController` that:

- opens `https://www.krill-ai.com/app` in a `WKWebView`,
- uses `WKWebsiteDataStore.default()` so the hidden reader and login window share the app-owned session,
- contains no autofill or credential handling,
- calls a completion closure when the window closes so the widget can refresh.

- [ ] **Step 4: Verify build**

Run: `rtk make build`

Expected: app builds and codesigns.

### Task 3: Snapshot And UI Source Switch

**Files:**
- Modify: `Sources/CodexUsageWidget/main.swift`

- [ ] **Step 1: Write the failing compile changes**

Add references to:

```swift
enum BalanceSourceMode: String, CaseIterable, Equatable { case proxy, official }
```

Add `proxyBalance` to `UsageSnapshot` and render a `BalanceSourceSwitch`.

Run: `rtk make build`

Expected: fail until all initializers and views are updated.

- [ ] **Step 2: Update snapshot flow**

Extend `UsageSnapshot` with:

```swift
let proxyBalance: ProxyBalance?
```

Update `.empty`, `replacingTaskBoard`, `CodexUsageReader.load()`, and `dumpJSON`.

Load proxy balance alongside app-server/local usage. Proxy failures must append a short message but not block other data.

- [ ] **Step 3: Add mode persistence**

Add `BalanceSourceMode.storedOrDefault(defaults:)` and `persist(defaults:)`, defaulting to `.proxy`.

- [ ] **Step 4: Render source switch and proxy overview**

In `UsageWidgetView`, add `@State private var sourceMode = BalanceSourceMode.storedOrDefault()`.

In the header, add a segmented picker with `中转站` and `官方`.

In `usageOverviewSection`, branch:

- proxy mode renders proxy balance big number and proxy detail rows,
- official mode renders the existing gauge and 5h/7d windows.

- [ ] **Step 5: Add quick login button**

When proxy mode is selected, show a small login/open button. It calls an app-level login presenter and then refreshes the store after the login window closes.

- [ ] **Step 6: Verify build**

Run: `rtk make build`

Expected: app builds and codesigns.

### Task 4: Documentation And DMG

**Files:**
- Modify: `README.md`
- Modify: `README.en.md`

- [ ] **Step 1: Document proxy mode**

Add concise docs:

- proxy mode is default,
- login button opens in-app Krill login,
- official mode remains available,
- codexU does not read Chrome cookies, saved passwords, or Krill credentials.

- [ ] **Step 2: Run tests**

Run: `rtk make test`

Expected: parser tests pass.

- [ ] **Step 3: Run probe**

Run: `rtk make probe`

Expected: JSON dumps without crashing. Proxy balance may be unavailable until the in-app Krill session is logged in.

- [ ] **Step 4: Build release DMG**

Run: `rtk make release`

Expected:

```text
dist/codexU-<version>-mac-arm64.dmg
dist/codexU-<version>-mac-arm64.dmg.sha256
```

- [ ] **Step 5: Report artifact paths**

Provide the DMG and checksum paths, plus verification commands that passed.

## Self-Review

Spec coverage:

- Mode switch is covered in Task 3.
- Krill-first proxy balance is covered in Tasks 1 through 3.
- Quick login entry is covered in Task 2 and Task 3.
- No Chrome cookie/password access is covered in Task 2 and docs in Task 4.
- Parser tests are covered in Task 1.
- DMG output is covered in Task 4.

Placeholder scan:

- No placeholder steps remain. Each task has exact files, commands, and expected outcomes.

Type consistency:

- `ProxyBalance`, `ProxyBalanceParser`, `ProxyBalanceReader`, `ProxyLoginWindowController`, and `BalanceSourceMode` are named consistently across tasks.
