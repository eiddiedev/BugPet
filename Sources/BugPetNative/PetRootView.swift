import AppKit
import SpriteKit

@MainActor
final class PetRootView: NSView {
    var onContextMenuRequest: ((NSView) -> Void)?
    var onHoverChange: ((Bool) -> Void)?
    var onDragStart: (() -> Void)?

    private let bubbleView = SpeechBubbleView(frame: NSRect(x: 30, y: 128, width: 160, height: 76))
    private let petView = PetSpriteView(frame: NSRect(x: 72, y: 44, width: 76, height: 76))
    private let statusCardView = NSView(frame: NSRect(x: 36, y: 212, width: 156, height: 24))
    private let statusLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false

        bubbleView.wantsLayer = true
        bubbleView.layer?.zPosition = 1

        petView.wantsLayer = true
        petView.layer?.zPosition = 5

        statusCardView.wantsLayer = true
        statusCardView.layer?.backgroundColor = NSColor(calibratedWhite: 0.07, alpha: 0.72).cgColor
        statusCardView.layer?.cornerRadius = 12
        statusCardView.layer?.borderWidth = 1
        statusCardView.layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
        statusCardView.layer?.zPosition = 2

        statusLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        statusLabel.textColor = NSColor(calibratedWhite: 1, alpha: 0.94)
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.frame = NSRect(x: 12, y: 4, width: 132, height: 16)
        statusLabel.wantsLayer = true
        statusLabel.layer?.zPosition = 3

        petView.onContextMenu = { [weak self] _ in
            guard let self else { return }
            self.onContextMenuRequest?(self.petView)
        }
        petView.onHoverChange = { [weak self] isHovering in
            self?.onHoverChange?(isHovering)
        }
        petView.onDragStart = { [weak self] in
            self?.onDragStart?()
        }

        statusCardView.addSubview(statusLabel)
        addSubview(bubbleView)
        addSubview(statusCardView)
        addSubview(petView)
        statusCardView.alphaValue = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(model: PetRenderModel) {
        bubbleView.update(title: model.speechLabel, text: model.speech, isVisible: model.speechVisible)
        statusLabel.stringValue = model.statusText
        layoutPet(scale: model.petDisplayScale)
        petView.setDisplayScale(model.petDisplayScale)
        let showsBubbleCluster = model.speechVisible
        statusCardView.animator().alphaValue = model.showsStatusBar && showsBubbleCluster ? 1 : 0
        petView.setPet(model.selectedPet, level: model.selectedPetLevel)
    }

    private func layoutPet(scale: CGFloat) {
        let baseWidth: CGFloat = 76
        let baseHeight: CGFloat = 76
        let scaledWidth = baseWidth * scale
        let scaledHeight = baseHeight * scale
        let originX = (bounds.width - scaledWidth) / 2
        let originY = 44 - ((scaledHeight - baseHeight) / 2)
        petView.frame = NSRect(x: originX, y: originY, width: scaledWidth, height: scaledHeight)
    }
}
