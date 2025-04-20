import AppKit
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    let menuBarController = MenuBarController()
    private var hasShownPermissionsAlert = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApp()
        KeyboardShortcuts.onKeyDown(for: .togglePopover) { [weak self] in
            self?.menuBarController.togglePopover()
        }
    }
    
    private func setupApp() {
        // Setup menu bar first
        menuBarController.setup()
        
        // Start clipboard monitoring
        ClipboardManager.shared.startMonitoring()
        
        // Check permissions only if not already granted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessibilityEnabled && !hasShownPermissionsAlert {
            hasShownPermissionsAlert = true
            showPermissionsAlert()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // If the app is reopened (e.g., Dock icon click) and has no visible windows,
        // show the floating panel instead of creating a new default window.
        if !flag {
            menuBarController.togglePopover(nil) // Use the general toggle which calls toggleFloatingPanel
            return true // Indicate we've handled the reopen
        }
        return false // Let default behavior occur if windows are visible
    }
    
    private func showPermissionsAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "oioi needs accessibility permissions to monitor clipboard and handle keyboard shortcuts."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup code if needed
    }
}
