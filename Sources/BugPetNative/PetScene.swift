import AppKit
import SpriteKit

@MainActor
final class PetScene: SKScene {
    private let petNode = SKSpriteNode()
    private let idleSize = CGSize(width: 58, height: 58)
    private let fearSize = CGSize(width: 64, height: 44)
    private let idlePositionOffset: CGFloat = 4
    private let fearPositionOffset: CGFloat = -1
    private let bugCatIdleFrames = [
        PetAssetCatalog.texture(for: .bugcat, level: .one),
        PetAssetCatalog.bugCatIdleFrame(2),
        PetAssetCatalog.bugCatIdleFrame(3),
    ]
    private let fearTexture = PetAssetCatalog.bugCatFearTexture()

    private(set) var currentPet: PetKind = .bugcat
    private(set) var currentLevel: PetLevel = .one
    private var isFrightened = false
    private var displayScale: CGFloat = 1.0

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        guard petNode.parent == nil else {
            return
        }

        petNode.texture = displayTexture(for: currentPet, level: currentLevel)
        petNode.size = idleSize
        petNode.position = CGPoint(x: size.width / 2, y: size.height / 2 + idlePositionOffset)
        applyDisplayScale()
        addChild(petNode)

        startIdleFloat()
        scheduleIdleAnimation()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        guard petNode.parent != nil else {
            return
        }

