import Foundation

enum CodexUWidgetConstants {
    static let kind = "CodexUWidget"
    static let openURL = "codexu://open"
    static let loginURL = "codexu://login"
}

struct WidgetOfficialSnapshot: Codable, Equatable {
    let primaryRemainingPercent: Double?
    let primaryUsedPercent: Double?
    let primaryResetsAt: Date?
    let secondaryRemainingPercent: Double?
    let secondaryUsedPercent: Double?
    let secondaryResetsAt: Date?
}

struct WidgetLocalSnapshot: Codable, Equatable {
    let todayTokens: Int64?
    let sevenDayTokens: Int64?
    let lifetimeTokens: Int64?
}

struct WidgetProxySnapshot: Codable, Equatable {
    let status: ProxyBalanceStatus
    let primaryText: String
    let statusText: String
    let message: String?
    let walletBalance: Double?
    let todaySpend: Double?
    let weeklyRemaining: Double?
    let weeklyLimit: Double?
    let packageName: String?
    let packageRemaining: Double?
    let packageLimit: Double?
    let expiresAtText: String?
    let keyUsageCost: Double?
    let keyRequestCount: Int?

    var weeklyProgress: ProxyQuotaProgress? {
        ProxyQuotaProgress(remaining: weeklyRemaining, limit: weeklyLimit)
    }

    var packageProgress: ProxyQuotaProgress? {
        ProxyQuotaProgress(remaining: packageRemaining, limit: packageLimit)
    }
}

struct CodexUWidgetSnapshot: Codable, Equatable {
    static let schemaVersion = 1

    let schemaVersion: Int
    let refreshedAt: Date
    let sourceMode: BalanceSourceMode
    let proxy: WidgetProxySnapshot?
    let official: WidgetOfficialSnapshot?
    let local: WidgetLocalSnapshot?
    let message: String?

    init(
        schemaVersion: Int = CodexUWidgetSnapshot.schemaVersion,
        refreshedAt: Date,
        sourceMode: BalanceSourceMode,
        proxy: WidgetProxySnapshot?,
        official: WidgetOfficialSnapshot?,
        local: WidgetLocalSnapshot?,
        message: String?
    ) {
        self.schemaVersion = schemaVersion
        self.refreshedAt = refreshedAt
        self.sourceMode = sourceMode
        self.proxy = proxy
        self.official = official
        self.local = local
        self.message = message
    }

    static var empty: CodexUWidgetSnapshot {
        CodexUWidgetSnapshot(
            refreshedAt: Date(),
            sourceMode: .proxy,
            proxy: WidgetProxySnapshot(
                status: .unavailable,
                primaryText: "--",
                statusText: "打开 codexU 刷新",
                message: "打开 codexU 刷新",
                walletBalance: nil,
                todaySpend: nil,
                weeklyRemaining: nil,
                weeklyLimit: nil,
                packageName: nil,
                packageRemaining: nil,
                packageLimit: nil,
                expiresAtText: nil,
                keyUsageCost: nil,
                keyRequestCount: nil
            ),
            official: nil,
            local: nil,
            message: "打开 codexU 刷新"
        )
    }
}

enum WidgetSnapshotCodec {
    static func encode(_ snapshot: CodexUWidgetSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    static func decode(_ data: Data) throws -> CodexUWidgetSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CodexUWidgetSnapshot.self, from: data)
    }
}

enum WidgetSnapshotStore {
    static let directoryName = "codexU"
    static let fileName = "widget-snapshot.json"

    static func snapshotURL(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        return base
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }

    static func read(fileManager: FileManager = .default) -> CodexUWidgetSnapshot {
        let url = snapshotURL(fileManager: fileManager)
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? WidgetSnapshotCodec.decode(data)
        else { return .empty }
        return snapshot
    }

    static func write(_ snapshot: CodexUWidgetSnapshot, fileManager: FileManager = .default) throws {
        let url = snapshotURL(fileManager: fileManager)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try WidgetSnapshotCodec.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }
}
