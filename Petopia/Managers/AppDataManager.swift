//
//  AppDataManager.swift
//  Petopia
//
//  Created for Petopia data persistence
//

import Foundation

class AppDataManager {
    static let shared = AppDataManager()
    
    private let petKey = "SavedPet"
    private let lastPlayedKey = "MinigameLastPlayed"
    private let currencyTransactionsKey = "CurrencyTransactions"
    private let lastDailyBonusKey = "LastDailyBonusDate"
    private let dailyBonusStreakKey = "DailyBonusStreak"
    private let dailiesKey = "SavedDailyActivities"
    private let achievementsKey = "SavedAchievements"
    private let recentUnlocksKey = "RecentlyUnlockedAchievements"
    
    // Save all app data
    func saveAllData(viewModel: PetViewModel) {
        // Save pet data
        if let encoded = try? JSONEncoder().encode(viewModel.pet) {
            UserDefaults.standard.set(encoded, forKey: petKey)
        }
        
        // Save streak data
        if let lastDate = viewModel.lastDailyBonusDate {
            UserDefaults.standard.set(lastDate, forKey: lastDailyBonusKey)
        }
        UserDefaults.standard.set(viewModel.dailyBonusStreak, forKey: dailyBonusStreakKey)
        
        // Save dailies data (handled by DailiesManager)
        // Save minigames data (handled by MinigameManager)
        // Save currency transactions (handled by CurrencyManager)
        // Save achievements data (handled by AchievementManager)
    }
    
    // Load pet data
    func loadPet() -> Pet? {
        if let savedPetData = UserDefaults.standard.data(forKey: petKey),
           let pet = try? JSONDecoder().decode(Pet.self, from: savedPetData) {
            return pet
        }
        return nil
    }
    
    // Load streak data
    func loadDailyBonusData() -> (Date?, Int) {
        let lastDate = UserDefaults.standard.object(forKey: lastDailyBonusKey) as? Date
        let streak = UserDefaults.standard.integer(forKey: dailyBonusStreakKey)
        return (lastDate, streak)
    }
    
    // Clear all data (for testing or resetting)
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: petKey)
        UserDefaults.standard.removeObject(forKey: lastPlayedKey)
        UserDefaults.standard.removeObject(forKey: currencyTransactionsKey)
        UserDefaults.standard.removeObject(forKey: lastDailyBonusKey)
        UserDefaults.standard.removeObject(forKey: dailyBonusStreakKey)
        UserDefaults.standard.removeObject(forKey: dailiesKey)
        UserDefaults.standard.removeObject(forKey: achievementsKey)
        UserDefaults.standard.removeObject(forKey: recentUnlocksKey)
        
        // Also clear data in specific managers
        CurrencyManager.shared.clearTransactions()
        DailiesManager.shared.resetAllActivities()
        AchievementManager.shared.resetAllAchievements()
        
        print("All app data cleared")
    }
}