        let yOffset = isFrightened && currentPet == .bugcat && currentLevel != .three
            ? fearPositionOffset
            : idlePositionOffset
        petNode.position = CGPoint(x: size.width / 2, y: size.height / 2 + yOffset)
        applyDisplayScale()
    }

    func setPet(_ pet: PetKind, level: PetLevel) {
        if currentPet == pet, currentLevel == level, petNode.parent != nil, !isFrightened {
            return
        }

        currentPet = pet
        currentLevel = level

        guard !isFrightened else {
            return
        }

        petNode.removeAction(forKey: "idle-switch")
        petNode.texture = displayTexture(for: pet, level: level)
        petNode.size = idleSize
        petNode.position = CGPoint(x: size.width / 2, y: size.height / 2 + idlePositionOffset)
        applyDisplayScale()
        scheduleIdleAnimation()
    }

    func setDisplayScale(_ scale: CGFloat) {
        displayScale = scale
        applyDisplayScale()
    }

    func beginFrightenedDrag() {
        guard !isFrightened else {
            return
        }

        isFrightened = true
        petNode.removeAction(forKey: "idle-switch")
        petNode.removeAction(forKey: "fear-recover")

        if currentPet == .bugcat, currentLevel != .three {
            petNode.texture = fearTexture
            petNode.size = fearSize
            petNode.position = CGPoint(x: size.width / 2, y: size.height / 2 + fearPositionOffset)
        }
        applyDisplayScale()

        let shake = SKAction.sequence([
            .moveBy(x: -1.5, y: 0, duration: 0.04),
            .moveBy(x: 3.0, y: 0, duration: 0.06),
            .moveBy(x: -3.0, y: 0, duration: 0.06),
            .moveBy(x: 1.5, y: 0, duration: 0.04),
        ])
        shake.timingMode = .easeInEaseOut

        let tilt = SKAction.sequence([
            .rotate(toAngle: -0.035, duration: 0.04, shortestUnitArc: true),
            .rotate(toAngle: 0.035, duration: 0.06, shortestUnitArc: true),
            .rotate(toAngle: -0.025, duration: 0.06, shortestUnitArc: true),
            .rotate(toAngle: 0, duration: 0.04, shortestUnitArc: true),
        ])
        tilt.timingMode = .easeInEaseOut

        let pulse = SKAction.sequence([
            .scale(to: 0.985, duration: 0.05),
            .scale(to: 1.0, duration: 0.05),
        ])
        pulse.timingMode = .easeInEaseOut

        let fearLoop = SKAction.sequence([
            .group([shake, tilt, pulse]),
            .wait(forDuration: 0.10),
        ])

        petNode.run(.repeatForever(fearLoop), withKey: "fear-shake")
    }

    func endFrightenedDrag() {
        guard isFrightened else {
            return
        }

        isFrightened = false
        petNode.removeAction(forKey: "fear-shake")

        let recover = SKAction.sequence([
            .run { [weak self] in
                guard let self else { return }
                self.petNode.texture = self.displayTexture(for: self.currentPet, level: self.currentLevel)
                self.petNode.size = self.idleSize
                self.petNode.position = CGPoint(
                    x: self.size.width / 2,
                    y: self.size.height / 2 + self.idlePositionOffset
                )
                self.petNode.zRotation = 0
                self.applyDisplayScale()
            },
            .scale(to: 1.0, duration: 0.12),
            .wait(forDuration: 0.6),
            .run { [weak self] in
                self?.scheduleIdleAnimation()
            },
        ])

        petNode.run(recover, withKey: "fear-recover")
    }

    private func startIdleFloat() {
        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 3, duration: 1.2),
            .moveBy(x: 0, y: -3, duration: 1.2),
        ])
        bob.timingMode = .easeInEaseOut
        petNode.run(.repeatForever(bob), withKey: "idle-bob")
    }

    private func scheduleIdleAnimation() {
        guard !isFrightened else {
            return
        }

        if currentPet == .bugcat, currentLevel == .one {
            let switchFrames = SKAction.sequence([
                .wait(forDuration: Double.random(in: 1.8 ... 4.0)),
                .run { [weak self] in
                    self?.petNode.texture = self?.bugCatIdleFrames[safe: 1] ?? self?.bugCatIdleFrames.first
                },
                .wait(forDuration: 0.12),
                .run { [weak self] in
                    self?.petNode.texture = self?.bugCatIdleFrames[safe: 2] ?? self?.bugCatIdleFrames.first
                },
                .wait(forDuration: 0.14),
                .run { [weak self] in
                    self?.petNode.texture = self?.bugCatIdleFrames.first
                },
                .run { [weak self] in
                    self?.scheduleIdleAnimation()
                },
            ])

            petNode.run(switchFrames, withKey: "idle-switch")
            return
        }

        if currentPet == .bugcat, (currentLevel == .two || currentLevel == .three),
           let animatedTexture = animatedTexture(for: currentPet, level: currentLevel) {
            petNode.texture = animatedTexture.frames.first
            let occasionalAnimation = SKAction.sequence([
                .wait(forDuration: Double.random(in: 5.0 ... 10.0)),
                .animate(with: animatedTexture.frames, timePerFrame: animatedTexture.timePerFrame, resize: false, restore: false),
                .wait(forDuration: 1.0),
                .run { [weak self] in
                    self?.petNode.texture = animatedTexture.frames.first
                },
                .run { [weak self] in
                    self?.scheduleIdleAnimation()
                },
            ])
            petNode.run(occasionalAnimation, withKey: "idle-switch")
            return
        }

        if let animatedTexture = animatedTexture(for: currentPet, level: currentLevel) {
            petNode.texture = animatedTexture.frames.first
            let triggeredAnimation = SKAction.sequence([
                .wait(forDuration: Double.random(in: 1.8 ... 4.0)),
                .animate(with: animatedTexture.frames, timePerFrame: animatedTexture.timePerFrame, resize: false, restore: false),
                .run { [weak self] in
                    self?.petNode.texture = animatedTexture.frames.first
                },
                .run { [weak self] in
                    self?.scheduleIdleAnimation()
                },
            ])
            petNode.run(triggeredAnimation, withKey: "idle-switch")
            return
        }

        petNode.texture = displayTexture(for: currentPet, level: currentLevel)
    }

    private func displayTexture(for pet: PetKind, level: PetLevel) -> SKTexture {
        if let animatedTexture = animatedTexture(for: pet, level: level) {
            return animatedTexture.frames.first ?? PetAssetCatalog.texture(for: pet, level: level)
        }
        return PetAssetCatalog.texture(for: pet, level: level)
    }

    private func animatedTexture(for pet: PetKind, level: PetLevel) -> PetAssetCatalog.AnimatedTexture? {
        return PetAssetCatalog.animatedTexture(for: pet, level: level)
    }

    private func applyDisplayScale() {
        petNode.setScale(displayScale)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
