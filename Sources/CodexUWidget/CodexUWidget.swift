import SwiftUI
import WidgetKit

struct CodexUWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CodexUWidgetSnapshot
}

struct CodexUWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CodexUWidgetEntry {
        CodexUWidgetEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (CodexUWidgetEntry) -> Void) {
        completion(CodexUWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CodexUWidgetEntry>) -> Void) {
        let entry = CodexUWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore.read())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct CodexUWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: CodexUWidgetEntry
    private let language = CodexUWidgetLanguage.automatic

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                CodexUMediumWidget(snapshot: entry.snapshot, language: language)
            default:
                CodexUSmallWidget(snapshot: entry.snapshot, language: language)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.12),
                    Color(red: 0.10, green: 0.16, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: CodexUWidgetConstants.openURL))
    }
}

struct CodexUSmallWidget: View {
    let snapshot: CodexUWidgetSnapshot
    let language: CodexUWidgetLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            WidgetHeader(snapshot: snapshot, language: language, compact: true)
            Spacer(minLength: 0)
            Text(primaryText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)

            if shouldShowLogin {
                WidgetLoginLink(language: language)
            } else {
                VStack(spacing: 7) {
                    if snapshot.sourceMode == .official {
                        WidgetProgressRow(
                            title: "5h",
                            value: formatPercent(snapshot.official?.primaryRemainingPercent),
                            progress: officialPrimaryProgress,
                            tint: Color(red: 0.42, green: 0.73, blue: 0.58),
                            compact: true
                        )
                        WidgetProgressRow(
                            title: "7d",
                            value: formatPercent(snapshot.official?.secondaryRemainingPercent),
                            progress: officialSecondaryProgress,
                            tint: Color(red: 0.36, green: 0.61, blue: 0.86),
                            compact: true
                        )
                    } else {
                        WidgetProgressRow(
                            title: language.text("周", "Week"),
                            value: weeklyValue,
                            progress: proxy?.weeklyProgress,
                            tint: Color(red: 0.42, green: 0.73, blue: 0.58),
                            compact: true
                        )
                        WidgetProgressRow(
                            title: language.text("套餐", "Pack"),
                            value: packageValue,
                            progress: proxy?.packageProgress,
                            tint: Color(red: 0.93, green: 0.67, blue: 0.24),
                            compact: true
                        )
                    }
                }
            }
        }
        .padding(14)
    }

    private var proxy: WidgetProxySnapshot? { snapshot.proxy }

    private var primaryText: String {
        if snapshot.sourceMode == .official {
            return formatPercent(snapshot.official?.primaryRemainingPercent)
        }
        return proxy?.primaryText ?? "--"
    }

    private var subtitle: String {
        if snapshot.sourceMode == .official {
            return language.text("官方 5h 剩余额度", "Official 5h remaining")
        }
        if let proxy, proxy.status != .available {
            return proxy.message ?? language.text("打开 codexU 刷新", "Open codexU to refresh")
        }
        return proxy?.packageName ?? language.text("中转站余额", "Proxy balance")
    }

    private var shouldShowLogin: Bool {
        snapshot.sourceMode == .proxy && proxy?.status != .available
    }

    private var weeklyValue: String {
        formatQuotaValue(remaining: proxy?.weeklyRemaining, limit: proxy?.weeklyLimit)
    }

    private var packageValue: String {
        formatQuotaValue(remaining: proxy?.packageRemaining, limit: proxy?.packageLimit)
    }

    private var officialPrimaryProgress: ProxyQuotaProgress? {
        ProxyQuotaProgress(remaining: snapshot.official?.primaryRemainingPercent, limit: 100)
    }

    private var officialSecondaryProgress: ProxyQuotaProgress? {
        ProxyQuotaProgress(remaining: snapshot.official?.secondaryRemainingPercent, limit: 100)
    }
}

