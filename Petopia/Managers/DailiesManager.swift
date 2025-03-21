//
//  DailiesManager.swift
//  Petopia
//
//  Created for Petopia dailies system
//

import Foundation

class DailiesManager {
    static let shared = DailiesManager()
    
    private(set) var dailyActivities: [DailyActivity] = []
    private let dailiesKey = "SavedDailyActivities"
    
    private init() {
        loadDailyActivities()
        
        // If no activities exist yet, create the default ones
        if dailyActivities.isEmpty {
            createDefaultActivities()
        }
    }
    
    // Create default daily activities for first-time users
    private func createDefaultActivities() {
        dailyActivities = [
            DailyActivity(
                name: "Treasure Chest",
                description: "Open a treasure chest for random coins and prizes.",
                imageName: "treasure_chest",
                type: .treasureChest,
                minReward: 50,
                maxReward: 150
            ),
            
            DailyActivity(
                name: "Lucky Wheel",
                description: "Spin the wheel and try your luck for rewards.",
                imageName: "lucky_wheel",
                type: .wheel,
                minReward: 10,
                maxReward: 300
            ),
            
            DailyActivity(
                name: "Mystery Box",
                description: "Receive a reward from the mystery box. Contents change daily!",
                imageName: "mystery_box",
                type: .mysteryBox,
                minReward: 25,
                maxReward: 200
            ),
            
            DailyActivity(
                name: "Food Bowl",
                description: "Collect free food for your pet each day.",
                imageName: "food_bowl",
                type: .foodBowl,
                minReward: 40,
                maxReward: 100
            ),
            
            DailyActivity(
                name: "Pet Rock",
                description: "Visit your pet rock for a small but guaranteed daily reward.",
                imageName: "pet_rock",
                type: .petRock,
                minReward: 15,
                maxReward: 30
            )
        ]
        
        saveDailyActivities()
    }
    
    // Complete a specific daily activity and return the reward
    func completeActivity(id: UUID) -> Int? {
        guard let index = dailyActivities.firstIndex(where: { $0.id == id }),
              dailyActivities[index].canCompleteToday else {
            return nil
        }
        
        let reward = dailyActivities[index].getRandomReward()
        dailyActivities[index].markCompleted()
        saveDailyActivities()
        
        return reward
    }
    
    // Get activities that can be completed today
    func getAvailableActivities() -> [DailyActivity] {
        return dailyActivities.filter { $0.canCompleteToday }
    }
    
    // Reset a specific activity (for testing)
    func resetActivity(id: UUID) {
        if let index = dailyActivities.firstIndex(where: { $0.id == id }) {
            dailyActivities[index].lastCompletedDate = nil
            saveDailyActivities()
        }
    }
    
    // Reset all activities (for testing)
    func resetAllActivities() {
        for index in dailyActivities.indices {
            dailyActivities[index].lastCompletedDate = nil
        }
        saveDailyActivities()
    }
    
    // Load saved activities from UserDefaults
    private func loadDailyActivities() {
        if let savedData = UserDefaults.standard.data(forKey: dailiesKey),
           let activities = try? JSONDecoder().decode([DailyActivity].self, from: savedData) {
            dailyActivities = activities
        }
    }
    
    // Save activities to UserDefaults
    private func saveDailyActivities() {
        if let encoded = try? JSONEncoder().encode(dailyActivities) {
            UserDefaults.standard.set(encoded, forKey: dailiesKey)
        }
    }
}
