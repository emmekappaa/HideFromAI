//
//  HomeView.swift
//  HumanVsAI
//
//  Main home screen view
//

import SwiftUI

struct HomeView: View {
    @State private var showGameModeSelection = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Hide From AI")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Play") {
                showGameModeSelection = true
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button("Settings") {
                NavigationManager.shared.navigateToSettings()
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showGameModeSelection) {
            GameModeSelectionView(isPresented: $showGameModeSelection)
        }
    }
}

// MARK: - Game Mode Selection View

struct GameModeSelectionView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Game Mode")
                .font(.title)
                .fontWeight(.bold)
            
            Button("HideFromAI (3 AI, 1 Human)") {
                NavigationManager.shared.navigateToGame(aiCount: 3)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button("Back to Home") {
                isPresented = false
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
