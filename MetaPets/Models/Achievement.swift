//
//  Achievement.swift
//  Petopia
//
//  Created for Petopia achievement system
//

import SwiftUI

struct Achievement: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var description: String
    var category: AchievementCategory
    var difficulty: AchievementDifficulty
    var goal: Int
    var progress: Int = 0
    var rewardAmount: Int
    var isUnlocked: Bool = false
    var dateUnlocked: Date?
    var hidden: Bool = false
    
    // Computed property for progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        return min(1.0, Double(progress) / Double(goal))
    }
    
    // Updates progress and returns whether achievement was just unlocked
    mutating func updateProgress(newProgress: Int) -> Bool {
        // Only update if not already unlocked
        guard !isUnlocked else {
            return false
        }
        
        // Update progress
        progress = min(newProgress, goal)
        
        // Check if achievement is now complete
        if progress >= goal {
            isUnlocked = true
            dateUnlocked = Date()
            return true // Just unlocked
        }
        
        return false // Not unlocked yet
    }
    
    // For Equatable conformance
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        return lhs.id == rhs.id
    }
}

// Achievement categories
enum AchievementCategory: String, Codable, CaseIterable {
    case petCare, games, dailies, collection, special
    
    var displayName: String {
        switch self {
        case .petCare: return "Pet Care"
        case .games: return "Games"
        case .dailies: return "Daily Activities"
        case .collection: return "Collection"
        case .special: return "Special"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .petCare: return .blue
        case .games: return .purple
        case .dailies: return .green
        case .collection: return .orange
        case .special: return .pink
        }
    }
}

// Achievement difficulty levels
enum AchievementDifficulty: String, Codable, CaseIterable {
    case bronze, silver, gold, platinum
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.5, green: 0.5, blue: 0.9)
        }
    }
    
    var displayName: String {
        return self.rawValue.capitalized
    }
}
