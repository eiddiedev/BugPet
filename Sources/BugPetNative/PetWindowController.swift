import AppKit
import SpriteKit

@MainActor
final class PetWindowController: NSWindowController, NSPopoverDelegate {
    var onLanguageChange: ((AppLanguage) -> Void)? {
        didSet {
            panelController.onLanguageChange = onLanguageChange
        }
    }
    var onPetSelected: ((PetKind) -> Void)? {
        didSet {
            panelController.onSelectPet = onPetSelected
        }
    }
    var onPetSlotSelected: ((PetKind, Int) -> Void)? {
        didSet {
            panelController.onSelectPetSlot = onPetSlotSelected
        }
    }
    var onUpgrade: (() -> Void)? {
        didSet {
            panelController.onUpgrade = onUpgrade
        }
    }
    var onDowngrade: (() -> Void)? {
        didSet {
            panelController.onDowngrade = onDowngrade
        }
    }
    var onUnlockSecondaryPet: ((PetKind) -> Void)? {
        didSet {
            panelController.onUnlockSecondaryPet = onUnlockSecondaryPet
        }
    }
    var onPreferencesChange: (() -> Void)? {
        didSet {
            panelController.onPreferencesChange = onPreferencesChange
        }
    }
    var onHoverChange: ((Bool) -> Void)? {
        didSet {
            rootView.onHoverChange = onHoverChange
        }
    }
    var onDragStart: (() -> Void)? {
        didSet {
            rootView.onDragStart = onDragStart
        }
    }
    var onPanelVisibilityChange: ((Bool) -> Void)?

    private let rootView = PetRootView(frame: NSRect(x: 0, y: 0, width: 220, height: 252))
    private let panelController: ControlPanelViewController
    private let popover = NSPopover()
    private var currentLanguage: AppLanguage = .zh

    init(preferences: PreferencesStore) {
        panelController = ControlPanelViewController(preferences: preferences)
        let window = PetWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 252),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = rootView

        super.init(window: window)
        shouldCascadeWindows = false

        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = panelController
        popover.delegate = self

        rootView.onContextMenuRequest = { [weak self] anchorView in
            self?.togglePanel(relativeTo: anchorView)
        }

        window.center()
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func positionNearBottomRight() {
        guard let screen = NSScreen.main, let window else { return }
        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.maxX - window.frame.width - 48,
            y: visibleFrame.minY + 72
        )
        window.setFrameOrigin(origin)
    }

    func render(model: PetRenderModel, panelModel: ControlPanelViewModel) {
        rootView.render(model: model)
        panelController.update(with: panelModel)
    }

    func updateLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    func closePanel() {
        popover.performClose(nil)
    }

    var isPanelShown: Bool {
        popover.isShown
    }

    private func togglePanel(relativeTo anchorView: NSView) {
        if popover.isShown {
            popover.performClose(nil)
            return
        }

        popover.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .maxY)
        onPanelVisibilityChange?(true)
    }

    func popoverDidClose(_ notification: Notification) {
        onPanelVisibilityChange?(false)
    }
}

private final class PetWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
