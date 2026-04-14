import Foundation

enum AppLanguage: String, Codable, CaseIterable {
    case zh
    case en
}

enum PanelTheme: String, Codable {
    case system
    case light
    case dark
}

enum PetDisplaySize: String, Codable, CaseIterable {
    case small
    case medium
    case large

    var scale: CGFloat {
        switch self {
        case .small:
            return 0.88
        case .medium:
            return 1.0
        case .large:
            return 1.18
        }
    }
}

enum PetKind: String, Codable, CaseIterable {
    case bugcat
    case trae
    case codex
    case claudecode

    var displayName: String {
        switch self {
        case .bugcat:
            return "BugCat"
        case .trae:
            return "TRAE SOLO"
        case .codex:
            return "Codex"
        case .claudecode:
            return "Claude Code"
        }
    }
}

enum CodingToolKind: String, Codable, CaseIterable {
    case trae
    case codex
    case claudecode
    case xcode
    case vscode
    case cursor
    case other

    var isCodingApp: Bool {
        self != .other
    }
}

enum PetLevel: Int, Codable, CaseIterable {
    case one = 1
    case two = 2
    case three = 3

    var displayLabel: String {
        "Lv.\(rawValue)"
    }
}

enum PetState: String {
    case idle
    case watching
    case focused
    case chaotic
}

enum SpeechKind {
    case state
    case levelUp
}

struct ActivityReading {
    let frontmostAppName: String
    let frontmostBundleIdentifier: String?
    let windowTitle: String
    let idleSeconds: TimeInterval
    let sampleDate: Date
    let isCodingApp: Bool
    let activeCodingTool: CodingToolKind
}

struct PetSpeechState {
    let message: String
    let kind: SpeechKind
    let visibleUntil: Date
}

struct PetStateUpdate {
    let state: PetState
    let appName: String
    let windowTitle: String
    let idleSeconds: Int
    let switchCount: Int
    let isCodingContext: Bool
    let activeCodingTool: CodingToolKind
    let recentMessage: String
    let bubbleVisibleUntil: Date
}

struct PetProgress: Codable {
    var xp: Int
    var level: PetLevel
    var focusedMsCarry: TimeInterval
    var chaoticMsCarry: TimeInterval
}

struct TodoItem: Codable, Hashable {
    let id: UUID
    var title: String
    var isDone: Bool
}

struct WhitelistApp: Codable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String?
    let isPreset: Bool

    init(name: String, bundleIdentifier: String? = nil, isPreset: Bool = false) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = Self.makeID(name: normalizedName, bundleIdentifier: bundleIdentifier)
        self.name = normalizedName
        self.bundleIdentifier = bundleIdentifier
        self.isPreset = isPreset
    }

    private static func makeID(name: String, bundleIdentifier: String?) -> String {
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            return bundleIdentifier.lowercased()
        }

        return name.lowercased()
    }
}

struct GrowthSnapshot {
    let pet: PetKind
    let xp: Int
    let level: PetLevel
    let progressRatio: Double
    let nextLevelXp: Int?
    let xpToNext: Int?
    let isMaxLevel: Bool
    let isMinLevel: Bool
    let leveledUp: Bool
}

struct ContributionDay {
    let date: Date
    let focusedMinutes: Int
}

struct CodingStatsSummary {
    let contributionDays: [ContributionDay]
    let availableYears: [Int]
    let todayCodingSeconds: TimeInterval
    let currentMonthCodingSeconds: TimeInterval
    let totalCodingSeconds: TimeInterval
}

struct PetRenderModel {
    let selectedPet: PetKind
    let selectedPetLevel: PetLevel
    let petDisplayScale: CGFloat
    let showsStatusBar: Bool
    let state: PetState
    let appName: String
    let appBundleIdentifier: String?
    let windowTitle: String
    let idleSeconds: Int
    let switchCount: Int
    let isCodingContext: Bool
    let activeCodingTool: CodingToolKind
    let speech: String
    let speechLabel: String
    let speechVisible: Bool
    let statusText: String
    let debugText: String
    let growthSnapshots: [PetKind: GrowthSnapshot]
}
