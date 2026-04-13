import Foundation

@MainActor
final class PetStateEngine {
    private var lastTrackedApp = ""
    private var switchTimestamps: [Date] = []
    private var currentState: PetState = .watching
    private var recentMessage = ""
    private var nextSpeakAt = Date.distantPast
    private var bubbleVisibleUntil = Date.distantPast

    func update(reading: ActivityReading, selectedPet: PetKind, level: PetLevel, language: AppLanguage) -> PetStateUpdate {
        let now = reading.sampleDate
        trackAppSwitch(appName: reading.frontmostAppName, now: now)

        let switchCount = reading.isCodingApp ? switchTimestamps.count : 0
        let nextState = resolveState(reading: reading, switchCount: switchCount)
        let stateChanged = nextState != currentState

        if shouldGenerateMessage(for: nextState, reading: reading, now: now, stateChanged: stateChanged) {
            recentMessage = SpeechCatalog.randomLine(
                for: selectedPet,
                level: level,
                state: nextState,
                language: language,
                avoiding: recentMessage
            )
            bubbleVisibleUntil = now.addingTimeInterval(5)
            nextSpeakAt = now.addingTimeInterval(cooldown(for: nextState))
        }

        currentState = nextState

        return PetStateUpdate(
            state: nextState,
            appName: reading.frontmostAppName,
            windowTitle: reading.windowTitle,
            idleSeconds: Int(reading.idleSeconds.rounded()),
            switchCount: switchCount,
            isCodingContext: reading.isCodingApp,
            activeCodingTool: reading.activeCodingTool,
            recentMessage: recentMessage,
            bubbleVisibleUntil: bubbleVisibleUntil
        )
    }

    func overrideMessage(_ message: String, visibleUntil: Date = Date().addingTimeInterval(2.4)) {
        recentMessage = message
        bubbleVisibleUntil = visibleUntil
    }

    private func trackAppSwitch(appName: String, now: Date) {
        let normalized = appName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, !normalized.contains("bugpet") else {
            return
        }

        if !lastTrackedApp.isEmpty, normalized != lastTrackedApp {
            switchTimestamps.append(now)
        }

        lastTrackedApp = normalized
        switchTimestamps.removeAll { now.timeIntervalSince($0) > 60 }
    }

    private func resolveState(reading: ActivityReading, switchCount: Int) -> PetState {
        if reading.idleSeconds >= 60 {
            return .idle
        }

        guard reading.isCodingApp else {
            return .watching
        }

        if switchCount >= 8 {
            return .chaotic
        }

        return .focused
    }

    private func shouldGenerateMessage(
        for state: PetState,
        reading: ActivityReading,
        now: Date,
        stateChanged: Bool
    ) -> Bool {
        guard state != .watching else {
            return false
        }

        if stateChanged {
            return true
        }

        guard now >= nextSpeakAt else {
            return false
        }

        switch state {
        case .focused:
            return reading.isCodingApp && reading.idleSeconds < 10
        case .idle:
            return reading.idleSeconds >= 120
        case .chaotic:
            return reading.isCodingApp
        case .watching:
            return false
        }
    }

    private func cooldown(for state: PetState) -> TimeInterval {
        switch state {
        case .idle:
            return 100
        case .focused:
            return 65
        case .chaotic:
            return 45
        case .watching:
            return 90
        }
    }
}
