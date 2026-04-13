import AppKit
import SpriteKit
import QuartzCore

@MainActor
final class PetSpriteView: SKView {
    var onContextMenu: ((NSEvent) -> Void)?
    var onHoverChange: ((Bool) -> Void)?

    private let petScene = PetScene(size: CGSize(width: 76, height: 76))
    private var trackingAreaRef: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        allowsTransparency = true
        presentScene(petScene)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaRef = trackingArea
        super.updateTrackingAreas()
    }

    func setPet(_ pet: PetKind, level: PetLevel) {
        petScene.setPet(pet, level: level)
    }

    func setDisplayScale(_ scale: CGFloat) {
        petScene.setDisplayScale(scale)
    }

    override func mouseDown(with event: NSEvent) {
        petScene.beginFrightenedDrag()

        needsDisplay = true
        displayIfNeeded()
        CATransaction.flush()
        runManualDragLoop(from: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        onContextMenu?(event)
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChange?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChange?(false)
    }

    private func runManualDragLoop(from initialEvent: NSEvent) {
        guard let window else {
            petScene.endFrightenedDrag()
            return
        }

        let startingMouseLocation = NSEvent.mouseLocation
        let startingOrigin = window.frame.origin

        while let nextEvent = NSApp.nextEvent(
            matching: [.leftMouseDragged, .leftMouseUp],
            until: .distantFuture,
            inMode: .eventTracking,
            dequeue: true
        ) {
            switch nextEvent.type {
            case .leftMouseDragged:
                let currentLocation = NSEvent.mouseLocation
                let deltaX = currentLocation.x - startingMouseLocation.x
                let deltaY = currentLocation.y - startingMouseLocation.y

                window.setFrameOrigin(
                    NSPoint(
                        x: startingOrigin.x + deltaX,
                        y: startingOrigin.y + deltaY
                    )
                )
            case .leftMouseUp:
                petScene.endFrightenedDrag()
                return
            default:
                break
            }
        }

        petScene.endFrightenedDrag()
    }
}
