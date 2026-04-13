import Foundation

@MainActor
final class GrowthEngine {
    private enum Constants {
        static let focusedInterval: TimeInterval = 60
        static let chaoticInterval: TimeInterval = 240
        static let level2XP = 600
        static let level3XP = 1_800
        static let maxXP = level3XP
        static let maxElapsed: TimeInterval = 10
    }

    private let defaults: UserDefaults
    private let storageKey = "bugpet.native.progress.v1"
    private var profiles: [PetKind: PetProgress]
    private var lastTickAt = Date()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.profiles = Self.loadProfiles(from: defaults, storageKey: storageKey)
    }

    func getSnapshot(for pet: PetKind) -> GrowthSnapshot {
        Self.snapshot(for: pet, progress: profiles[pet] ?? Self.defaultProgress())
    }

    func getAllSnapshots() -> [PetKind: GrowthSnapshot] {
        var snapshots: [PetKind: GrowthSnapshot] = [:]
        for pet in PetKind.allCases {
            snapshots[pet] = getSnapshot(for: pet)
        }
        return snapshots
    }

    func update(state: PetState, isCodingContext: Bool, selectedPet: PetKind, now: Date) -> GrowthSnapshot {
        let elapsed = max(0, min(now.timeIntervalSince(lastTickAt), Constants.maxElapsed))
        lastTickAt = now

        guard var progress = profiles[selectedPet] else {
            let snapshot = Self.snapshot(for: selectedPet, progress: Self.defaultProgress())
            profiles[selectedPet] = Self.defaultProgress()
            persist()
            return snapshot
        }

        let previousLevel = progress.level
        var dirty = false

        if progress.xp >= Constants.maxXP {
            progress.focusedMsCarry = 0
            progress.chaoticMsCarry = 0
            profiles[selectedPet] = progress
            persist()
            return Self.snapshot(for: selectedPet, progress: progress)
        }

        if isCodingContext {
            switch state {
            case .focused:
                progress.focusedMsCarry += elapsed
            case .chaotic:
                progress.chaoticMsCarry += elapsed
            default:
                break
            }

            let focusedXP = Int(progress.focusedMsCarry / Constants.focusedInterval)
            let chaoticXP = Int(progress.chaoticMsCarry / Constants.chaoticInterval)
            let gainedXP = focusedXP + chaoticXP

            if focusedXP > 0 {
                progress.focusedMsCarry = progress.focusedMsCarry.truncatingRemainder(dividingBy: Constants.focusedInterval)
                dirty = true
            }

            if chaoticXP > 0 {
                progress.chaoticMsCarry = progress.chaoticMsCarry.truncatingRemainder(dividingBy: Constants.chaoticInterval)
                dirty = true
            }

            if gainedXP > 0 {
                progress.xp = min(Constants.maxXP, progress.xp + gainedXP)
                progress.level = Self.level(for: progress.xp)

                if progress.xp >= Constants.maxXP {
                    progress.focusedMsCarry = 0
                    progress.chaoticMsCarry = 0
                }

                dirty = true
            }
        }

        profiles[selectedPet] = progress
        if dirty || progress.level != previousLevel {
            persist()
        }

        return Self.snapshot(
            for: selectedPet,
            progress: progress,
            leveledUp: progress.level.rawValue > previousLevel.rawValue
        )
    }

    func jumpToNextLevel(for pet: PetKind) -> GrowthSnapshot {
        guard var progress = profiles[pet] else {
            profiles[pet] = Self.defaultProgress()
            return getSnapshot(for: pet)
        }

        let targetXP: Int
        switch progress.level {
        case .one:
            targetXP = Constants.level2XP
        case .two:
            targetXP = Constants.level3XP
        case .three:
            return Self.snapshot(for: pet, progress: progress)
        }

        let previousLevel = progress.level
        progress.xp = targetXP
        progress.level = Self.level(for: progress.xp)
        progress.focusedMsCarry = 0
        progress.chaoticMsCarry = 0
        profiles[pet] = progress
        persist()

        return Self.snapshot(for: pet, progress: progress, leveledUp: progress.level.rawValue > previousLevel.rawValue)
    }

    func jumpToPreviousLevel(for pet: PetKind) -> GrowthSnapshot {
        guard var progress = profiles[pet] else {
            profiles[pet] = Self.defaultProgress()
            return getSnapshot(for: pet)
        }

        switch progress.level {
        case .one:
            return Self.snapshot(for: pet, progress: progress)
        case .two:
            progress.xp = Constants.level2XP - 1
        case .three:
            progress.xp = Constants.level3XP - 1
        }

        progress.level = Self.level(for: progress.xp)
        progress.focusedMsCarry = 0
        progress.chaoticMsCarry = 0
        profiles[pet] = progress
        persist()

        return Self.snapshot(for: pet, progress: progress)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(profiles)
            defaults.set(data, forKey: storageKey)
        } catch {
            NSLog("Failed to save BugPet native progress: \(error.localizedDescription)")
        }
    }

    private static func loadProfiles(from defaults: UserDefaults, storageKey: String) -> [PetKind: PetProgress] {
        guard let data = defaults.data(forKey: storageKey) else {
            return defaultProfiles()
        }

        do {
            let decoded = try JSONDecoder().decode([PetKind: PetProgress].self, from: data)
            var normalized: [PetKind: PetProgress] = [:]
            for pet in PetKind.allCases {
                normalized[pet] = decoded[pet] ?? defaultProgress()
            }
            return normalized
        } catch {
            NSLog("Failed to load BugPet native progress: \(error.localizedDescription)")
            return defaultProfiles()
        }
    }

    private static func defaultProfiles() -> [PetKind: PetProgress] {
        var profiles: [PetKind: PetProgress] = [:]
        for pet in PetKind.allCases {
            profiles[pet] = defaultProgress()
        }
        return profiles
    }

    private static func defaultProgress() -> PetProgress {
        PetProgress(xp: 0, level: .one, focusedMsCarry: 0, chaoticMsCarry: 0)
    }

    private static func level(for xp: Int) -> PetLevel {
        if xp >= Constants.level3XP {
            return .three
        }

        if xp >= Constants.level2XP {
            return .two
        }

        return .one
    }

    private static func snapshot(for pet: PetKind, progress: PetProgress, leveledUp: Bool = false) -> GrowthSnapshot {
        let nextXP: Int?
        switch progress.level {
        case .one:
            nextXP = Constants.level2XP
        case .two:
            nextXP = Constants.level3XP
        case .three:
            nextXP = nil
        }

        let progressRatio: Double
        switch progress.level {
        case .one:
            progressRatio = min(1, Double(progress.xp) / Double(Constants.level2XP))
        case .two:
            progressRatio = min(1, Double(progress.xp - Constants.level2XP) / Double(Constants.level3XP - Constants.level2XP))
        case .three:
            progressRatio = 1
        }

        return GrowthSnapshot(
            pet: pet,
            xp: progress.xp,
            level: progress.level,
            progressRatio: progressRatio,
            nextLevelXp: nextXP,
            xpToNext: nextXP.map { max(0, $0 - progress.xp) },
            isMaxLevel: nextXP == nil,
            isMinLevel: progress.level == .one && progress.xp == 0,
            leveledUp: leveledUp
        )
    }
}
