import Foundation

@main
struct ProxyBalanceParserTestRunner {
    static func main() {
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
        assertClose(balance.weeklyRemaining, 554.47, "weekly remaining")
        assertClose(balance.weeklyLimit, 600.0, "weekly limit")
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

        let suiteName = "codexU.ProxyBalanceParserTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        assertEqual(BalanceSourceMode.storedOrDefault(defaults: defaults), .proxy, "default source mode")
        BalanceSourceMode.official.persist(defaults: defaults)
        assertEqual(BalanceSourceMode.storedOrDefault(defaults: defaults), .official, "stored source mode")

        let progress = ProxyQuotaProgress(remaining: 541.5, limit: 600)
        assertClose(progress?.availableFraction, 0.9025, "quota progress fraction")
        let overLimitProgress = ProxyQuotaProgress(remaining: 720, limit: 600)
        assertClose(overLimitProgress?.availableFraction, 1.0, "quota progress clamps high values")
        let invalidProgress = ProxyQuotaProgress(remaining: 10, limit: 0)
        assertEqual(invalidProgress == nil, true, "quota progress rejects invalid limit")

        print("ProxyBalanceParserTests passed")
    }

    private static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
        if actual != expected {
            fputs("FAIL: \(message). Expected \(expected), got \(actual)\n", stderr)
            exit(1)
        }
    }

    private static func assertClose(_ actual: Double?, _ expected: Double, _ message: String) {
        guard let actual, abs(actual - expected) < 0.0001 else {
            fputs("FAIL: \(message). Expected \(expected), got \(String(describing: actual))\n", stderr)
            exit(1)
        }
    }
}
