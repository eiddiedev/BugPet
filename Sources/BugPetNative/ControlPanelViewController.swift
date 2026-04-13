import AppKit
import UniformTypeIdentifiers

struct ControlPanelViewModel {
    let language: AppLanguage
    let theme: PanelTheme
    let selectedPet: PetKind
    let snapshots: [PetKind: GrowthSnapshot]
    let todos: [TodoItem]
    let statsSummary: CodingStatsSummary
    let currentAppName: String
    let currentAppBundleIdentifier: String?
}

private struct PanelPalette {
    let background: NSColor
    let surface: NSColor
    let border: NSColor
    let primaryText: NSColor
    let secondaryText: NSColor
    let accent: NSColor
    let accentSoft: NSColor
    let inputBackground: NSColor
    let emptyContribution: NSColor
    let contributionLow: NSColor
    let contributionMedium: NSColor
    let contributionHigh: NSColor
    let contributionVeryHigh: NSColor
}

@MainActor
private func resolvedTheme(_ theme: PanelTheme) -> PanelTheme {
    switch theme {
    case .system:
        let globalDefaults = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        if let style = globalDefaults?["AppleInterfaceStyle"] as? String,
           style.caseInsensitiveCompare("dark") == .orderedSame {
            return .dark
        }

        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return .dark
        }

        return .light
    case .light, .dark:
        return theme
    }
}

@MainActor
private func makePalette(for theme: PanelTheme) -> PanelPalette {
    switch resolvedTheme(theme) {
    case .light:
        return PanelPalette(
            background: NSColor(calibratedRed: 0.98, green: 0.97, blue: 0.95, alpha: 0.98),
            surface: NSColor(calibratedWhite: 1.0, alpha: 0.94),
            border: NSColor(calibratedRed: 0.86, green: 0.84, blue: 0.80, alpha: 1),
            primaryText: NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.18, alpha: 1),
            secondaryText: NSColor(calibratedRed: 0.42, green: 0.41, blue: 0.43, alpha: 1),
            accent: NSColor(calibratedRed: 0.92, green: 0.53, blue: 0.23, alpha: 1),
            accentSoft: NSColor(calibratedRed: 0.98, green: 0.92, blue: 0.86, alpha: 1),
            inputBackground: NSColor(calibratedRed: 0.96, green: 0.95, blue: 0.93, alpha: 1),
            emptyContribution: NSColor(calibratedRed: 0.92, green: 0.92, blue: 0.92, alpha: 1),
            contributionLow: NSColor(calibratedRed: 0.72, green: 0.86, blue: 0.72, alpha: 1),
            contributionMedium: NSColor(calibratedRed: 0.35, green: 0.71, blue: 0.38, alpha: 1),
            contributionHigh: NSColor(calibratedRed: 0.11, green: 0.57, blue: 0.20, alpha: 1),
            contributionVeryHigh: NSColor(calibratedRed: 0.05, green: 0.42, blue: 0.12, alpha: 1)
        )
    case .dark:
        return PanelPalette(
            background: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.13, alpha: 0.98),
            surface: NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.20, alpha: 0.96),
            border: NSColor(calibratedRed: 0.30, green: 0.29, blue: 0.27, alpha: 1),
            primaryText: NSColor(calibratedRed: 0.95, green: 0.94, blue: 0.92, alpha: 1),
            secondaryText: NSColor(calibratedRed: 0.72, green: 0.70, blue: 0.68, alpha: 1),
            accent: NSColor(calibratedRed: 0.95, green: 0.62, blue: 0.28, alpha: 1),
            accentSoft: NSColor(calibratedRed: 0.27, green: 0.21, blue: 0.17, alpha: 1),
            inputBackground: NSColor(calibratedRed: 0.14, green: 0.14, blue: 0.16, alpha: 1),
            emptyContribution: NSColor(calibratedRed: 0.24, green: 0.24, blue: 0.25, alpha: 1),
            contributionLow: NSColor(calibratedRed: 0.32, green: 0.52, blue: 0.33, alpha: 1),
            contributionMedium: NSColor(calibratedRed: 0.20, green: 0.64, blue: 0.24, alpha: 1),
            contributionHigh: NSColor(calibratedRed: 0.09, green: 0.79, blue: 0.20, alpha: 1),
            contributionVeryHigh: NSColor(calibratedRed: 0.04, green: 0.90, blue: 0.20, alpha: 1)
        )
    case .system:
        fatalError("resolvedTheme returns light or dark only")
    }
}

@MainActor
final class ControlPanelViewController: NSViewController, NSTextFieldDelegate {
    var onLanguageChange: ((AppLanguage) -> Void)?
    var onSelectPet: ((PetKind) -> Void)?
    var onUpgrade: (() -> Void)?
    var onDowngrade: (() -> Void)?
    var onPreferencesChange: (() -> Void)?

    private let preferences: PreferencesStore
    private let calendar = Calendar.autoupdatingCurrent
    private var viewModel: ControlPanelViewModel?
    private var currentPage = 0
    private var selectedContributionYear: Int?
    private weak var whitelistController: WhitelistEditorViewController?
    private let whitelistPopover = NSPopover()

    private let titleLabel = NSTextField(labelWithString: "")
    private let settingsButton = NSButton()
    private let settingsBadgeView = NSView()
    private let contentContainer = NSView()

    private let overviewPage = NSView()
    private let todoPage = NSView()
    private let petPage = NSView()

