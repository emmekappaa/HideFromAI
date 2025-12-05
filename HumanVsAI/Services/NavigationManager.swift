//
//  NavigationManager.swift
//  HumanVsAI
//
//  Service to handle navigation between views
//

import SwiftUI
import UIKit

class NavigationManager {
    static let shared = NavigationManager()
    
    private init() {}
    
    func navigateTo<T: View>(_ view: T) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
    }
    
    func navigateToHome() {
        navigateTo(HomeView())
    }
    
    func navigateToGame(aiCount: Int = 3) {
        let language = LanguageManager.shared.selectedLanguage
        navigateTo(GameView(aiCount: aiCount, language: language))
    }
    
    func navigateToSettings() {
        navigateTo(LanguageSettingsView())
    }
}
