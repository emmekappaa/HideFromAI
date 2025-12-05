//
//  LanguageManager.swift
//  HumanVsAI
//
//  Service to manage language settings
//

import Foundation

class LanguageManager {
    static let shared = LanguageManager()
    
    private let languageKey = "selectedLanguage"
    
    var selectedLanguage: String {
        get {
            return UserDefaults.standard.string(forKey: languageKey) ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: languageKey)
        }
    }
    
    private init() {}
}
