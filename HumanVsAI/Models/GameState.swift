//
//  GameState.swift
//  HumanVsAI
//
//  Model representing the current game state
//

import Foundation

enum GamePhase {
    case chat
    case voting
    case results
}

struct GameState {
    var topic: String
    var currentRound: Int
    var currentTurn: Int
    var phase: GamePhase
    var players: [Player]
    var messages: [Message]
    var userVote: Int?
    var aiVotes: [Int]
    
    var totalRounds: Int = 2
    var humanPlayerIndex: Int {
        players.firstIndex { $0.isHuman } ?? players.count - 1
    }
    
    var isUserTurn: Bool {
        currentTurn == humanPlayerIndex
    }
    
    var currentPlayer: Player? {
        players.indices.contains(currentTurn) ? players[currentTurn] : nil
    }
    
    mutating func nextTurn() {
        currentTurn += 1
        
        if currentTurn >= players.count {
            if currentRound >= totalRounds - 1 {
                phase = .voting
            } else {
                currentRound += 1
                currentTurn = 0
            }
        }
    }
    
    mutating func reset(with newTopic: String, players: [Player]) {
        self.topic = newTopic
        self.currentRound = 0
        self.currentTurn = 0
        self.phase = .chat
        self.players = players
        self.messages = []
        self.userVote = nil
        self.aiVotes = []
    }
}
