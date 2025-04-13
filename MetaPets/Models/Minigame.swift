//
//  Minigame.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

struct Minigame: Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var difficulty: MinigameDifficulty
    var type: MinigameType
    var rewardAmount: Int
    var imageName: String
    var cooldownMinutes: Int
    var petType: PetType
    
    // Computed property to determine rewards based on difficulty
    var possibleReward: Int {
        switch difficulty {
        case .easy:
            return rewardAmount
        case .medium:
            return Int(Double(rewardAmount) * 1.5)
        case .hard:
            return rewardAmount * 2
        }
    }
}

enum MinigameDifficulty: String, CaseIterable, Codable {
    case easy, medium, hard
    
    var description: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

enum MinigameType: String, CaseIterable, Codable {
    case memoryMatch, quickTap, patternRecognition, petCare
    
    var description: String {
        switch self {
        case .memoryMatch: return "Memory Match"
        case .quickTap: return "Quick Tap"
        case .patternRecognition: return "Pattern Recognition"
        case .petCare: return "Pet Care Quiz"
        }
    }
}
