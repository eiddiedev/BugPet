import AppKit

@MainActor
final class SpeechBubbleView: NSView {
    private enum Metrics {
        static let bubbleWidth: CGFloat = 168
        static let minBubbleHeight: CGFloat = 76
        static let maxBubbleHeight: CGFloat = 124
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 14
        static let bottomPadding: CGFloat = 14
        static let tailHeight: CGFloat = 14
        static let textMeasurementSlack: CGFloat = 8
    }

    private let bodyLabel = NSTextField(wrappingLabelWithString: "")
    private let bubbleLayer = CAShapeLayer()
    private let tailLayer = CAShapeLayer()
    private var measuredBodyHeight: CGFloat = 20

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        bubbleLayer.fillColor = NSColor(calibratedWhite: 1, alpha: 0.92).cgColor
        bubbleLayer.shadowColor = NSColor.black.withAlphaComponent(0.2).cgColor
        bubbleLayer.shadowOpacity = 1
        bubbleLayer.shadowRadius = 10
        bubbleLayer.shadowOffset = CGSize(width: 0, height: -2)

        tailLayer.fillColor = bubbleLayer.fillColor

        layer?.addSublayer(bubbleLayer)
        layer?.addSublayer(tailLayer)

        bodyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        bodyLabel.textColor = NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.18, alpha: 1)
        bodyLabel.maximumNumberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.cell?.wraps = true
        bodyLabel.cell?.usesSingleLineMode = false
        bodyLabel.cell?.isScrollable = false

        addSubview(bodyLabel)
        alphaValue = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        let bubbleRect = NSRect(
            x: 4,
            y: Metrics.tailHeight,
            width: bounds.width - 8,
            height: bounds.height - Metrics.tailHeight - 4
        )
        let roundedPath = NSBezierPath(roundedRect: bubbleRect, xRadius: 18, yRadius: 18)
        bubbleLayer.path = roundedPath.cgPath

        let bodyHeight = max(18, measuredBodyHeight)
        let bodyY = bubbleRect.minY + Metrics.bottomPadding
        bodyLabel.frame = NSRect(
            x: Metrics.horizontalPadding,
            y: bodyY,
            width: bounds.width - Metrics.horizontalPadding * 2,
            height: min(bodyHeight, bubbleRect.height - Metrics.topPadding - Metrics.bottomPadding)
        )

        let tailPath = NSBezierPath()
        tailPath.move(to: NSPoint(x: bounds.midX - 9, y: Metrics.tailHeight))
        tailPath.line(to: NSPoint(x: bounds.midX, y: 4))
        tailPath.line(to: NSPoint(x: bounds.midX + 9, y: Metrics.tailHeight))
        tailPath.close()
        tailLayer.path = tailPath.cgPath
    }

    func update(title: String, text: String, isVisible: Bool) {
        bodyLabel.stringValue = text
        resizeToFitCurrentText()
        animator().alphaValue = isVisible && !text.isEmpty ? 1 : 0
    }

    private func resizeToFitCurrentText() {
        let availableTextWidth = Metrics.bubbleWidth - Metrics.horizontalPadding * 2
        let textRect = bodyLabel.attributedStringValue.boundingRect(
            with: NSSize(width: availableTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        measuredBodyHeight = max(18, ceil(textRect.height) + Metrics.textMeasurementSlack)
        let bubbleHeight = min(
            Metrics.maxBubbleHeight,
            max(
                Metrics.minBubbleHeight,
                Metrics.topPadding + measuredBodyHeight + Metrics.bottomPadding + Metrics.tailHeight + 4
            )
        )
        let newSize = NSSize(width: Metrics.bubbleWidth, height: bubbleHeight)

        if frame.size != newSize {
            frame.size = newSize
        }

        needsLayout = true
        layoutSubtreeIfNeeded()
    }
}

private extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)

        for index in 0..<elementCount {
            let type = element(at: index, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }

        return path
    }
}
