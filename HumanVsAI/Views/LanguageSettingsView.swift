//
//  LanguageSettingsView.swift
//  HumanVsAI
//
//  Language settings screen
//

import SwiftUI

struct LanguageSettingsView: View {
    @State private var selectedLanguage = LanguageManager.shared.selectedLanguage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Language Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select AI Language")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                LanguageOption(
                    flag: "🇺🇸",
                    name: "English",
                    code: "en",
                    isSelected: selectedLanguage == "en"
                ) {
                    selectedLanguage = "en"
                    LanguageManager.shared.selectedLanguage = "en"
                }
                
                LanguageOption(
                    flag: "🇮🇹",
                    name: "Italiano",
                    code: "it",
                    isSelected: selectedLanguage == "it"
                ) {
                    selectedLanguage = "it"
                    LanguageManager.shared.selectedLanguage = "it"
                }
            }
            .padding(.horizontal)
            
            Button("Back to Home") {
                NavigationManager.shared.navigateToHome()
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Language Option Component

struct LanguageOption: View {
    let flag: String
    let name: String
    let code: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(flag)
                    .font(.title)
                Text(name)
                    .font(.title2)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}
