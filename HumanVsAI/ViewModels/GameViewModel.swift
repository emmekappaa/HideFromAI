//
//  GameViewModel.swift
//  HumanVsAI
//
//  ViewModel managing game logic and state
//

import Foundation
import Combine

class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var gameState: GameState
    @Published var playerInput: String = ""
    @Published var showConnectionError: Bool = false
    
    // MARK: - Private Properties
    private let aiService = AIService.shared
    private let topicsPool = ["Football", "Basketball", "Food", "American Food", "Instagram", "TikTok", 
                               "Movies", "Music", "Travel", "Technology", "Books", "Fitness", "Gaming", 
                               "Fashion", "Art", "Science", "History", "Politics", "Education", "Nature"]
    
    private let personalityPool = ["curioso", "annoiato", "sarcastico", "entusiasta", "pigro", "critico", 
                                    "timido", "energico", "pessimista", "cinico", "spontaneo"]
    
    private let language: String
    
    // MARK: - Initialization
    init(aiCount: Int, language: String) {
        self.language = language
        
        let players = Self.createPlayers(aiCount: aiCount, personalityPool: personalityPool)
        self.gameState = GameState(
            topic: "",
            currentRound: 0,
            currentTurn: 0,
            phase: .chat,
            players: players,
            messages: [],
            userVote: nil,
            aiVotes: []
        )
    }
    
    // MARK: - Public Methods
    
    func startNewGame() {
        let topic = topicsPool.randomElement() ?? "Unknown"
        let players = Self.createPlayers(aiCount: gameState.players.filter { !$0.isHuman }.count, 
                                          personalityPool: personalityPool)
        
        aiService.cancelAllTasks()
        gameState.reset(with: topic, players: players)
        
        print("New game started - Topic: \(topic)")
        printPlayerPersonalities()
    }
    
    func submitMessage(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        aiService.cancelAllTasks()
        
        let newMessage = Message(playerId: gameState.currentTurn, content: message)
        gameState.messages.append(newMessage)
        
        print("Message added from Player \(gameState.currentTurn + 1)")
        
        gameState.nextTurn()
        
        if gameState.phase == .chat && !gameState.isUserTurn {
            requestAIResponse()
        }
    }
    
    func submitUserVote(_ vote: Int) {
        gameState.userVote = vote
        print("User voted for Player \(vote + 1)")
        startAIVoting()
    }
    
    func canCallVerdict() -> Bool {
        gameState.currentRound > 0 && gameState.phase == .chat
    }
    
    func callVerdict() {
        gameState.phase = .voting
    }
    
    // MARK: - Private Methods
    
    private func requestAIResponse() {
        guard let currentPlayer = gameState.currentPlayer,
              !currentPlayer.isHuman else {
            return
        }
        
        let expectedTurn = gameState.currentTurn
        let personality = currentPlayer.personality ?? "normale"
        
        _ = aiService.generateAIMessage(
            topic: gameState.topic,
            chatHistory: gameState.messages,
            personality: personality,
            language: language
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let aiMessage):
                if self.gameState.currentTurn == expectedTurn && self.gameState.phase == .chat {
                    self.submitMessage(aiMessage)
                }
            case .failure:
                self.showConnectionError = true
            }
        }
    }
    
    private func startAIVoting() {
        gameState.aiVotes = []
        
        let aiPlayers = gameState.players.enumerated().filter { !$0.element.isHuman }
        
        for (aiIndex, _) in aiPlayers {
            aiService.voteForHuman(
                chatHistory: gameState.messages,
                aiIndex: aiIndex,
                totalPlayers: gameState.players.count
            ) { [weak self] vote in
                guard let self = self else { return }
                
                self.gameState.aiVotes.append(vote)
                print("AI \(aiIndex + 1) voted for Player \(vote + 1)")
                
                if self.gameState.aiVotes.count == aiPlayers.count {
                    self.gameState.phase = .results
                }
            }
        }
    }
    
    private func printPlayerPersonalities() {
        print("Player personalities:")
        for player in gameState.players {
            let role = player.isHuman ? "Human" : "AI"
            let personality = player.personality ?? "N/A"
            print("Player \(player.id + 1) (\(role)): \(personality)")
        }
    }
    
    // MARK: - Static Helpers
    
    private static func createPlayers(aiCount: Int, personalityPool: [String]) -> [Player] {
        var players: [Player] = []
        var availablePersonalities = personalityPool
        
        // Create AI players
        for i in 0..<aiCount {
            let personality = availablePersonalities.randomElement() ?? "normale"
            availablePersonalities.removeAll { $0 == personality }
            
            if availablePersonalities.isEmpty {
                availablePersonalities = personalityPool
            }
            
            players.append(Player(id: i, type: .ai, personality: personality))
        }
        
        // Add human player at the end
        players.append(Player(id: aiCount, type: .human, personality: nil))
        
        return players
    }
    
    // MARK: - Result Calculation
    
    func determineWinner() -> String {
        let aiVotesAgainstUser = gameState.aiVotes.filter { $0 == gameState.humanPlayerIndex }.count
        let totalAI = gameState.players.filter { !$0.isHuman }.count
        
        if aiVotesAgainstUser < 2 {
            return "🎉 Human wins! Only \(aiVotesAgainstUser) out of \(totalAI) AIs identified you as human. You blended in successfully!"
        } else {
            return "🤖 AI wins! \(aiVotesAgainstUser) out of \(totalAI) AIs correctly identified you as human."
        }
    }
}