    private let levelCard = NSView()
    private let levelTitleLabel = NSTextField(labelWithString: "")
    private let levelValueLabel = NSTextField(labelWithString: "")
    private let xpCard = NSView()
    private let xpTitleLabel = NSTextField(labelWithString: "")
    private let xpValueLabel = NSTextField(labelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    private let progressLabel = NSTextField(labelWithString: "")

    private let contributionTitleLabel = NSTextField(labelWithString: "")
    private let contributionYearLabel = NSTextField(labelWithString: "")
    private let contributionPrevYearButton = NSButton()
    private let contributionNextYearButton = NSButton()
    private let contributionScrollView = NSScrollView()
    private let contributionHeatmapContainer = NSView()
    private let contributionLegendStack = NSStackView()

    private let todayCard = NSView()
    private let todayTitleLabel = NSTextField(labelWithString: "")
    private let todayValueLabel = NSTextField(labelWithString: "")
    private let monthCard = NSView()
    private let monthTitleLabel = NSTextField(labelWithString: "")
    private let monthValueLabel = NSTextField(labelWithString: "")
    private let totalCard = NSView()
    private let totalTitleLabel = NSTextField(labelWithString: "")
    private let totalValueLabel = NSTextField(labelWithString: "")

    private let todoInputContainer = NSView()
    private let todoInputField = NSTextField()
    private let addTodoButton = NSButton(title: "", target: nil, action: nil)
    private let todoListStack = NSStackView()
    private let todoScrollView = NSScrollView()
    private let todoEmptyLabel = NSTextField(labelWithString: "")

    private let petScrollView = NSScrollView()
    private let petListStack = NSStackView()
    private let downgradeButton = NSButton(title: "", target: nil, action: nil)
    private let upgradeButton = NSButton(title: "", target: nil, action: nil)
    private var petButtons: [PetKind: NSButton] = [:]
    private var petRowCards: [PetKind: NSView] = [:]
    private var petPreviewViews: [PetKind: NSImageView] = [:]
    private var petNameLabels: [PetKind: NSTextField] = [:]
    private var petLevelLabels: [PetKind: NSTextField] = [:]
    private var petFusionSlots: [PetKind: [NSView]] = [:]

    private let prevPageButton = NSButton()
    private let nextPageButton = NSButton()
    private let pageIndicatorLabel = NSTextField(labelWithString: "")

    init(preferences: PreferencesStore) {
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 270, height: 340))
        view.wantsLayer = true
        view.layer?.cornerRadius = 18
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        configureActions()
        rebuildPetRows()
        refreshTodoList(with: preferences.todos)
        updatePageVisibility()
        applyTheme()
    }

    func update(with viewModel: ControlPanelViewModel) {
        self.viewModel = viewModel
        syncSelectedYear(with: viewModel.statsSummary)
        applyTheme()
        refreshTexts()
        refreshOverview(with: viewModel)
        refreshTodoList(with: viewModel.todos)
        refreshPetRows(with: viewModel)
        whitelistController?.sync(
            language: viewModel.language,
            theme: resolvedTheme(viewModel.theme),
            currentAppName: viewModel.currentAppName,
            currentAppBundleIdentifier: viewModel.currentAppBundleIdentifier
        )
    }

    private var language: AppLanguage {
        viewModel?.language ?? preferences.language
    }

    private var palette: PanelPalette {
        makePalette(for: viewModel?.theme ?? preferences.panelTheme)
    }

    private func syncSelectedYear(with summary: CodingStatsSummary) {
        let fallbackYear = calendar.component(.year, from: .now)
        if let selectedContributionYear, summary.availableYears.contains(selectedContributionYear) {
            return
        }

        selectedContributionYear = summary.availableYears.max() ?? fallbackYear
    }

    private func buildLayout() {
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)

        settingsButton.isBordered = false
        settingsButton.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        settingsButton.contentTintColor = palette.accent
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        settingsBadgeView.wantsLayer = true
        settingsBadgeView.layer?.cornerRadius = 3
        settingsBadgeView.translatesAutoresizingMaskIntoConstraints = false

        let settingsWrap = NSView()
        settingsWrap.translatesAutoresizingMaskIntoConstraints = false
        settingsWrap.addSubview(settingsButton)
        settingsWrap.addSubview(settingsBadgeView)

        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: settingsWrap.topAnchor),
            settingsButton.leadingAnchor.constraint(equalTo: settingsWrap.leadingAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: settingsWrap.trailingAnchor),
            settingsButton.bottomAnchor.constraint(equalTo: settingsWrap.bottomAnchor),
            settingsWrap.widthAnchor.constraint(equalToConstant: 20),
            settingsWrap.heightAnchor.constraint(equalToConstant: 20),
            settingsBadgeView.widthAnchor.constraint(equalToConstant: 6),
            settingsBadgeView.heightAnchor.constraint(equalToConstant: 6),
            settingsBadgeView.topAnchor.constraint(equalTo: settingsWrap.topAnchor, constant: 1),
            settingsBadgeView.trailingAnchor.constraint(equalTo: settingsWrap.trailingAnchor, constant: -1),
        ])

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(spacer)
        headerStack.addArrangedSubview(settingsWrap)

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        [overviewPage, todoPage, petPage].forEach { page in
            page.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview(page)
            NSLayoutConstraint.activate([
                page.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                page.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                page.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                page.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            ])
        }

        buildOverviewPage()
        buildTodoPage()
        buildPetPage()

        configurePagerButton(prevPageButton, symbol: "chevron.left")
        configurePagerButton(nextPageButton, symbol: "chevron.right")
        pageIndicatorLabel.alignment = .center
        pageIndicatorLabel.font = .systemFont(ofSize: 10, weight: .medium)

        let pagerStack = NSStackView(views: [prevPageButton, pageIndicatorLabel, nextPageButton])
        pagerStack.orientation = .horizontal
        pagerStack.alignment = .centerY
        pagerStack.distribution = .fillEqually
        pagerStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStack)
        view.addSubview(contentContainer)
        view.addSubview(pagerStack)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            contentContainer.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            pagerStack.topAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: 8),
            pagerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            pagerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            pagerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            pagerStack.heightAnchor.constraint(equalToConstant: 18),
        ])
    }


    private func buildOverviewPage() {
        configureMetricCard(levelCard, titleLabel: levelTitleLabel, valueLabel: levelValueLabel)
        configureMetricCard(xpCard, titleLabel: xpTitleLabel, valueLabel: xpValueLabel)
        configureMetricCard(todayCard, titleLabel: todayTitleLabel, valueLabel: todayValueLabel)
        configureMetricCard(monthCard, titleLabel: monthTitleLabel, valueLabel: monthValueLabel)
        configureMetricCard(totalCard, titleLabel: totalTitleLabel, valueLabel: totalValueLabel)

        let topMetrics = NSStackView(views: [levelCard, xpCard])
        topMetrics.orientation = .horizontal
        topMetrics.distribution = .fillEqually
        topMetrics.spacing = 8

        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = .systemFont(ofSize: 10, weight: .medium)

        contributionTitleLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        contributionYearLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        configurePagerButton(contributionPrevYearButton, symbol: "chevron.left")
        configurePagerButton(contributionNextYearButton, symbol: "chevron.right")

        let contributionHeader = NSStackView(views: [contributionTitleLabel, NSView(), contributionPrevYearButton, contributionYearLabel, contributionNextYearButton])
        contributionHeader.orientation = .horizontal
        contributionHeader.alignment = .centerY
        contributionHeader.spacing = 6

        contributionHeatmapContainer.wantsLayer = true
        contributionHeatmapContainer.layer?.cornerRadius = 12
        contributionHeatmapContainer.translatesAutoresizingMaskIntoConstraints = false

        contributionScrollView.drawsBackground = false
        contributionScrollView.borderType = .noBorder
        contributionScrollView.hasHorizontalScroller = true
        contributionScrollView.autohidesScrollers = true
        contributionScrollView.hasVerticalScroller = false
        contributionScrollView.documentView = contributionHeatmapContainer
        contributionScrollView.translatesAutoresizingMaskIntoConstraints = false

        contributionLegendStack.orientation = .horizontal
        contributionLegendStack.alignment = .centerY
        contributionLegendStack.spacing = 8

        let bottomMetrics = NSStackView(views: [todayCard, monthCard, totalCard])
        bottomMetrics.orientation = .horizontal
        bottomMetrics.distribution = .fillEqually
        bottomMetrics.spacing = 8

        let stack = NSStackView(views: [
            topMetrics,
            progressIndicator,
            progressLabel,
            contributionHeader,
            contributionScrollView,
            contributionLegendStack,
            bottomMetrics,
        ])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        overviewPage.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: overviewPage.topAnchor),
            stack.leadingAnchor.constraint(equalTo: overviewPage.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: overviewPage.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: overviewPage.bottomAnchor),
            progressIndicator.heightAnchor.constraint(equalToConstant: 6),
            contributionScrollView.heightAnchor.constraint(equalToConstant: 118),
        ])
    }

    private func buildTodoPage() {
        todoInputContainer.wantsLayer = true
        todoInputContainer.layer?.cornerRadius = 11
        todoInputContainer.translatesAutoresizingMaskIntoConstraints = false

        todoInputField.isBordered = false
        todoInputField.drawsBackground = false
        todoInputField.focusRingType = .none
        todoInputField.font = .systemFont(ofSize: 12)
        todoInputField.delegate = self
        todoInputField.target = self
        todoInputField.action = #selector(handleAddTodo)
        todoInputField.translatesAutoresizingMaskIntoConstraints = false

        addTodoButton.bezelStyle = .rounded
        addTodoButton.controlSize = .small

        todoInputContainer.addSubview(todoInputField)
        NSLayoutConstraint.activate([
            todoInputField.topAnchor.constraint(equalTo: todoInputContainer.topAnchor, constant: 8),
            todoInputField.leadingAnchor.constraint(equalTo: todoInputContainer.leadingAnchor, constant: 10),
            todoInputField.trailingAnchor.constraint(equalTo: todoInputContainer.trailingAnchor, constant: -10),
            todoInputField.bottomAnchor.constraint(equalTo: todoInputContainer.bottomAnchor, constant: -8),
            todoInputContainer.heightAnchor.constraint(equalToConstant: 34),
        ])

        let inputStack = NSStackView(views: [todoInputContainer, addTodoButton])
        inputStack.orientation = .horizontal
        inputStack.alignment = .centerY
        inputStack.spacing = 8

        todoListStack.orientation = .vertical
        todoListStack.alignment = .leading
        todoListStack.spacing = 6
        todoListStack.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(todoListStack)
        NSLayoutConstraint.activate([
            todoListStack.topAnchor.constraint(equalTo: documentView.topAnchor),
            todoListStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            todoListStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            todoListStack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
            todoListStack.widthAnchor.constraint(equalTo: documentView.widthAnchor),
        ])

        todoScrollView.drawsBackground = false
        todoScrollView.borderType = .noBorder
        todoScrollView.hasVerticalScroller = true
        todoScrollView.autohidesScrollers = true
        todoScrollView.documentView = documentView
        todoScrollView.translatesAutoresizingMaskIntoConstraints = false

        todoEmptyLabel.alignment = .center
        todoEmptyLabel.font = .systemFont(ofSize: 11)

        let stack = NSStackView(views: [inputStack, todoScrollView, todoEmptyLabel])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        todoPage.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: todoPage.topAnchor),
            stack.leadingAnchor.constraint(equalTo: todoPage.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: todoPage.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: todoPage.bottomAnchor),
            todoScrollView.heightAnchor.constraint(equalToConstant: 214),
        ])
    }

    private func buildPetPage() {
        petListStack.orientation = .vertical
        petListStack.alignment = .leading
        petListStack.spacing = 5
        petListStack.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(petListStack)
        NSLayoutConstraint.activate([
            petListStack.topAnchor.constraint(equalTo: documentView.topAnchor),
            petListStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            petListStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            petListStack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
            petListStack.widthAnchor.constraint(equalTo: documentView.widthAnchor),
        ])

        petScrollView.drawsBackground = false
        petScrollView.borderType = .noBorder
        petScrollView.hasVerticalScroller = true
        petScrollView.autohidesScrollers = true
        petScrollView.documentView = documentView
        petScrollView.translatesAutoresizingMaskIntoConstraints = false

        downgradeButton.bezelStyle = .rounded
        downgradeButton.controlSize = .small
        upgradeButton.bezelStyle = .rounded
        upgradeButton.controlSize = .small

        let buttonRow = NSStackView(views: [downgradeButton, upgradeButton])
        buttonRow.orientation = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 8

        let stack = NSStackView(views: [petScrollView, buttonRow])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        petPage.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: petPage.topAnchor),
            stack.leadingAnchor.constraint(equalTo: petPage.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: petPage.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: petPage.bottomAnchor),
            petScrollView.heightAnchor.constraint(equalToConstant: 222),
        ])
    }

    private func configureActions() {
        settingsButton.target = self
        settingsButton.action = #selector(handleSettingsTap)

        contributionPrevYearButton.target = self
        contributionPrevYearButton.action = #selector(handlePreviousYear)
        contributionNextYearButton.target = self
        contributionNextYearButton.action = #selector(handleNextYear)

        addTodoButton.target = self
        addTodoButton.action = #selector(handleAddTodo)

        downgradeButton.target = self
        downgradeButton.action = #selector(handleDowngrade)
        upgradeButton.target = self
        upgradeButton.action = #selector(handleUpgrade)

        prevPageButton.target = self
        prevPageButton.action = #selector(handlePreviousPage)
        nextPageButton.target = self
        nextPageButton.action = #selector(handleNextPage)
    }

    private func configureMetricCard(_ card: NSView, titleLabel: NSTextField, valueLabel: NSTextField) {
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 9, weight: .semibold)
        valueLabel.font = .systemFont(ofSize: 15, weight: .bold)

        let stack = NSStackView(views: [titleLabel, valueLabel])
        stack.orientation = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            card.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func configurePagerButton(_ button: NSButton, symbol: String) {
        button.isBordered = false
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
    }

    private func makeFusionSlot() -> NSView {
        let slot = NSView()
        slot.wantsLayer = true
        slot.layer?.cornerRadius = 3
        slot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            slot.widthAnchor.constraint(equalToConstant: 11),
            slot.heightAnchor.constraint(equalToConstant: 11),
        ])
        return slot
    }

    private func rebuildPetRows() {
        petListStack.arrangedSubviews.forEach { view in
            petListStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        petButtons.removeAll()
        petRowCards.removeAll()
        petPreviewViews.removeAll()
        petNameLabels.removeAll()
        petLevelLabels.removeAll()
        petFusionSlots.removeAll()

        for pet in PetKind.allCases {
            let row = NSView()
            row.wantsLayer = true
            row.layer?.cornerRadius = 10
            row.translatesAutoresizingMaskIntoConstraints = false

            let preview = NSImageView()
            preview.imageScaling = .scaleProportionallyUpOrDown
            preview.translatesAutoresizingMaskIntoConstraints = false

            let nameLabel = NSTextField(labelWithString: pet.displayName)
            nameLabel.font = .systemFont(ofSize: 11, weight: .semibold)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            let levelLabel = NSTextField(labelWithString: "Lv.1")
            levelLabel.font = .systemFont(ofSize: 10, weight: .medium)
            levelLabel.translatesAutoresizingMaskIntoConstraints = false

            let textStack = NSStackView(views: [nameLabel, levelLabel])
            textStack.orientation = .vertical
            textStack.alignment = .leading
            textStack.spacing = 2
            textStack.translatesAutoresizingMaskIntoConstraints = false

            let spacer = NSView()
            spacer.translatesAutoresizingMaskIntoConstraints = false

            let button = NSButton(title: localized("切换", "Select"), target: self, action: #selector(handlePetSelection(_:)))
            button.tag = PetKind.allCases.firstIndex(of: pet) ?? 0
            button.bezelStyle = .rounded
            button.controlSize = .small
            button.translatesAutoresizingMaskIntoConstraints = false
            button.font = .systemFont(ofSize: 10, weight: .semibold)

            let slotOne = makeFusionSlot()
            let slotTwo = makeFusionSlot()
            petFusionSlots[pet] = [slotOne, slotTwo]
            let slotStack = NSStackView(views: [slotOne, slotTwo])
            slotStack.orientation = .horizontal
            slotStack.alignment = .centerY
            slotStack.spacing = 4
            slotStack.translatesAutoresizingMaskIntoConstraints = false

            let rowStack = NSStackView(views: [preview, textStack, spacer, button, slotStack])
            rowStack.orientation = .horizontal
            rowStack.alignment = .centerY
            rowStack.spacing = 8
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            row.addSubview(rowStack)
            NSLayoutConstraint.activate([
                preview.widthAnchor.constraint(equalToConstant: 38),
                preview.heightAnchor.constraint(equalToConstant: 38),
                rowStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 6),
                rowStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 6),
                rowStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -6),
                rowStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -6),
                row.widthAnchor.constraint(equalTo: petListStack.widthAnchor),
                row.heightAnchor.constraint(equalToConstant: 50),
            ])

            petRowCards[pet] = row
            petPreviewViews[pet] = preview
            petNameLabels[pet] = nameLabel
            petLevelLabels[pet] = levelLabel
            petButtons[pet] = button
            petListStack.addArrangedSubview(row)
        }
    }

    private func refreshTexts() {
        titleLabel.stringValue = pageTitle(for: currentPage)
        pageIndicatorLabel.stringValue = "\(currentPage + 1) / 3"

        levelTitleLabel.stringValue = localized("等级", "Level")
        xpTitleLabel.stringValue = localized("经验", "XP")
        todayTitleLabel.stringValue = localized("今日 Coding", "Today")
        monthTitleLabel.stringValue = localized("本月 Coding", "This Month")
        totalTitleLabel.stringValue = localized("累计 Coding", "Total")
        contributionTitleLabel.stringValue = localized("专注贡献", "Focus Contributions")

        todoInputField.placeholderString = localized("输入一个待办", "Add a todo")
        addTodoButton.title = localized("添加", "Add")
        todoEmptyLabel.stringValue = localized("还没有待办，先写一件今天要推进的事。", "No todos yet. Add the next thing you want to do.")

        downgradeButton.title = localized("降级", "Level -")
        upgradeButton.title = localized("升级", "Level +")
    }

    private func refreshOverview(with viewModel: ControlPanelViewModel) {
        let snapshot = viewModel.snapshots[viewModel.selectedPet] ?? GrowthSnapshot(
            pet: viewModel.selectedPet,
            xp: 0,
            level: .one,
            progressRatio: 0,
            nextLevelXp: 600,
            xpToNext: 600,
            isMaxLevel: false,
            isMinLevel: true,
            leveledUp: false
        )

        levelValueLabel.stringValue = snapshot.level.displayLabel
        xpValueLabel.stringValue = "\(snapshot.xp)"
        progressIndicator.doubleValue = snapshot.progressRatio
        progressLabel.stringValue = snapshot.isMaxLevel
            ? SpeechCatalog.maxLevelText(for: viewModel.language)
            : SpeechCatalog.toNextLevelText(for: viewModel.language, xp: snapshot.xpToNext ?? 0)

        todayValueLabel.stringValue = formatDuration(viewModel.statsSummary.todayCodingSeconds)
        monthValueLabel.stringValue = formatDuration(viewModel.statsSummary.currentMonthCodingSeconds)
        totalValueLabel.stringValue = formatDuration(viewModel.statsSummary.totalCodingSeconds)

        contributionYearLabel.stringValue = String(selectedContributionYear ?? calendar.component(.year, from: .now))
        contributionPrevYearButton.isEnabled = canMoveYear(delta: -1, availableYears: viewModel.statsSummary.availableYears)
        contributionNextYearButton.isEnabled = canMoveYear(delta: 1, availableYears: viewModel.statsSummary.availableYears)

        rebuildContributionHeatmap(using: viewModel.statsSummary)
        rebuildContributionLegend()
    }

    private func refreshTodoList(with todos: [TodoItem]) {
        todoListStack.arrangedSubviews.forEach { view in
            todoListStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        todoEmptyLabel.isHidden = !todos.isEmpty
        todoScrollView.isHidden = todos.isEmpty

        for todo in todos {
            let row = NSView()
            row.wantsLayer = true
            row.layer?.cornerRadius = 10
            row.layer?.backgroundColor = palette.surface.cgColor
            row.layer?.borderWidth = 1
            row.layer?.borderColor = palette.border.cgColor
            row.translatesAutoresizingMaskIntoConstraints = false

            let checkbox = NSButton(checkboxWithTitle: todo.title, target: self, action: #selector(handleToggleTodo(_:)))
            checkbox.state = todo.isDone ? .on : .off
            checkbox.identifier = NSUserInterfaceItemIdentifier(todo.id.uuidString)
            checkbox.font = .systemFont(ofSize: 11)
            checkbox.translatesAutoresizingMaskIntoConstraints = false

            let deleteButton = NSButton()
            deleteButton.isBordered = false
            deleteButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
            deleteButton.identifier = NSUserInterfaceItemIdentifier(todo.id.uuidString)
            deleteButton.target = self
            deleteButton.action = #selector(handleDeleteTodo(_:))
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.contentTintColor = palette.secondaryText

            row.addSubview(checkbox)
            row.addSubview(deleteButton)

            NSLayoutConstraint.activate([
                checkbox.topAnchor.constraint(equalTo: row.topAnchor, constant: 6),
                checkbox.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
                checkbox.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -6),
                checkbox.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -6),
                deleteButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                deleteButton.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -8),
                deleteButton.widthAnchor.constraint(equalToConstant: 16),
                deleteButton.heightAnchor.constraint(equalToConstant: 16),
                row.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
            ])

            todoListStack.addArrangedSubview(row)
        }
    }

    private func refreshPetRows(with viewModel: ControlPanelViewModel? = nil) {
        let activeModel = viewModel ?? self.viewModel

        for pet in PetKind.allCases {
            guard let button = petButtons[pet] else { continue }
            let snapshot = activeModel?.snapshots[pet]
            let isSelected = pet == activeModel?.selectedPet
            petPreviewViews[pet]?.image = PetAssetCatalog.image(for: pet, level: snapshot?.level ?? .one)
            petNameLabels[pet]?.stringValue = pet.displayName
            petLevelLabels[pet]?.stringValue = snapshot?.level.displayLabel ?? "Lv.1"
            petNameLabels[pet]?.textColor = palette.primaryText
            petLevelLabels[pet]?.textColor = palette.secondaryText
            petRowCards[pet]?.layer?.backgroundColor = (isSelected ? palette.accentSoft : palette.surface).cgColor
            petRowCards[pet]?.layer?.borderWidth = 1
            petRowCards[pet]?.layer?.borderColor = (isSelected ? palette.accent : palette.border).cgColor
            button.title = isSelected ? localized("已选中", "Selected") : localized("切换", "Select")
            petFusionSlots[pet]?.forEach { slot in
                slot.layer?.backgroundColor = palette.inputBackground.cgColor
                slot.layer?.borderWidth = 1
                slot.layer?.borderColor = palette.border.cgColor
            }
        }

        if let selectedSnapshot = activeModel?.snapshots[activeModel?.selectedPet ?? .bugcat] {
            downgradeButton.title = selectedSnapshot.isMinLevel ? "Lv.1" : localized("降级", "Level -")
            upgradeButton.title = selectedSnapshot.isMaxLevel ? localized("满级", "Max") : localized("升级", "Level +")
            downgradeButton.isEnabled = !selectedSnapshot.isMinLevel
            upgradeButton.isEnabled = !selectedSnapshot.isMaxLevel
        }
    }

    private func rebuildContributionHeatmap(using summary: CodingStatsSummary) {
        contributionHeatmapContainer.subviews.forEach { $0.removeFromSuperview() }

        let year = selectedContributionYear ?? calendar.component(.year, from: .now)
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)),
              let firstDisplayDate = calendar.date(byAdding: .day, value: -normalizedWeekdayIndex(for: yearStart), to: yearStart)
        else {
            return
        }

        let dayMap = Dictionary(uniqueKeysWithValues: summary.contributionDays.map { (calendar.startOfDay(for: $0.date), $0.focusedMinutes) })
        let dayLabelColumnWidth: CGFloat = 22
        let cellSize: CGFloat = 8
        let cellGap: CGFloat = 3
        let rowHeight = cellSize + cellGap
        let columnWidth = cellSize + cellGap
        let monthLabelHeight: CGFloat = 12
        let topInset: CGFloat = 8
        let leftInset: CGFloat = 8
        let bottomInset: CGFloat = 8
        let weeks = Int(ceil(yearEnd.timeIntervalSince(firstDisplayDate) / (7 * 24 * 60 * 60)))
        let contentWidth = leftInset + dayLabelColumnWidth + CGFloat(weeks) * columnWidth + 12
        let contentHeight = topInset + monthLabelHeight + 6 + 7 * rowHeight + bottomInset

        contributionHeatmapContainer.frame = NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        contributionHeatmapContainer.layer?.backgroundColor = palette.surface.cgColor
        contributionHeatmapContainer.layer?.borderWidth = 1
        contributionHeatmapContainer.layer?.borderColor = palette.border.cgColor

        for (offset, labelText) in [(1, "Mon"), (3, "Wed"), (5, "Fri")] {
            let label = NSTextField(labelWithString: labelText)
            label.font = .systemFont(ofSize: 8, weight: .medium)
            label.textColor = palette.secondaryText
            label.alignment = .right
            label.frame = NSRect(
                x: leftInset,
                y: contentHeight - topInset - monthLabelHeight - 6 - CGFloat(offset + 1) * rowHeight + 1,
                width: dayLabelColumnWidth - 4,
                height: 10
            )
            contributionHeatmapContainer.addSubview(label)
        }

        var previousMonth: Int?
        for week in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .day, value: week * 7, to: firstDisplayDate) else {
                continue
            }

            let month = calendar.component(.month, from: weekStart)
            let yearOfWeek = calendar.component(.year, from: weekStart)
            if yearOfWeek == year,
               month != previousMonth,
               calendar.component(.day, from: weekStart) <= 7 {
                let monthLabel = NSTextField(labelWithString: monthTitle(month))
                monthLabel.font = .systemFont(ofSize: 8, weight: .semibold)
                monthLabel.textColor = palette.secondaryText
                monthLabel.frame = NSRect(
                    x: leftInset + dayLabelColumnWidth + CGFloat(week) * columnWidth,
                    y: contentHeight - topInset - monthLabelHeight,
                    width: 28,
                    height: monthLabelHeight
                )
                contributionHeatmapContainer.addSubview(monthLabel)
                previousMonth = month
            }

            for weekday in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: week * 7 + weekday, to: firstDisplayDate) else {
                    continue
                }

                let cell = NSView(frame: NSRect(
                    x: leftInset + dayLabelColumnWidth + CGFloat(week) * columnWidth,
                    y: contentHeight - topInset - monthLabelHeight - 6 - CGFloat(weekday + 1) * rowHeight,
                    width: cellSize,
                    height: cellSize
                ))
                cell.wantsLayer = true
                cell.layer?.cornerRadius = 2

                if date >= yearStart, date < yearEnd {
                    let minutes = dayMap[calendar.startOfDay(for: date)] ?? 0
                    cell.layer?.backgroundColor = contributionColor(for: minutes).cgColor
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    cell.toolTip = "\(formatter.string(from: date))  \(minutes)m"
                } else {
                    cell.layer?.backgroundColor = NSColor.clear.cgColor
                }

                contributionHeatmapContainer.addSubview(cell)
            }
        }
    }

    private func rebuildContributionLegend() {
        contributionLegendStack.arrangedSubviews.forEach { view in
            contributionLegendStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let items = [
            (localized("0", "0"), palette.emptyContribution),
            (localized("10m", "10m"), palette.contributionLow),
            (localized("60m", "60m"), palette.contributionMedium),
            (localized("120m", "120m"), palette.contributionHigh),
            (localized("180m+", "180m+"), palette.contributionVeryHigh),
        ]

        let lessLabel = NSTextField(labelWithString: localized("少", "Less"))
        lessLabel.font = .systemFont(ofSize: 9, weight: .medium)
        lessLabel.textColor = palette.secondaryText
        contributionLegendStack.addArrangedSubview(lessLabel)

        for item in items {
            let swatch = NSView()
            swatch.wantsLayer = true
            swatch.layer?.cornerRadius = 2
            swatch.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                swatch.widthAnchor.constraint(equalToConstant: 8),
                swatch.heightAnchor.constraint(equalToConstant: 8),
            ])
            swatch.layer?.backgroundColor = item.1.cgColor

            let label = NSTextField(labelWithString: item.0)
            label.font = .systemFont(ofSize: 9, weight: .medium)
            label.textColor = palette.secondaryText

            let row = NSStackView(views: [swatch, label])
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 4
            contributionLegendStack.addArrangedSubview(row)
        }

        let moreLabel = NSTextField(labelWithString: localized("多", "More"))
        moreLabel.font = .systemFont(ofSize: 9, weight: .medium)
        moreLabel.textColor = palette.secondaryText
        contributionLegendStack.addArrangedSubview(moreLabel)
    }

    private func applyTheme() {
        let theme = resolvedTheme(viewModel?.theme ?? preferences.panelTheme)
        let palette = makePalette(for: theme)

        view.appearance = NSAppearance(named: theme == .dark ? .darkAqua : .aqua)
        view.layer?.backgroundColor = palette.background.cgColor
        view.layer?.borderWidth = 1
        view.layer?.borderColor = palette.border.cgColor

        titleLabel.textColor = palette.primaryText
        pageIndicatorLabel.textColor = palette.secondaryText
        settingsBadgeView.layer?.backgroundColor = palette.accent.cgColor
        settingsButton.contentTintColor = palette.accent

        [levelTitleLabel, xpTitleLabel, todayTitleLabel, monthTitleLabel, totalTitleLabel, progressLabel, contributionTitleLabel, contributionYearLabel, todoEmptyLabel]
            .forEach { $0.textColor = palette.secondaryText }
        [levelValueLabel, xpValueLabel, todayValueLabel, monthValueLabel, totalValueLabel].forEach { $0.textColor = palette.primaryText }

        [levelCard, xpCard, todayCard, monthCard, totalCard].forEach { card in
            card.layer?.backgroundColor = palette.surface.cgColor
            card.layer?.borderWidth = 1
            card.layer?.borderColor = palette.border.cgColor
        }

        progressIndicator.controlTint = theme == .dark ? .graphiteControlTint : .blueControlTint
        todoInputContainer.layer?.backgroundColor = palette.inputBackground.cgColor
        todoInputContainer.layer?.borderWidth = 1
        todoInputContainer.layer?.borderColor = palette.border.cgColor
        todoInputField.textColor = palette.primaryText

        [addTodoButton, downgradeButton, upgradeButton, prevPageButton, nextPageButton, contributionPrevYearButton, contributionNextYearButton]
            .forEach { $0.contentTintColor = palette.primaryText }

        contributionHeatmapContainer.layer?.backgroundColor = palette.surface.cgColor
        contributionHeatmapContainer.layer?.borderWidth = 1
        contributionHeatmapContainer.layer?.borderColor = palette.border.cgColor

        refreshTodoList(with: viewModel?.todos ?? preferences.todos)
        refreshPetRows()
    }

    private func updatePageVisibility() {
        overviewPage.isHidden = currentPage != 0
        todoPage.isHidden = currentPage != 1
        petPage.isHidden = currentPage != 2
        titleLabel.stringValue = pageTitle(for: currentPage)
        pageIndicatorLabel.stringValue = "\(currentPage + 1) / 3"
        prevPageButton.isEnabled = currentPage > 0
        nextPageButton.isEnabled = currentPage < 2
    }

    private func pageTitle(for page: Int) -> String {
        switch page {
        case 0:
            return localized("经验", "Growth")
        case 1:
            return "TODO"
        default:
            return localized("宠物", "Pets")
        }
    }

    private func canMoveYear(delta: Int, availableYears: [Int]) -> Bool {
        guard let current = selectedContributionYear,
              let index = availableYears.firstIndex(of: current) else {
            return false
        }

        let next = index + delta
        return availableYears.indices.contains(next)
    }

    private func monthTitle(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = language == .zh ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US_POSIX")
        formatter.setLocalizedDateFormatFromTemplate(language == .zh ? "M月" : "MMM")
        guard let date = calendar.date(from: DateComponents(year: 2000, month: month, day: 1)) else {
            return "\(month)"
        }
        return formatter.string(from: date)
    }

    private func contributionColor(for minutes: Int) -> NSColor {
        switch minutes {
        case 180...:
            return palette.contributionVeryHigh
        case 120...:
            return palette.contributionHigh
        case 60...:
            return palette.contributionMedium
        case 10...:
            return palette.contributionLow
        default:
            return palette.emptyContribution
        }
    }

    private func normalizedWeekdayIndex(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        let base = calendar.firstWeekday
        return (weekday - base + 7) % 7
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func localized(_ zh: String, _ en: String) -> String {
        language == .zh ? zh : en
    }

    @objc private func handleSettingsTap() {
        let menu = NSMenu()

        let languageItem = NSMenuItem(title: localized("语言", "Language"), action: nil, keyEquivalent: "")
        let languageMenu = NSMenu()
        languageMenu.addItem(makeLanguageMenuItem(title: "中文", language: .zh))
        languageMenu.addItem(makeLanguageMenuItem(title: "English", language: .en))
        menu.setSubmenu(languageMenu, for: languageItem)
        menu.addItem(languageItem)

        let themeItem = NSMenuItem(title: localized("主题", "Theme"), action: nil, keyEquivalent: "")
        let themeMenu = NSMenu()
        themeMenu.addItem(makeThemeMenuItem(title: localized("跟随系统", "Follow System"), theme: .system))
        themeMenu.addItem(makeThemeMenuItem(title: localized("浅色", "Light"), theme: .light))
        themeMenu.addItem(makeThemeMenuItem(title: localized("深色", "Dark"), theme: .dark))
        menu.setSubmenu(themeMenu, for: themeItem)
        menu.addItem(themeItem)

        let statusItem = NSMenuItem(title: localized("显示状态栏", "Show Status Bar"), action: #selector(handleToggleStatusBar), keyEquivalent: "")
        statusItem.target = self
        statusItem.state = preferences.showsStatusBar ? .on : .off
        menu.addItem(statusItem)

        let sizeItem = NSMenuItem(title: localized("宠物大小", "Pet Size"), action: nil, keyEquivalent: "")
        let sizeMenu = NSMenu()
        sizeMenu.addItem(makeSizeMenuItem(title: localized("小", "Small"), size: .small))
        sizeMenu.addItem(makeSizeMenuItem(title: localized("中", "Medium"), size: .medium))
        sizeMenu.addItem(makeSizeMenuItem(title: localized("大", "Large"), size: .large))
        menu.setSubmenu(sizeMenu, for: sizeItem)
        menu.addItem(sizeItem)

        let whitelistItem = NSMenuItem(title: localized("白名单…", "Whitelist…"), action: #selector(handleManageWhitelist), keyEquivalent: "")
        whitelistItem.target = self
        menu.addItem(whitelistItem)

        menu.popUp(positioning: nil, at: NSPoint(x: -170, y: settingsButton.bounds.minY - 4), in: settingsButton)
    }

    private func makeLanguageMenuItem(title: String, language: AppLanguage) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(handleLanguageMenu(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = language.rawValue
        item.state = self.language == language ? .on : .off
        return item
    }

    private func makeThemeMenuItem(title: String, theme: PanelTheme) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(handleThemeMenu(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = theme.rawValue
        item.state = preferences.panelTheme == theme ? .on : .off
        return item
    }

    private func makeSizeMenuItem(title: String, size: PetDisplaySize) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(handleSizeMenu(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = size.rawValue
        item.state = preferences.petDisplaySize == size ? .on : .off
        return item
    }

    @objc private func handleLanguageMenu(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let language = AppLanguage(rawValue: rawValue) else {
            return
        }
        onLanguageChange?(language)
    }

    @objc private func handleThemeMenu(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let theme = PanelTheme(rawValue: rawValue) else {
            return
        }
        preferences.panelTheme = theme
        applyTheme()
        onPreferencesChange?()
    }

    @objc private func handleToggleStatusBar() {
        preferences.showsStatusBar.toggle()
        onPreferencesChange?()
    }

    @objc private func handleSizeMenu(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let size = PetDisplaySize(rawValue: rawValue) else {
            return
        }
        preferences.petDisplaySize = size
        onPreferencesChange?()
    }

    @objc private func handleManageWhitelist() {
        let controller = WhitelistEditorViewController(preferences: preferences)
        controller.sync(
            language: language,
            theme: resolvedTheme(viewModel?.theme ?? preferences.panelTheme),
            currentAppName: viewModel?.currentAppName ?? "",
            currentAppBundleIdentifier: viewModel?.currentAppBundleIdentifier
        )
        controller.onEntriesChanged = { [weak self] in
            self?.onPreferencesChange?()
        }
        whitelistController = controller
        whitelistPopover.behavior = .transient
        whitelistPopover.animates = true
        whitelistPopover.contentViewController = controller
        whitelistPopover.show(relativeTo: settingsButton.bounds, of: settingsButton, preferredEdge: .maxY)
    }

    @objc private func handlePreviousYear() {
        guard let summary = viewModel?.statsSummary,
              let current = selectedContributionYear,
              let index = summary.availableYears.firstIndex(of: current),
              summary.availableYears.indices.contains(index - 1) else {
            return
        }
        selectedContributionYear = summary.availableYears[index - 1]
        refreshOverview(with: summaryWrappedModel())
    }

    @objc private func handleNextYear() {
        guard let summary = viewModel?.statsSummary,
              let current = selectedContributionYear,
              let index = summary.availableYears.firstIndex(of: current),
              summary.availableYears.indices.contains(index + 1) else {
            return
        }
        selectedContributionYear = summary.availableYears[index + 1]
        refreshOverview(with: summaryWrappedModel())
    }

    private func summaryWrappedModel() -> ControlPanelViewModel {
        viewModel ?? ControlPanelViewModel(
            language: preferences.language,
            theme: preferences.panelTheme,
            selectedPet: preferences.selectedPet,
            snapshots: [:],
            todos: preferences.todos,
            statsSummary: CodingStatsSummary(
                contributionDays: [],
                availableYears: [calendar.component(.year, from: .now)],
                todayCodingSeconds: 0,
                currentMonthCodingSeconds: 0,
                totalCodingSeconds: 0
            ),
            currentAppName: "",
            currentAppBundleIdentifier: nil
        )
    }

    @objc private func handleAddTodo() {
        let title = todoInputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        var todos = preferences.todos
        todos.insert(TodoItem(id: UUID(), title: title, isDone: false), at: 0)
        preferences.todos = todos
        todoInputField.stringValue = ""
        refreshTodoList(with: todos)
    }

    @objc private func handleToggleTodo(_ sender: NSButton) {
        guard let rawValue = sender.identifier?.rawValue,
              let id = UUID(uuidString: rawValue) else {
            return
        }
        var todos = preferences.todos
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isDone.toggle()
        preferences.todos = todos
        refreshTodoList(with: todos)
    }

    @objc private func handleDeleteTodo(_ sender: NSButton) {
        guard let rawValue = sender.identifier?.rawValue,
              let id = UUID(uuidString: rawValue) else {
            return
        }
        let todos = preferences.todos.filter { $0.id != id }
        preferences.todos = todos
        refreshTodoList(with: todos)
    }

    @objc private func handlePetSelection(_ sender: NSButton) {
        let pet = PetKind.allCases[sender.tag]
        onSelectPet?(pet)
    }

    @objc private func handleDowngrade() {
        onDowngrade?()
    }

    @objc private func handleUpgrade() {
        onUpgrade?()
    }

    @objc private func handlePreviousPage() {
        currentPage = max(0, currentPage - 1)
        updatePageVisibility()
    }

    @objc private func handleNextPage() {
        currentPage = min(2, currentPage + 1)
        updatePageVisibility()
    }
}

@MainActor
private final class WhitelistEditorViewController: NSViewController {
    var onEntriesChanged: (() -> Void)?

    private let preferences: PreferencesStore
    private var language: AppLanguage = .zh
    private var theme: PanelTheme = .light
    private var currentAppName = ""
    private var currentAppBundleIdentifier: String?

    private let titleLabel = NSTextField(labelWithString: "")
    private let helperLabel = NSTextField(labelWithString: "")
    private let addCurrentButton = NSButton(title: "", target: nil, action: nil)
    private let addAppButton = NSButton(title: "", target: nil, action: nil)
    private let appListStack = NSStackView()

    init(preferences: PreferencesStore) {
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 272, height: 320))
        view.wantsLayer = true
        view.layer?.cornerRadius = 14
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        helperLabel.font = .systemFont(ofSize: 10)
        helperLabel.maximumNumberOfLines = 2

        addCurrentButton.bezelStyle = .rounded
        addCurrentButton.controlSize = .small
        addCurrentButton.target = self
        addCurrentButton.action = #selector(handleAddCurrentApp)

        addAppButton.bezelStyle = .rounded
        addAppButton.controlSize = .small
        addAppButton.target = self
        addAppButton.action = #selector(handleAddFromDisk)

        let buttonStack = NSStackView(views: [addCurrentButton, addAppButton])
        buttonStack.orientation = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8

        appListStack.orientation = .vertical
        appListStack.alignment = .leading
        appListStack.spacing = 6
        appListStack.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(appListStack)
        NSLayoutConstraint.activate([
            appListStack.topAnchor.constraint(equalTo: documentView.topAnchor),
            appListStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            appListStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            appListStack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
            appListStack.widthAnchor.constraint(equalTo: documentView.widthAnchor),
        ])

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = documentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [titleLabel, helperLabel, buttonStack, scrollView])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            scrollView.heightAnchor.constraint(equalToConstant: 224),
        ])

        refresh()
    }

    func sync(language: AppLanguage, theme: PanelTheme, currentAppName: String, currentAppBundleIdentifier: String?) {
        self.language = language
        self.theme = theme
        self.currentAppName = currentAppName
        self.currentAppBundleIdentifier = currentAppBundleIdentifier
        if isViewLoaded {
            refresh()
        }
    }

    private func refresh() {
        let palette = makePalette(for: theme)
        view.appearance = NSAppearance(named: resolvedTheme(theme) == .dark ? .darkAqua : .aqua)
        view.layer?.backgroundColor = palette.background.cgColor
        view.layer?.borderWidth = 1
        view.layer?.borderColor = palette.border.cgColor

        titleLabel.stringValue = localized("专注白名单", "Whitelist")
        helperLabel.stringValue = localized("勾选或添加的软件都会计入 coding 和经验。", "Checked or added apps will count for coding and XP.")
        addCurrentButton.title = localized("添加当前应用", "Add Current App")
        addAppButton.title = localized("从应用中添加", "Add App…")

        titleLabel.textColor = palette.primaryText
        helperLabel.textColor = palette.secondaryText
        rebuildRows()
    }

    private func rebuildRows() {
        let palette = makePalette(for: theme)
        appListStack.arrangedSubviews.forEach { view in
            appListStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let selectedIDs = preferences.selectedWhitelistIDs
        let apps = preferences.availableWhitelistApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        for app in apps {
            let row = NSView()
            row.wantsLayer = true
            row.layer?.cornerRadius = 10
            row.layer?.backgroundColor = palette.surface.cgColor
            row.layer?.borderWidth = 1
            row.layer?.borderColor = palette.border.cgColor
            row.translatesAutoresizingMaskIntoConstraints = false

            let checkbox = NSButton(checkboxWithTitle: app.name, target: self, action: #selector(handleToggleWhitelist(_:)))
            checkbox.state = selectedIDs.contains(app.id) ? .on : .off
            checkbox.identifier = NSUserInterfaceItemIdentifier(app.id)
            checkbox.font = .systemFont(ofSize: 11)
            checkbox.translatesAutoresizingMaskIntoConstraints = false

            row.addSubview(checkbox)
            NSLayoutConstraint.activate([
                checkbox.topAnchor.constraint(equalTo: row.topAnchor, constant: 6),
                checkbox.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
                checkbox.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -6),
            ])

            if !app.isPreset {
                let deleteButton = NSButton()
                deleteButton.isBordered = false
                deleteButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
                deleteButton.identifier = NSUserInterfaceItemIdentifier(app.id)
                deleteButton.target = self
                deleteButton.action = #selector(handleRemoveCustom(_:))
                deleteButton.contentTintColor = palette.secondaryText
                deleteButton.translatesAutoresizingMaskIntoConstraints = false
                row.addSubview(deleteButton)

                NSLayoutConstraint.activate([
                    deleteButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                    deleteButton.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -8),
                    deleteButton.widthAnchor.constraint(equalToConstant: 16),
                    checkbox.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -6),
                ])
            } else {
                NSLayoutConstraint.activate([
                    checkbox.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -8),
                ])
            }

            appListStack.addArrangedSubview(row)
        }
    }

    @objc private func handleToggleWhitelist(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        var selected = preferences.selectedWhitelistIDs
        if sender.state == .on {
            selected.insert(id)
        } else {
            selected.remove(id)
        }
        preferences.setWhitelistSelection(selected)
        onEntriesChanged?()
        rebuildRows()
    }

    @objc private func handleRemoveCustom(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        preferences.removeCustomWhitelistApp(id: id)
        onEntriesChanged?()
        rebuildRows()
    }

    @objc private func handleAddCurrentApp() {
        let name = currentAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !name.lowercased().contains("bugpet") else {
            NSSound.beep()
            return
        }
        preferences.addCustomWhitelistApp(WhitelistApp(name: name, bundleIdentifier: currentAppBundleIdentifier))
        onEntriesChanged?()
        rebuildRows()
    }

    @objc private func handleAddFromDisk() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let bundle = Bundle(url: url)
        let name = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String)
            ?? url.deletingPathExtension().lastPathComponent

        preferences.addCustomWhitelistApp(
            WhitelistApp(name: name, bundleIdentifier: bundle?.bundleIdentifier)
        )
        onEntriesChanged?()
        rebuildRows()
    }

    private func localized(_ zh: String, _ en: String) -> String {
        language == .zh ? zh : en
    }
}
