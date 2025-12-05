//
//  GameView.swift
//  HumanVsAI
//
//  Main game screen with chat and voting
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    
    init(aiCount: Int, language: String) {
        _viewModel = StateObject(wrappedValue: GameViewModel(aiCount: aiCount, language: language))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Top bar
            TopBar()
            
            // Game info
            GameInfoSection(
                topic: viewModel.gameState.topic,
                currentRound: viewModel.gameState.currentRound
            )
            
            // Chat messages
            ChatScrollView(messages: viewModel.gameState.messages)
            
            // Game phase content
            switch viewModel.gameState.phase {
            case .chat:
                ChatPhaseView(viewModel: viewModel)
            case .voting:
                VotingPhaseView(viewModel: viewModel)
            case .results:
                ResultsView(viewModel: viewModel)
            }
            
            Spacer()
        }
        .padding()
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            viewModel.startNewGame()
        }
        .onDisappear {
            AIService.shared.cancelAllTasks()
        }
        .alert("Connection Error", isPresented: $viewModel.showConnectionError) {
            Button("OK") {
                NavigationManager.shared.navigateToHome()
            }
        } message: {
            Text("Please try again")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                       to: nil, from: nil, for: nil)
    }
}

// MARK: - Top Bar

struct TopBar: View {
    var body: some View {
        HStack {
            Spacer()
            Button {
                NavigationManager.shared.navigateToHome()
            } label: {
                Image(systemName: "house.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
    }
}

// MARK: - Game Info Section

struct GameInfoSection: View {
    let topic: String
    let currentRound: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Topic: \(topic)")
                .font(.headline)
            
            Text("Phase \(currentRound + 1) of 2")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom)
    }
}

// MARK: - Chat Scroll View

struct ChatScrollView: View {
    let messages: [Message]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        Text(message.displayText)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .id(message.id)
                    }
                }
            }
            .frame(maxHeight: 300)
            .padding()
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Chat Phase View

struct ChatPhaseView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.gameState.isUserTurn {
                TextField("Write your message...", text: $viewModel.playerInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Send") {
                    viewModel.submitMessage(viewModel.playerInput)
                    viewModel.playerInput = ""
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Text("AI \(viewModel.gameState.currentTurn + 1) is typing...")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            if viewModel.canCallVerdict() {
                Button("Call the Verdict") {
                    viewModel.callVerdict()
                }
                .buttonStyle(VerdictButtonStyle())
            }
        }
    }
}

// MARK: - Voting Phase View

struct VotingPhaseView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Voting Phase: Pick someone to accuse 👀")
                .font(.headline)
                .padding()
            
            ForEach(viewModel.gameState.players.filter { !$0.isHuman }) { player in
                VoteButton(
                    playerNumber: player.id + 1,
                    isSelected: viewModel.gameState.userVote == player.id,
                    isDisabled: viewModel.gameState.userVote != nil
                ) {
                    viewModel.submitUserVote(player.id)
                }
            }
            
            if viewModel.gameState.userVote != nil {
                Text("AI are voting...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

// MARK: - Vote Button

struct VoteButton: View {
    let playerNumber: Int
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("AI \(playerNumber)")
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isDisabled)
        .padding(.horizontal)
    }
}

// MARK: - Results View

struct ResultsView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Voting Results")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                if let userVote = viewModel.gameState.userVote {
                    Text("🧑 You voted for: AI \(userVote + 1)")
                }
                
                ForEach(Array(viewModel.gameState.aiVotes.enumerated()), id: \.offset) { aiIndex, votedFor in
                    let votedForText = votedFor == viewModel.gameState.humanPlayerIndex 
                        ? "You" 
                        : "AI \(votedFor + 1)"
                    Text("🤖 AI \(aiIndex + 1) voted for: \(votedForText)")
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            Text(viewModel.determineWinner())
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            Button("New Game") {
                viewModel.startNewGame()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

// MARK: - Verdict Button Style

struct VerdictButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