struct CodexUMediumWidget: View {
    let snapshot: CodexUWidgetSnapshot
    let language: CodexUWidgetLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeader(snapshot: snapshot, language: language, compact: false)

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(primaryText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(primaryLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                    if shouldShowLogin {
                        WidgetLoginLink(language: language)
                            .padding(.top, 4)
                    }
                }
                .frame(width: 120, alignment: .leading)

                VStack(spacing: 8) {
                    if snapshot.sourceMode == .official {
                        WidgetProgressRow(
                            title: language.text("5 小时窗口", "5-hour window"),
                            value: formatPercent(snapshot.official?.primaryRemainingPercent),
                            progress: officialPrimaryProgress,
                            tint: Color(red: 0.42, green: 0.73, blue: 0.58),
                            compact: false
                        )
                        WidgetProgressRow(
                            title: language.text("7 天窗口", "7-day window"),
                            value: formatPercent(snapshot.official?.secondaryRemainingPercent),
                            progress: officialSecondaryProgress,
                            tint: Color(red: 0.36, green: 0.61, blue: 0.86),
                            compact: false
                        )
                    } else {
                        WidgetProgressRow(
                            title: language.text("本周额度", "Weekly quota"),
                            value: weeklyValue,
                            progress: proxy?.weeklyProgress,
                            tint: Color(red: 0.42, green: 0.73, blue: 0.58),
                            compact: false
                        )
                        WidgetProgressRow(
                            title: language.text("套餐额度", "Package quota"),
                            value: packageValue,
                            progress: proxy?.packageProgress,
                            tint: Color(red: 0.93, green: 0.67, blue: 0.24),
                            compact: false
                        )
                    }
                }
            }

            HStack(spacing: 8) {
                WidgetMetricTile(title: language.text("今日花费", "Today spend"), value: formatCurrency(proxy?.todaySpend), tint: Color(red: 0.93, green: 0.67, blue: 0.24))
                WidgetMetricTile(title: language.text("钱包", "Wallet"), value: formatCurrency(proxy?.walletBalance), tint: Color(red: 0.36, green: 0.61, blue: 0.86))
                WidgetMetricTile(title: language.text("Tokens", "Tokens"), value: formatTokens(snapshot.local?.todayTokens), tint: Color(red: 0.42, green: 0.73, blue: 0.58))
            }
        }
        .padding(14)
    }

    private var proxy: WidgetProxySnapshot? { snapshot.proxy }

    private var primaryText: String {
        if snapshot.sourceMode == .official {
            return formatPercent(snapshot.official?.primaryRemainingPercent)
        }
        return proxy?.primaryText ?? "--"
    }

    private var primaryLabel: String {
        if snapshot.sourceMode == .official {
            return language.text("官方 5h 剩余额度", "Official 5h remaining")
        }
        if let expiresAt = proxy?.expiresAtText {
            return language.text("到期 \(expiresAt)", "Expires \(expiresAt)")
        }
        return proxy?.packageName ?? language.text("中转站余额", "Proxy balance")
    }

    private var shouldShowLogin: Bool {
        snapshot.sourceMode == .proxy && proxy?.status != .available
    }

    private var weeklyValue: String {
        formatQuotaValue(remaining: proxy?.weeklyRemaining, limit: proxy?.weeklyLimit)
    }

    private var packageValue: String {
        formatQuotaValue(remaining: proxy?.packageRemaining, limit: proxy?.packageLimit)
    }

    private var officialPrimaryProgress: ProxyQuotaProgress? {
        ProxyQuotaProgress(remaining: snapshot.official?.primaryRemainingPercent, limit: 100)
    }

    private var officialSecondaryProgress: ProxyQuotaProgress? {
        ProxyQuotaProgress(remaining: snapshot.official?.secondaryRemainingPercent, limit: 100)
    }
}

