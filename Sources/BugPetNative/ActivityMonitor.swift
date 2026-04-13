import AppKit
import ApplicationServices
import CoreGraphics
import IOKit

@MainActor
struct ActivityMonitor {
    private static let idleFallbackCap: TimeInterval = 60 * 60 * 8
    private static var monitorsInstalled = false
    private static var globalMonitor: Any?
    private static var localMonitor: Any?
    private static var lastObservedInputDate = Date()

    func read(whitelistApps: [WhitelistApp], now: Date = .now) -> ActivityReading {
        installEventMonitorsIfNeeded()

        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let appName = frontmostApp?.localizedName ?? "Unknown"
        let bundleIdentifier = frontmostApp?.bundleIdentifier
        let windowTitle = frontmostApp.map(fetchWindowTitle(for:)) ?? ""
        let idleSeconds = readIdleSeconds(now: now)
        let codingTool = detectCodingTool(appName: appName, windowTitle: windowTitle)
        let isCodingApp = matchesWhitelist(appName: appName, bundleIdentifier: bundleIdentifier, whitelistApps: whitelistApps)

        return ActivityReading(
            frontmostAppName: appName,
            frontmostBundleIdentifier: bundleIdentifier,
            windowTitle: windowTitle,
            idleSeconds: idleSeconds,
            sampleDate: now,
            isCodingApp: isCodingApp,
            activeCodingTool: codingTool
        )
    }

    private func installEventMonitorsIfNeeded() {
        guard !Self.monitorsInstalled else {
            return
        }

        let mask: NSEvent.EventTypeMask = [
            .keyDown,
            .flagsChanged,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged,
            .mouseMoved,
            .scrollWheel,
        ]

        Self.globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { _ in
            Self.lastObservedInputDate = Date()
        }

        Self.localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            Self.lastObservedInputDate = Date()
            return event
        }

        Self.monitorsInstalled = true
    }

    private func readIdleSeconds(now: Date) -> TimeInterval {
        let monitorIdle = max(0, now.timeIntervalSince(Self.lastObservedInputDate))
        let systemIdle = readSystemIdleSeconds()

        let candidates = [
            monitorIdle,
            systemIdle,
            CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .null),
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null),
        ]
            .filter { $0.isFinite && $0 >= 0 && $0 < Self.idleFallbackCap }

        return candidates.min() ?? 0
    }

    private func readSystemIdleSeconds() -> TimeInterval {
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard entry != 0 else {
            return .infinity
        }
        defer { IOObjectRelease(entry) }

        guard let property = IORegistryEntryCreateCFProperty(entry, "HIDIdleTime" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            return .infinity
        }

        if let number = property as? NSNumber {
            return TimeInterval(number.uint64Value) / 1_000_000_000
        }

        if let data = property as? Data, data.count >= MemoryLayout<UInt64>.size {
            let value = data.withUnsafeBytes { rawBuffer in
                rawBuffer.load(as: UInt64.self)
            }
            return TimeInterval(value) / 1_000_000_000
        }

        return .infinity
    }

    private func fetchWindowTitle(for application: NSRunningApplication) -> String {
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var focusedWindow: CFTypeRef?

        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
              let windowElement = focusedWindow
        else {
            return ""
        }

        var titleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(windowElement as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success
        else {
            return ""
        }

        return titleValue as? String ?? ""
    }

    private func detectCodingTool(appName: String, windowTitle: String) -> CodingToolKind {
        let normalizedApp = appName.lowercased()
        let normalizedTitle = windowTitle.lowercased()
        let haystack = "\(normalizedApp) \(normalizedTitle)"

        if haystack.contains("trae") {
            return .trae
        }

        if haystack.contains("codex") {
            return .codex
        }

        if haystack.contains("claude") {
            return .claudecode
        }

        if haystack.contains("xcode") {
            return .xcode
        }

        if haystack.contains("visual studio code")
            || haystack.contains("vs code")
            || haystack.contains("code.app")
            || normalizedApp == "code"
        {
            return .vscode
        }

        if haystack.contains("cursor") {
            return .cursor
        }

        return .other
    }

    private func matchesWhitelist(appName: String, bundleIdentifier: String?, whitelistApps: [WhitelistApp]) -> Bool {
        let normalizedApp = appName.lowercased()
        let normalizedBundle = bundleIdentifier?.lowercased()

        return whitelistApps.contains { app in
            if let bundleIdentifier = app.bundleIdentifier?.lowercased(),
               bundleIdentifier == normalizedBundle {
                return true
            }

            let normalizedName = app.name.lowercased()
            return normalizedApp == normalizedName
                || normalizedApp.contains(normalizedName)
                || normalizedName.contains(normalizedApp)
        }
    }
}
