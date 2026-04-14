import AppKit
import ImageIO
import SpriteKit

@MainActor
enum PetAssetCatalog {
    struct AnimatedTexture {
        let frames: [SKTexture]
        let timePerFrame: TimeInterval
    }

    private static var animatedTextureCache: [String: AnimatedTexture] = [:]

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
        let cacheKey = "\(pet.rawValue)-level\(level.rawValue)"
        if let cached = animatedTextureCache[cacheKey] {
            return cached
        }

        guard let url = Bundle.module.url(
            forResource: cacheKey,
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
        let animatedTexture = AnimatedTexture(frames: frames, timePerFrame: timePerFrame)
        animatedTextureCache[cacheKey] = animatedTexture
        return animatedTexture
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
        let backgroundSamples = [
            readPixel(x: 0, y: 0, pixels: pixels, width: width, bytesPerPixel: bytesPerPixel),
            readPixel(x: max(width - 1, 0), y: 0, pixels: pixels, width: width, bytesPerPixel: bytesPerPixel),
            readPixel(x: 0, y: max(height - 1, 0), pixels: pixels, width: width, bytesPerPixel: bytesPerPixel),
            readPixel(x: max(width - 1, 0), y: max(height - 1, 0), pixels: pixels, width: width, bytesPerPixel: bytesPerPixel),
        ]
        let backgroundColor = averageColor(backgroundSamples)

        for y in 0 ..< height {
            for x in 0 ..< width {
                let index = (y * width + x) * bytesPerPixel
                let red = pixels[index]
                let green = pixels[index + 1]
                let blue = pixels[index + 2]
                let alpha = pixels[index + 3]

                if alpha == 0 {
                    continue
                }

                if isBackgroundPixel(
                    red: red,
                    green: green,
                    blue: blue,
                    alpha: alpha,
                    backgroundColor: backgroundColor
                ) {
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

    private static func readPixel(
        x: Int,
        y: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        width: Int,
        bytesPerPixel: Int
    ) -> (UInt8, UInt8, UInt8, UInt8) {
        let index = (y * width + x) * bytesPerPixel
        return (pixels[index], pixels[index + 1], pixels[index + 2], pixels[index + 3])
    }

    private static func averageColor(_ samples: [(UInt8, UInt8, UInt8, UInt8)]) -> (UInt8, UInt8, UInt8, UInt8) {
        guard !samples.isEmpty else {
            return (255, 255, 255, 0)
        }

        let red = samples.reduce(0) { $0 + Int($1.0) } / samples.count
        let green = samples.reduce(0) { $0 + Int($1.1) } / samples.count
        let blue = samples.reduce(0) { $0 + Int($1.2) } / samples.count
        let alpha = samples.reduce(0) { $0 + Int($1.3) } / samples.count

        return (UInt8(red), UInt8(green), UInt8(blue), UInt8(alpha))
    }

    private static func isBackgroundPixel(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8,
        backgroundColor: (UInt8, UInt8, UInt8, UInt8)
    ) -> Bool {
        let colorDistance = abs(Int(red) - Int(backgroundColor.0))
            + abs(Int(green) - Int(backgroundColor.1))
            + abs(Int(blue) - Int(backgroundColor.2))
        let alphaDistance = abs(Int(alpha) - Int(backgroundColor.3))
        return colorDistance <= 30 && alphaDistance <= 30
    }
}
