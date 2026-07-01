import Foundation

enum BalanceSourceMode: String, CaseIterable, Equatable {
    case proxy
    case official

    private static let storageKey = "codexU.balanceSourceMode"

    static func storedOrDefault(defaults: UserDefaults = .standard) -> BalanceSourceMode {
        guard let rawValue = defaults.string(forKey: storageKey),
              let mode = BalanceSourceMode(rawValue: rawValue)
        else { return .proxy }
        return mode
    }

    func persist(defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.storageKey)
    }
}

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

    static func unavailable(_ message: String, sourceURL: String? = nil) -> ProxyBalance {
        ProxyBalance(
            status: .unavailable,
            sourceURL: sourceURL,
            todaySpend: nil,
            walletBalance: nil,
            packageName: nil,
            packageRemaining: nil,
            packageLimit: nil,
            expiresAtText: nil,
            keyUsage: nil,
            message: message
        )
    }

    static func loggedOut(sourceURL: String? = nil) -> ProxyBalance {
        ProxyBalance(
            status: .loggedOut,
            sourceURL: sourceURL,
            todaySpend: nil,
            walletBalance: nil,
            packageName: nil,
            packageRemaining: nil,
            packageLimit: nil,
            expiresAtText: nil,
            keyUsage: nil,
            message: "Krill login required"
        )
    }
}

enum ProxyBalanceParser {
    static func parse(text: String, sourceURL: String?) -> ProxyBalance {
        let lines = normalizedLines(text)
        let joined = lines.joined(separator: "\n")

        if looksLoggedOut(joined) {
            return .loggedOut(sourceURL: sourceURL)
        }

        let todaySpend = currencyAfter(label: "今日请求花费", in: lines)
        let walletBalance = currencyAfter(label: "钱包余额", in: lines)
        let packageInfo = bestPackageInfo(in: joined)
        let expiresAtText = textAfter(label: "到期时间", in: lines)
        let packageName = packageName(in: lines)
        let keyUsage = parseKeyUsage(from: joined)

        let hasData = todaySpend != nil
            || walletBalance != nil
            || packageInfo.remaining != nil
            || keyUsage != nil

        guard hasData else {
            return .unavailable("Krill balance data not found", sourceURL: sourceURL)
        }

        return ProxyBalance(
            status: .available,
            sourceURL: sourceURL,
            todaySpend: todaySpend,
            walletBalance: walletBalance,
            packageName: packageName,
            packageRemaining: packageInfo.remaining,
            packageLimit: packageInfo.limit,
            expiresAtText: expiresAtText,
            keyUsage: keyUsage,
            message: nil
        )
    }

    private static func normalizedLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func looksLoggedOut(_ text: String) -> Bool {
        let hasLoginWords = text.contains("登录") && (text.contains("密码") || text.contains("邮箱"))
        let hasBalanceWords = text.contains("钱包余额") || text.contains("今日请求花费") || text.contains("API Keys")
        return hasLoginWords && !hasBalanceWords
    }

    private static func currencyAfter(label: String, in lines: [String]) -> Double? {
        guard let index = lines.firstIndex(where: { $0.contains(label) }) else { return nil }
        for line in lines.dropFirst(index + 1).prefix(3) {
            if let value = firstCurrency(in: line) {
                return value
            }
        }
        return nil
    }

    private static func textAfter(label: String, in lines: [String]) -> String? {
        guard let index = lines.firstIndex(where: { $0.contains(label) }),
              lines.indices.contains(index + 1)
        else { return nil }
        return lines[index + 1]
    }

    private static func packageName(in lines: [String]) -> String? {
        let ignored = ["世界杯奖励", "兑换码", "钱包余额", "今日请求花费"]
        for index in lines.indices.reversed() where lines[index].contains("订阅 #") && index > 0 {
            let candidate = lines[index - 1]
            if !ignored.contains(candidate) {
                return candidate
            }
        }
        return nil
    }

    private static func bestPackageInfo(in text: String) -> (remaining: Double?, limit: Double?) {
        let pattern = #"剩余\s*\$([0-9,]+(?:\.[0-9]+)?)\s*/\s*\$([0-9,]+(?:\.[0-9]+)?)"#
        let matches = regexMatches(pattern: pattern, in: text)
        let values = matches.compactMap { match -> (Double, Double)? in
            guard match.count >= 3,
                  let remaining = parseDouble(match[1]),
                  let limit = parseDouble(match[2])
            else { return nil }
            return (remaining, limit)
        }
        return values.max { $0.1 < $1.1 } ?? (nil, nil)
    }

    private static func parseKeyUsage(from text: String) -> ProxyKeyUsage? {
        let totalCost = firstCaptureDouble(pattern: #"合计费用\s*\$([0-9,]+(?:\.[0-9]+)?)"#, in: text)
        let requests = firstCaptureInt(pattern: #"请求\s*([0-9,]+)"#, in: text)
        let tokens = firstCaptureInt64(pattern: #"Tokens\s*([0-9,]+)"#, in: text)

        guard totalCost != nil || requests != nil || tokens != nil else {
            return nil
        }

        return ProxyKeyUsage(totalCost: totalCost, requestCount: requests, tokenCount: tokens)
    }

    private static func firstCurrency(in text: String) -> Double? {
        firstCaptureDouble(pattern: #"\$([0-9,]+(?:\.[0-9]+)?)"#, in: text)
    }

    private static func firstCaptureDouble(pattern: String, in text: String) -> Double? {
        guard let value = regexMatches(pattern: pattern, in: text).first?.dropFirst().first else {
            return nil
        }
        return parseDouble(value)
    }

    private static func firstCaptureInt(pattern: String, in text: String) -> Int? {
        guard let value = regexMatches(pattern: pattern, in: text).first?.dropFirst().first else {
            return nil
        }
        return Int(value.replacingOccurrences(of: ",", with: ""))
    }

    private static func firstCaptureInt64(pattern: String, in text: String) -> Int64? {
        guard let value = regexMatches(pattern: pattern, in: text).first?.dropFirst().first else {
            return nil
        }
        return Int64(value.replacingOccurrences(of: ",", with: ""))
    }

    private static func parseDouble(_ value: String) -> Double? {
        Double(value.replacingOccurrences(of: ",", with: ""))
    }

    private static func regexMatches(pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).map { result in
            (0..<result.numberOfRanges).compactMap { index in
                let range = result.range(at: index)
                guard let swiftRange = Range(range, in: text) else { return nil }
                return String(text[swiftRange])
            }
        }
    }
}
