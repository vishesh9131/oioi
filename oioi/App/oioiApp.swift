import SwiftUI

@main
struct oioiApp: App {  // Changed from oldiApp to oioiApp for consistency
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate  // Fixed typo: "Adaptor" not "Adapter", "self" not "seif"
    
    var body: some Scene {
        // No main window scene defined here.
        // The app will run as a menu bar app only.
        // Settings can be accessed via a menu bar item if needed later.
//        MenuBarExtra("OiOi", image: "sloth_icon") { // Placeholder menu, can be customized
//            Button("Preferences...") {
//                // Action to open preferences/settings if needed
//            }
//            Divider()
//            Button("Quit oioi") {
//                NSApplication.shared.terminate(nil)
//            }
//        }
        
        // Removed the Settings scene to prevent default window
        // Settings {
        //     SettingsView() // Use the new SettingsView
        // }
        // .commands {
        //     CommandGroup(replacing: .appInfo) {
        //         Button("About oioi") {
        //             NSApplication.shared.orderFrontStandardAboutPanel(
        //                 options: [.applicationName: "oioi"]
        //             )
        //         }
        //     }
        // }
    }
}

