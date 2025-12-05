//
//  Player.swift
//  HumanVsAI
//
//  Model representing a player in the game
//

import Foundation

enum PlayerType {
    case human
    case ai
}

struct Player: Identifiable {
    let id: Int
    let type: PlayerType
    let personality: String?
    
    var displayName: String {
        type == .human ? "Player \(id + 1)" : "Player \(id + 1)"
    }
    
    var isHuman: Bool {
        type == .human
    }
}
