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

            let processedImage = processImageForTransparency(cgImage)
            frames.append(SKTexture(cgImage: processedImage))
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

    private static func processImageForTransparency(_ cgImage: CGImage) -> CGImage {
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return cgImage
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else {
            return cgImage
        }

        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        for y in 0 ..< height {
            for x in 0 ..< width {
                let index = (y * width + x) * bytesPerPixel
                let red = pixels[index]
                let green = pixels[index + 1]
                let blue = pixels[index + 2]
                let alpha = pixels[index + 3]

                if red > 240 && green > 240 && blue > 240 {
                    pixels[index + 3] = 0
                } else {
                    pixels[index + 3] = alpha
                }
            }
        }

        guard let processedCGImage = context.makeImage() else {
            return cgImage
        }

        return processedCGImage
    }
}
