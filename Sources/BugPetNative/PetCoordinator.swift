import AppKit

@MainActor
final class PetCoordinator {
    private let activityMonitor = ActivityMonitor()
    private let stateEngine = PetStateEngine()
    private let growthEngine = GrowthEngine()
    private let preferences = PreferencesStore()
    private let statsStore = CodingStatsStore()
    private lazy var petWindowController = PetWindowController(preferences: preferences)
    private var timer: Timer?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var isHoveringPet = false
    private var isPanelOpen = false
    private var speechState = PetSpeechState(message: "", kind: .state, visibleUntil: .distantPast)
    private var lastStateMessage = ""
    private var levelUpVisibleUntil = Date.distantPast

    func start() {
        petWindowController.onLanguageChange = { [weak self] language in
            self?.setLanguage(language)
        }
        petWindowController.onPetSelected = { [weak self] pet in
            self?.setSelectedPet(pet)
        }
        petWindowController.onPetSlotSelected = { [weak self] pet, slotIndex in
            self?.setSelectedPet(pet, slotIndex: slotIndex)
        }
        petWindowController.onUpgrade = { [weak self] in
            self?.upgradeSelectedPet()
        }
        petWindowController.onDowngrade = { [weak self] in
            self?.downgradeSelectedPet()
        }
        petWindowController.onUnlockSecondaryPet = { [weak self] pet in
            self?.unlockSecondaryPet(for: pet)
        }
        petWindowController.onPreferencesChange = { [weak self] in
            self?.refresh()
        }
        petWindowController.onHoverChange = { [weak self] isHovering in
            self?.isHoveringPet = isHovering
            self?.refresh()
        }
        petWindowController.onDragStart = { [weak self] in
            self?.handleDragStart()
        }
        petWindowController.onPanelVisibilityChange = { [weak self] isOpen in
            self?.isPanelOpen = isOpen
            self?.refresh()
        }

        petWindowController.showWindow(nil)
        petWindowController.positionNearBottomRight()
        petWindowController.updateLanguage(preferences.language)

        refresh()
        installWorkspaceObservers()
        startRefreshTimer()
    }