struct WidgetHeader: View {
    let snapshot: CodexUWidgetSnapshot
    let language: CodexUWidgetLanguage
    let compact: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: snapshot.sourceMode == .proxy ? "network" : "gauge.with.dots.needle.67percent")
                .font(.system(size: compact ? 12 : 13, weight: .bold))
                .foregroundStyle(Color(red: 0.42, green: 0.73, blue: 0.58))
            Text("codexU")
                .font(.system(size: compact ? 13 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer(minLength: 4)
            Text(statusText)
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
        }
    }

    private var statusText: String {
        if snapshot.sourceMode == .official {
            return language.text("官方", "Official")
        }
        if isStale {
            return language.text("需刷新", "Refresh")
        }
        return snapshot.proxy?.statusText ?? language.text("读取中", "Loading")
    }

    private var isStale: Bool {
        Date().timeIntervalSince(snapshot.refreshedAt) > 60 * 60
    }
}

struct WidgetProgressRow: View {
    let title: String
    let value: String
    let progress: ProxyQuotaProgress?
    let tint: Color
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 5) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: compact ? 9 : 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(value)
                    .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.white.opacity(0.14))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(tint)
                        .frame(width: barWidth(in: geometry.size.width))
                }
            }
            .frame(height: compact ? 5 : 6)
        }
    }

    private func barWidth(in width: CGFloat) -> CGFloat {
        guard let progress else { return 0 }
        let filled = width * CGFloat(progress.availableFraction)
        return progress.availableFraction <= 0 ? 0 : max(4, filled)
    }
}

struct WidgetMetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.10))
        )
    }
}

struct WidgetLoginLink: View {
    let language: CodexUWidgetLanguage

    var body: some View {
        Link(destination: URL(string: CodexUWidgetConstants.loginURL)!) {
            Label(language.text("登录", "Login"), systemImage: "person.crop.circle.badge.checkmark")
                .font(.system(size: 10, weight: .bold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(Color(red: 0.42, green: 0.73, blue: 0.58))
                .lineLimit(1)
        }
    }
}

enum CodexUWidgetLanguage {
    case zh
    case en

    static var automatic: CodexUWidgetLanguage {
        let chineseTimeZones: Set<String> = [
            "Asia/Shanghai",
            "Asia/Chongqing",
            "Asia/Harbin",
            "Asia/Urumqi",
            "Asia/Hong_Kong",
            "Asia/Macau",
            "Asia/Taipei"
        ]
        return chineseTimeZones.contains(TimeZone.current.identifier) ? .zh : .en
    }

    func text(_ zh: String, _ en: String) -> String {
        self == .zh ? zh : en
    }
}

private func formatQuotaValue(remaining: Double?, limit: Double?) -> String {
    guard let remaining, let limit else { return "--" }
    return "\(formatCurrencyCompactWidget(remaining)) / \(formatCurrencyCompactWidget(limit))"
}

private func formatCurrency(_ value: Double?) -> String {
    guard let value else { return "--" }
    return String(format: "$%.2f", value)
}

private func formatCurrencyCompactWidget(_ value: Double?) -> String {
    guard let value else { return "--" }
    let absValue = abs(value)
    if absValue >= 1_000 {
        return String(format: "$%.1fK", value / 1_000)
    }
    return String(format: "$%.0f", value)
}

private func formatPercent(_ value: Double?) -> String {
    guard let value else { return "--" }
    return "\(Int(value.rounded()))%"
}

private func formatTokens(_ value: Int64?) -> String {
    guard let value else { return "--" }
    let absValue = abs(Double(value))
    if absValue >= 1_000_000 {
        return String(format: "%.1fM", Double(value) / 1_000_000)
    }
    if absValue >= 1_000 {
        return String(format: "%.1fK", Double(value) / 1_000)
    }
    return "\(value)"
}

@main
struct CodexUWidget: Widget {
    let kind = CodexUWidgetConstants.kind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodexUWidgetProvider()) { entry in
            CodexUWidgetView(entry: entry)
        }
        .configurationDisplayName("codexU")
        .description("Codex and Krill usage")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
