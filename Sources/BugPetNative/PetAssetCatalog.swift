import AppKit
import ImageIO
import SpriteKit

enum PetAssetCatalog {
    struct AnimatedTexture {
        let frames: [SKTexture]
        let timePerFrame: TimeInterval
    }

    static func image(for pet: PetKind, level: PetLevel) -> NSImage? {
        guard let url = Bundle.module.url(
            forResource: "\(pet.rawValue)-level\(level.rawValue)",
            withExtension: "png"
        ) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    static func texture(for pet: PetKind, level: PetLevel) -> SKTexture {
        guard let image = image(for: pet, level: level) else {
            return SKTexture()
        }

        return SKTexture(image: image)
    }

    static func bugCatFearTexture() -> SKTexture {
        guard let url = Bundle.module.url(forResource: "bugcat-fear-static", withExtension: "png"),
              let image = NSImage(contentsOf: url)
        else {
            return SKTexture()
        }

        return SKTexture(image: image)
    }

    static func bugCatIdleFrame(_ index: Int) -> SKTexture {
        guard let url = Bundle.module.url(forResource: "bugcat-idle-\(index)", withExtension: "png"),
              let image = NSImage(contentsOf: url)
        else {
            return SKTexture()
        }

        return SKTexture(image: image)
    }

    static func animatedTexture(for pet: PetKind, level: PetLevel) -> AnimatedTexture? {
        guard let url = Bundle.module.url(
            forResource: "\(pet.rawValue)-level\(level.rawValue)",
            withExtension: "gif"
        ) else {
            return nil
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else {
            return nil
        }

        var frames: [SKTexture] = []
        var totalDuration: TimeInterval = 0

        for index in 0 ..< frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }

            frames.append(SKTexture(cgImage: cgImage))
            totalDuration += gifFrameDuration(source: source, index: index)
        }

        guard !frames.isEmpty else {
            return nil
        }

        let timePerFrame = max(totalDuration / Double(frames.count), 0.02)
        return AnimatedTexture(frames: frames, timePerFrame: timePerFrame)
    }

    private static func gifFrameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.1
        }

        if let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double,
           unclamped > 0 {
            return unclamped
        }

        if let delay = gifProperties[kCGImagePropertyGIFDelayTime] as? Double,
           delay > 0 {
            return delay
        }

        return 0.1
    }
}
