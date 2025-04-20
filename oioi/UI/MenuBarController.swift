import AppKit
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePopover = Self("togglePopover")
}

class MenuBarController {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var panel: NSPanel?
    
    func setup() {
        setupStatusItem()
        setupPopover()
        setupGlobalShortcut()
        
        // Add observer for panel close notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClosePanel),
            name: NSNotification.Name("ClosePanel"),
            object: nil
        )
        
        // Add observer for popover close notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClosePopover),
            name: NSNotification.Name("ClosePopover"),
            object: nil
        )
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use the custom sloth icon
            if let image = NSImage(named: "sloth_icon") {
                image.isTemplate = true // Ensures icon matches macOS theme (light/dark)
                image.size = NSSize(width: 18, height: 18) // Explicitly set size
                button.image = image
                button.imagePosition = .imageOnly // Display only the image
            } else {
                // Fallback to system icon if custom icon fails
                print("Error: Custom icon 'sloth_icon' not found. Using fallback.") // Added error logging
                let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                let fallbackImage = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "OiOi")?.withSymbolConfiguration(config)
                button.image = fallbackImage
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        
        // Create the content view with blur effect
        let historyPanel = HistoryPanel()
            .background(VisualEffectView())
        
        popover.contentViewController = NSHostingController(rootView: historyPanel)
    }
    
    private func setupGlobalShortcut() {
        if KeyboardShortcuts.getShortcut(for: .togglePopover) == nil {
            KeyboardShortcuts.setShortcut(.init(.v, modifiers: [.option]), for: .togglePopover)
        }
    }
    
    @objc func togglePopover(_ sender: Any? = nil) {
        if sender is NSStatusBarButton {
            // Clicked from menu bar
            toggleMenuBarPopover()
        } else {
            // Triggered by keyboard shortcut
            toggleFloatingPanel()
        }
    }
    
    private func toggleMenuBarPopover() {
        if popover.isShown {
            closePopover()
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    private func toggleFloatingPanel() {
        if let panel = panel, panel.isVisible {
            // Animate disappearance
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 0.0
                
                // Add a slight scale down animation
                if let layer = panel.contentView?.layer {
                    let animation = CABasicAnimation(keyPath: "transform.scale")
                    animation.fromValue = 1.0
                    animation.toValue = 0.95
                    animation.duration = 0.1
                    layer.add(animation, forKey: "popOut")
                }
            } completionHandler: {
                panel.close()
                self.panel = nil
            }
        } else {
            showFloatingPanel()
        }
    }
    
    private func showFloatingPanel() {
        // Create panel with borderless style
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.alphaValue = 0.0 // Start transparent for animation
        panel.collectionBehavior = [.moveToActiveSpace]
        
        // Add rounded corners and blur
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 30
        panel.contentView?.layer?.masksToBounds = true
        
        // Create content view with blur
        let historyPanel = HistoryPanel(isPanelMode: true)
            .background(VisualEffectView(cornerRadius: 30))
        let hostingView = NSHostingView(rootView: historyPanel)
        panel.contentView = hostingView
        
        // Position panel near cursor
        positionPanelOptimally(panel)
        
        // Show panel and make it key window to accept input
        panel.orderFront(nil)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Animate appearance
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
            
            // Add spring animation
            if let layer = panel.contentView?.layer {
                let animation = CASpringAnimation(keyPath: "transform.scale")
                animation.fromValue = 0.95
                animation.toValue = 1.0
                animation.damping = 15
                animation.initialVelocity = 5
                animation.mass = 1.0
                animation.duration = 0.4
                layer.add(animation, forKey: "spring-appearance")
            }
        }
        
        self.panel = panel
        
        // CRITICAL: Use multiple focus attempts with increasing delays
        for delay in [0.05, 0.1, 0.2, 0.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.forceTextFieldFocusInPanel(panel)
            }
        }
    }
    
    private func positionPanelOptimally(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelFrame = panel.frame
        
        // Calculate optimal position based on screen quadrant
        var xPos = mouseLocation.x
        var yPos = mouseLocation.y
        
        // Determine which quadrant of the screen the mouse is in
        let isInRightHalf = mouseLocation.x > screenFrame.midX
        let isInTopHalf = mouseLocation.y > screenFrame.midY
        
        // Position panel to open away from screen edges
        if isInRightHalf {
            xPos = mouseLocation.x - panelFrame.width - 10
        } else {
            xPos = mouseLocation.x + 10
        }
        
        if isInTopHalf {
            yPos = mouseLocation.y - 10
        } else {
            yPos = mouseLocation.y + panelFrame.height + 10
        }
        
        // Ensure panel stays within screen bounds
        xPos = max(screenFrame.minX + 10, min(xPos, screenFrame.maxX - panelFrame.width - 10))
        yPos = max(screenFrame.minY + panelFrame.height + 10, min(yPos, screenFrame.maxY - 10))
        
        // Set the panel position
        if isInTopHalf {
            panel.setFrameTopLeftPoint(NSPoint(x: xPos, y: yPos))
        } else {
            panel.setFrameOrigin(NSPoint(x: xPos, y: yPos - panelFrame.height))
        }
    }
    
    private func closePopover() {
        popover.performClose(nil)
    }
    
    // Replace the existing focusSearchFieldInPanel with this more aggressive version
    private func forceTextFieldFocusInPanel(_ panel: NSPanel) {
        // First make sure the panel is key and front
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // No need to find and focus text fields since search bar is removed
    }
    
    @objc private func handleClosePanel() {
        if let panel = self.panel, panel.isVisible {
            // Animate panel closing
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 0.0
            } completionHandler: {
                panel.close()
                self.panel = nil
            }
        }
    }
    
    @objc private func handleClosePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
