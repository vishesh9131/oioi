//
//  oioiApp.swift
//  oioi
//
//  Created by Vishesh Yadav on 19/04/25.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let permissionsGranted = "com.oioi.permissionsGranted"
    }
    
    var permissionsGranted: Bool {
        get { bool(forKey: Keys.permissionsGranted) }
        set { set(newValue, forKey: Keys.permissionsGranted) }
    }
}

