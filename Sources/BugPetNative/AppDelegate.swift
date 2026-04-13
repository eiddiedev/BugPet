import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: PetCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator = PetCoordinator()
        coordinator?.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