    private func startRefreshTimer() {
        timer?.invalidate()

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func installWorkspaceObservers() {
        guard workspaceObservers.isEmpty else {
            return
        }

        let notificationCenter = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
        ]

        workspaceObservers = names.map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
        }
    }

    private func refresh() {
        let reading = activityMonitor.read(whitelistApps: preferences.selectedWhitelistApps)
        let selectedPet = preferences.selectedPet
        let selectedSlotIndex = normalizedSelectedSlotIndex(for: selectedPet)
        let selectedSnapshot = growthEngine.getSnapshot(for: selectedPet, slotIndex: selectedSlotIndex)
        let stateUpdate = stateEngine.update(
            reading: reading,
            selectedPet: selectedPet,
            level: selectedSnapshot.level,
            language: preferences.language
        )
        statsStore.recordSample(
            isCodingContext: stateUpdate.isCodingContext,
            isFocused: stateUpdate.state == .focused,
            now: reading.sampleDate
        )
        let growthSnapshot = growthEngine.update(
            state: stateUpdate.state,
            isCodingContext: stateUpdate.isCodingContext,
            selectedPet: selectedPet,
            slotIndex: selectedSlotIndex,
            now: reading.sampleDate
        )
        let allSnapshots = growthEngine.getAllSnapshots()
        let secondarySnapshots = growthEngine.getAllSecondarySnapshots()
        let statsSummary = statsStore.summary(now: reading.sampleDate)

        syncSpeech(
            readingDate: reading.sampleDate,
            stateUpdate: stateUpdate,
            selectedPet: selectedPet,
            growthSnapshot: growthSnapshot
        )

        let speechVisible = !isPanelOpen &&
            !speechState.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (isHoveringPet || speechState.visibleUntil > reading.sampleDate)
        let speechLabel = speechState.kind == .levelUp
            ? SpeechCatalog.levelUpLabel(for: preferences.language)
            : SpeechCatalog.label(for: stateUpdate.state, language: preferences.language)

        let renderModel = PetRenderModel(
            selectedPet: selectedPet,
            selectedPetLevel: selectedSnapshot.level,
            petDisplayScale: preferences.petDisplayScale,
            language: preferences.language,
            showsStatusBar: preferences.showsStatusBar,
            state: stateUpdate.state,
            appName: stateUpdate.appName,
            appBundleIdentifier: reading.frontmostBundleIdentifier,
            windowTitle: stateUpdate.windowTitle,
            idleSeconds: stateUpdate.idleSeconds,
            switchCount: stateUpdate.switchCount,
            isCodingContext: stateUpdate.isCodingContext,
            activeCodingTool: stateUpdate.activeCodingTool,
            speech: speechState.message,
            speechLabel: speechLabel,
            speechVisible: speechVisible,
            statusText: makeStatusText(from: stateUpdate, language: preferences.language),
            debugText: makeDebugText(from: stateUpdate, language: preferences.language),
            growthSnapshots: allSnapshots
        )

        petWindowController.render(
            model: renderModel,
            panelModel: ControlPanelViewModel(
                language: preferences.language,
                theme: preferences.panelTheme,
                selectedPet: selectedPet,
                selectedPetSlotIndex: selectedSlotIndex,
                snapshots: allSnapshots,
                secondarySnapshots: secondarySnapshots,
                todos: preferences.todos,
                statsSummary: statsSummary,
                currentAppName: stateUpdate.appName,
                currentAppBundleIdentifier: reading.frontmostBundleIdentifier
            )
        )
    }

    private func syncSpeech(readingDate: Date, stateUpdate: PetStateUpdate, selectedPet: PetKind, growthSnapshot: GrowthSnapshot) {
        if stateUpdate.recentMessage != lastStateMessage && readingDate >= levelUpVisibleUntil {
            lastStateMessage = stateUpdate.recentMessage
            speechState = PetSpeechState(
                message: stateUpdate.recentMessage,
                kind: .state,
                visibleUntil: stateUpdate.bubbleVisibleUntil
            )
        }

        if growthSnapshot.leveledUp, growthSnapshot.level != .one {
            levelUpVisibleUntil = readingDate.addingTimeInterval(5)
            let message = SpeechCatalog.levelUpLine(for: selectedPet, level: growthSnapshot.level, language: preferences.language)
            speechState = PetSpeechState(message: message, kind: .levelUp, visibleUntil: levelUpVisibleUntil)
        }
    }

    private func setLanguage(_ language: AppLanguage) {
        preferences.language = language
        petWindowController.updateLanguage(language)

        let selectedPet = preferences.selectedPet
        let selectedSlotIndex = normalizedSelectedSlotIndex(for: selectedPet)
        let selectedSnapshot = growthEngine.getSnapshot(for: selectedPet, slotIndex: selectedSlotIndex)
        let now = Date()

        if speechState.kind == .levelUp, now < levelUpVisibleUntil, selectedSnapshot.level != .one {
            speechState = PetSpeechState(
                message: SpeechCatalog.levelUpLine(for: selectedPet, level: selectedSnapshot.level, language: language),
                kind: .levelUp,
                visibleUntil: levelUpVisibleUntil
            )
        } else {
            let reading = activityMonitor.read(whitelistApps: preferences.selectedWhitelistApps, now: now)
            let stateUpdate = stateEngine.update(
                reading: reading,
                selectedPet: selectedPet,
                level: selectedSnapshot.level,
                language: language
            )
            let message = stateUpdate.state == .watching ? speechState.message : stateUpdate.recentMessage
            lastStateMessage = message
            stateEngine.overrideMessage(message, visibleUntil: now.addingTimeInterval(2.4))
            speechState = PetSpeechState(message: message, kind: .state, visibleUntil: now.addingTimeInterval(2.4))
        }

        refresh()
    }

    private func setSelectedPet(_ pet: PetKind, slotIndex: Int = 0) {
        preferences.selectedPet = pet
        preferences.selectedPetSlotIndex = normalizedSlotIndex(slotIndex, for: pet)
        let snapshot = growthEngine.getSnapshot(for: pet, slotIndex: preferences.selectedPetSlotIndex)
        let reading = activityMonitor.read(whitelistApps: preferences.selectedWhitelistApps)
        let stateUpdate = stateEngine.update(
            reading: reading,
            selectedPet: pet,
            level: snapshot.level,
            language: preferences.language
        )
        let nextMessage = stateUpdate.state == .watching
            ? speechState.message
            : SpeechCatalog.randomLine(for: pet, level: snapshot.level, state: stateUpdate.state, language: preferences.language, avoiding: speechState.message)
        let visibleUntil = Date().addingTimeInterval(2.4)
        lastStateMessage = nextMessage
        stateEngine.overrideMessage(nextMessage, visibleUntil: visibleUntil)
        speechState = PetSpeechState(message: nextMessage, kind: .state, visibleUntil: visibleUntil)
        refresh()
    }

    private func handleDragStart() {
        let pet = preferences.selectedPet
        let level = growthEngine.getSnapshot(for: pet).level
        let message = SpeechCatalog.dragLine(
            for: pet,
            level: level,
            language: preferences.language,
            avoiding: speechState.message
        )
        let visibleUntil = Date().addingTimeInterval(2.8)
        lastStateMessage = message
        stateEngine.overrideMessage(message, visibleUntil: visibleUntil)
        speechState = PetSpeechState(message: message, kind: .state, visibleUntil: visibleUntil)
        refresh()
    }

    private func upgradeSelectedPet() {
        let pet = preferences.selectedPet
        let snapshot = growthEngine.jumpToNextLevel(for: pet, slotIndex: normalizedSelectedSlotIndex(for: pet))
        if snapshot.leveledUp {
            levelUpVisibleUntil = Date().addingTimeInterval(5)
            speechState = PetSpeechState(
                message: SpeechCatalog.levelUpLine(for: pet, level: snapshot.level, language: preferences.language),
                kind: .levelUp,
                visibleUntil: levelUpVisibleUntil
            )
        }
        refresh()
    }

    private func downgradeSelectedPet() {
        let pet = preferences.selectedPet
        _ = growthEngine.jumpToPreviousLevel(for: pet, slotIndex: normalizedSelectedSlotIndex(for: pet))
        refresh()
    }

    private func unlockSecondaryPet(for pet: PetKind) {
        if growthEngine.unlockSecondary(for: pet) != nil {
            setSelectedPet(pet, slotIndex: 1)
            return
        }
        refresh()
    }

    private func normalizedSelectedSlotIndex(for pet: PetKind) -> Int {
        normalizedSlotIndex(preferences.selectedPetSlotIndex, for: pet)
    }

    private func normalizedSlotIndex(_ slotIndex: Int, for pet: PetKind) -> Int {
        if slotIndex == 1, growthEngine.getSecondarySnapshot(for: pet) != nil {
            return 1
        }
        return 0
    }

    private func makeDebugText(from update: PetStateUpdate, language: AppLanguage) -> String {
        let coding = update.isCodingContext
            ? (language == .zh ? "是" : "Y")
            : (language == .zh ? "否" : "N")
        let app = update.appName.isEmpty ? (language == .zh ? "未知" : "unknown") : update.appName
        let title = update.windowTitle.isEmpty ? "-" : update.windowTitle

        if language == .zh {
            return """
            应用: \(app)
            编程上下文: \(coding)  工具: \(debugToolLabel(for: update.activeCodingTool, language: language))
            状态: \(debugStateLabel(for: update.state, language: language))  空闲: \(update.idleSeconds)秒  切换: \(update.switchCount)
            窗口: \(title)
            """
        }

        return """
        App: \(app)
        Coding: \(coding)  Tool: \(debugToolLabel(for: update.activeCodingTool, language: language))
        State: \(debugStateLabel(for: update.state, language: language))  Idle: \(update.idleSeconds)s  Switch: \(update.switchCount)
        Title: \(title)
        """
    }

    private func makeStatusText(from update: PetStateUpdate, language: AppLanguage) -> String {
        let stateText = debugStateLabel(for: update.state, language: language)
        let toolText = debugToolLabel(for: update.activeCodingTool, language: language)
        let appText = update.appName.isEmpty ? (language == .zh ? "未知" : "unknown") : update.appName

        if update.isCodingContext, update.activeCodingTool != .other {
            return "\(stateText) · \(toolText)"
        }

        if language == .zh {
            return "\(stateText) · \(appText)"
        }

        return "\(stateText) · \(appText)"
    }

    private func debugToolLabel(for tool: CodingToolKind, language: AppLanguage) -> String {
        switch tool {
        case .trae:
            return "TRAE"
        case .codex:
            return "Codex"
        case .claudecode:
            return language == .zh ? "Claude Code" : "Claude Code"
        case .xcode:
            return "Xcode"
        case .vscode:
            return "VS Code"
        case .cursor:
            return "Cursor"
        case .other:
            return language == .zh ? "其他" : "other"
        }
    }

    private func debugStateLabel(for state: PetState, language: AppLanguage) -> String {
        switch state {
        case .idle:
            return language == .zh ? "空闲" : "idle"
        case .watching:
            return language == .zh ? "围观" : "watching"
        case .focused:
            return language == .zh ? "专注" : "focused"
        case .chaotic:
            return language == .zh ? "混乱" : "chaotic"
        }
    }
}
