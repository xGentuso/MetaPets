//
//  AchievementManager.swift
//  Petopia
//
//  Created for Petopia achievement system
//

import Foundation
import SwiftUI

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var recentlyUnlocked: [Achievement] = []
    
    private let achievementsKey = "SavedAchievements"
    private let recentUnlocksKey = "RecentlyUnlockedAchievements"
    
    private init() {
        loadAchievements()
        
        // If no achievements exist yet, create the default ones
        if achievements.isEmpty {
            createDefaultAchievements()
        }
        
        loadRecentlyUnlocked()
    }
    
    // MARK: - Achievement Progress Tracking
    
    // Pet Care achievements
    func trackFeeding() {
        updateAchievementProgress(id: "feeding_novice", incrementBy: 1)
        updateAchievementProgress(id: "feeding_expert", incrementBy: 1)
        updateAchievementProgress(id: "feeding_master", incrementBy: 1)
    }
    
    func trackCleaning() {
        updateAchievementProgress(id: "cleaning_novice", incrementBy: 1)
        updateAchievementProgress(id: "cleaning_expert", incrementBy: 1)
    }
    
    func trackSleeping(hours: Int) {
        updateAchievementProgress(id: "sleeping_novice", incrementBy: hours)
        updateAchievementProgress(id: "sleeping_expert", incrementBy: hours)
    }
    
    func trackHealing() {
        updateAchievementProgress(id: "healing_novice", incrementBy: 1)
    }
    
    // Game achievements
    func trackMinigamePlayed() {
        updateAchievementProgress(id: "games_novice", incrementBy: 1)
        updateAchievementProgress(id: "games_expert", incrementBy: 1)
    }
    
    func trackCurrencyEarned(amount: Int) {
        updateAchievementProgress(id: "currency_novice", incrementBy: amount)
        updateAchievementProgress(id: "currency_expert", incrementBy: amount)
        updateAchievementProgress(id: "currency_master", incrementBy: amount)
    }
    
    // Daily activities
    func trackDailyActivity() {
        updateAchievementProgress(id: "dailies_novice", incrementBy: 1)
        updateAchievementProgress(id: "dailies_expert", incrementBy: 1)
    }
    
    func trackDailyStreak(streak: Int) {
        updateAchievementProgress(id: "streak_week", newProgress: streak)
        updateAchievementProgress(id: "streak_month", newProgress: streak)
    }
    
    // Collection achievements
    func trackAccessoryCollected() {
        updateAchievementProgress(id: "collection_novice", incrementBy: 1)
        updateAchievementProgress(id: "collection_expert", incrementBy: 1)
    }
    
    // Level achievements
    func trackLevelUp(newLevel: Int) {
        updateAchievementProgress(id: "level_5", newProgress: newLevel)
        updateAchievementProgress(id: "level_10", newProgress: newLevel)
        updateAchievementProgress(id: "level_25", newProgress: newLevel)
    }
    
    // Evolution achievements
    func trackEvolution(stage: GrowthStage) {
        switch stage {
        case .child:
            unlockAchievement(id: "evolution_child")
        case .teen:
            unlockAchievement(id: "evolution_teen")
        case .adult:
            unlockAchievement(id: "evolution_adult")
        default:
            break
        }
    }
    
    // Specialty achievements
    func trackPerfectStatus() {
        unlockAchievement(id: "perfect_pet")
    }
    
    // MARK: - Achievement Management
    
    // Get achievements by category
    func getAchievements(for category: AchievementCategory? = nil) -> [Achievement] {
        if let category = category {
            return achievements.filter { $0.category == category }
        } else {
            return achievements
        }
    }
    
    // Get all unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    // Get achievements by difficulty
    func getAchievements(difficulty: AchievementDifficulty) -> [Achievement] {
        return achievements.filter { $0.difficulty == difficulty }
    }
    
    // Update progress for an achievement by ID string
    func updateAchievementProgress(id: String, incrementBy: Int = 0, newProgress: Int? = nil) {
        guard let index = achievements.firstIndex(where: { $0.id.uuidString.prefix(id.count) == id }) else {
            return
        }
        
        let currentProgress = achievements[index].progress
        let updatedProgress: Int
        
        if let newProgress = newProgress {
            updatedProgress = newProgress
        } else {
            updatedProgress = currentProgress + incrementBy
        }
        
        let wasJustUnlocked = achievements[index].updateProgress(newProgress: updatedProgress)
        
        if wasJustUnlocked {
            // Add to recently unlocked and notify
            recentlyUnlocked.append(achievements[index])
            saveRecentlyUnlocked()
            NotificationCenter.default.post(name: .achievementUnlocked, object: achievements[index])
        }
        
        saveAchievements()
    }
    
    // Directly unlock an achievement
    func unlockAchievement(id: String) {
        guard let index = achievements.firstIndex(where: { $0.id.uuidString.prefix(id.count) == id }),
              !achievements[index].isUnlocked else {
            return
        }
        
        achievements[index].isUnlocked = true
        achievements[index].progress = achievements[index].goal
        achievements[index].dateUnlocked = Date()
        
        // Add to recently unlocked and notify
        recentlyUnlocked.append(achievements[index])
        saveRecentlyUnlocked()
        NotificationCenter.default.post(name: .achievementUnlocked, object: achievements[index])
        
        saveAchievements()
    }
    
    // Clear recently unlocked achievements
    func clearRecentlyUnlocked() {
        recentlyUnlocked = []
        saveRecentlyUnlocked()
    }
    
    // MARK: - Persistence
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func loadAchievements() {
        if let savedData = UserDefaults.standard.data(forKey: achievementsKey),
           let decodedAchievements = try? JSONDecoder().decode([Achievement].self, from: savedData) {
            achievements = decodedAchievements
        }
    }
    
    private func saveRecentlyUnlocked() {
        if let encoded = try? JSONEncoder().encode(recentlyUnlocked) {
            UserDefaults.standard.set(encoded, forKey: recentUnlocksKey)
        }
    }
    
    private func loadRecentlyUnlocked() {
        if let savedData = UserDefaults.standard.data(forKey: recentUnlocksKey),
           let decodedAchievements = try? JSONDecoder().decode([Achievement].self, from: savedData) {
            recentlyUnlocked = decodedAchievements
        }
    }
    
    // MARK: - Default Achievements
    
    private func createDefaultAchievements() {
        // Pet Care Achievements
        achievements.append(Achievement(
            id: UUID(uuidString: "feeding_novice") ?? UUID(),
            title: "Caring Beginner",
            description: "Feed your pet 10 times",
            category: .petCare,
            difficulty: .bronze,
            goal: 10,
            rewardAmount: 50
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "feeding_expert") ?? UUID(),
            title: "Caring Expert",
            description: "Feed your pet 50 times",
            category: .petCare,
            difficulty: .silver,
            goal: 50,
            rewardAmount: 150
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "feeding_master") ?? UUID(),
            title: "Feeding Master",
            description: "Feed your pet 200 times",
            category: .petCare,
            difficulty: .gold,
            goal: 200,
            rewardAmount: 500
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "cleaning_novice") ?? UUID(),
            title: "Squeaky Clean",
            description: "Clean your pet 5 times",
            category: .petCare,
            difficulty: .bronze,
            goal: 5,
            rewardAmount: 50
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "cleaning_expert") ?? UUID(),
            title: "Hygiene Expert",
            description: "Clean your pet 25 times",
            category: .petCare,
            difficulty: .silver,
            goal: 25,
            rewardAmount: 150
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "sleeping_novice") ?? UUID(),
            title: "Nap Time",
            description: "Let your pet sleep for 10 hours total",
            category: .petCare,
            difficulty: .bronze,
            goal: 10,
            rewardAmount: 50
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "sleeping_expert") ?? UUID(),
            title: "Sweet Dreams",
            description: "Let your pet sleep for 50 hours total",
            category: .petCare,
            difficulty: .silver,
            goal: 50,
            rewardAmount: 150
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "healing_novice") ?? UUID(),
            title: "Healing Touch",
            description: "Heal your pet 3 times",
            category: .petCare,
            difficulty: .bronze,
            goal: 3,
            rewardAmount: 75
        ))
        
        // Game Achievements
        achievements.append(Achievement(
            id: UUID(uuidString: "games_novice") ?? UUID(),
            title: "Game Beginner",
            description: "Play 5 minigames",
            category: .games,
            difficulty: .bronze,
            goal: 5,
            rewardAmount: 75
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "games_expert") ?? UUID(),
            title: "Game Expert",
            description: "Play 25 minigames",
            category: .games,
            difficulty: .silver,
            goal: 25,
            rewardAmount: 200
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "currency_novice") ?? UUID(),
            title: "Fortune Beginner",
            description: "Earn 500 coins total",
            category: .games,
            difficulty: .bronze,
            goal: 500,
            rewardAmount: 50
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "currency_expert") ?? UUID(),
            title: "Fortune Expert",
            description: "Earn 2,000 coins total",
            category: .games,
            difficulty: .silver,
            goal: 2000,
            rewardAmount: 200
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "currency_master") ?? UUID(),
            title: "Fortune Master",
            description: "Earn 10,000 coins total",
            category: .games,
            difficulty: .gold,
            goal: 10000,
            rewardAmount: 1000
        ))
        
        // Daily Activities
        achievements.append(Achievement(
            id: UUID(uuidString: "dailies_novice") ?? UUID(),
            title: "Daily Devotion",
            description: "Complete 10 daily activities",
            category: .dailies,
            difficulty: .bronze,
            goal: 10,
            rewardAmount: 100
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "dailies_expert") ?? UUID(),
            title: "Daily Expert",
            description: "Complete 50 daily activities",
            category: .dailies,
            difficulty: .silver,
            goal: 50,
            rewardAmount: 300
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "streak_week") ?? UUID(),
            title: "Weekly Streak",
            description: "Maintain a 7-day login streak",
            category: .dailies,
            difficulty: .bronze,
            goal: 7,
            rewardAmount: 150
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "streak_month") ?? UUID(),
            title: "Monthly Dedication",
            description: "Maintain a 30-day login streak",
            category: .dailies,
            difficulty: .gold,
            goal: 30,
            rewardAmount: 1000
        ))
        
        // Collection Achievements
        achievements.append(Achievement(
            id: UUID(uuidString: "collection_novice") ?? UUID(),
            title: "Collector Beginner",
            description: "Collect 3 different accessories",
            category: .collection,
            difficulty: .bronze,
            goal: 3,
            rewardAmount: 100
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "collection_expert") ?? UUID(),
            title: "Collector Expert",
            description: "Collect 10 different accessories",
            category: .collection,
            difficulty: .gold,
            goal: 10,
            rewardAmount: 500
        ))
        
        // Pet Leveling and Evolution
        achievements.append(Achievement(
            id: UUID(uuidString: "level_5") ?? UUID(),
            title: "Rising Star",
            description: "Reach pet level 5",
            category: .petCare,
            difficulty: .bronze,
            goal: 5,
            rewardAmount: 100
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "level_10") ?? UUID(),
            title: "Experienced Keeper",
            description: "Reach pet level 10",
            category: .petCare,
            difficulty: .silver,
            goal: 10,
            rewardAmount: 250
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "level_25") ?? UUID(),
            title: "Pet Master",
            description: "Reach pet level 25",
            category: .petCare,
            difficulty: .gold,
            goal: 25,
            rewardAmount: 1000
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "evolution_child") ?? UUID(),
            title: "First Evolution",
            description: "Evolve your pet to Child stage",
            category: .special,
            difficulty: .bronze,
            goal: 1,
            rewardAmount: 150
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "evolution_teen") ?? UUID(),
            title: "Second Evolution",
            description: "Evolve your pet to Teen stage",
            category: .special,
            difficulty: .silver,
            goal: 1,
            rewardAmount: 300
        ))
        
        achievements.append(Achievement(
            id: UUID(uuidString: "evolution_adult") ?? UUID(),
            title: "Final Evolution",
            description: "Evolve your pet to Adult stage",
            category: .special,
            difficulty: .gold,
            goal: 1,
            rewardAmount: 500
        ))
        
        // Hidden/Special Achievements
        achievements.append(Achievement(
            id: UUID(uuidString: "perfect_pet") ?? UUID(),
            title: "Perfect Balance",
            description: "Have all pet stats at 90 or above simultaneously",
            category: .special,
            difficulty: .platinum,
            goal: 1,
            rewardAmount: 1000,
            hidden: true
        ))
        
        saveAchievements()
    }
    
    // For testing only - reset all achievements
    func resetAllAchievements() {
        for i in 0..<achievements.count {
            achievements[i].isUnlocked = false
            achievements[i].progress = 0
            achievements[i].dateUnlocked = nil
        }
        recentlyUnlocked = []
        saveAchievements()
        saveRecentlyUnlocked()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
