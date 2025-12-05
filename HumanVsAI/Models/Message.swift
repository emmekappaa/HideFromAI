//
//  Message.swift
//  HumanVsAI
//
//  Model representing a chat message
//

import Foundation

struct Message: Identifiable {
    let id: UUID
    let playerId: Int
    let content: String
    let timestamp: Date
    
    init(playerId: Int, content: String) {
        self.id = UUID()
        self.playerId = playerId
        self.content = content
        self.timestamp = Date()
    }
    
    var displayText: String {
        "Player \(playerId + 1): \(content)"
    }
}
