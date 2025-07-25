//
//  HumanVsAIApp.swift
//  HumanVsAI
//
//  Created by Michele Cipriani on 13/07/25.
//

// This is the main entry point of the app
// The HumanVsAIApp.swift file defines the main app structure

import SwiftUI

@main // Indicates that this is the main app class
struct HumanVsAIApp: App {
    var body: some Scene {
        WindowGroup { // Defines the main app window
            HomeView() // Sets HomeView as the initial screen
        }
    }
}
