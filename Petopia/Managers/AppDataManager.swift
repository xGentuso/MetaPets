//
//  AppDataManager.swift
//  Petopia
//
//  Created for Petopia data persistence
//

import Foundation

class AppDataManager {
    static let shared = AppDataManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    private let petKey = "SavedPet"
    private let lastPlayedKey = "MinigameLastPlayed"
    private let currencyTransactionsKey = "CurrencyTransactions"
    private let lastDailyBonusKey = "LastDailyBonusDate"
    private let dailyBonusStreakKey = "DailyBonusStreak"
    private let dailiesKey = "SavedDailyActivities"
    private let achievementsKey = "SavedAchievements"
    private let recentUnlocksKey = "RecentlyUnlockedAchievements"
    private let onboardingCompleteKey = "HasCompletedOnboarding"
    private let tipsSeenKey = "TipsTopicsSeen"
    
    // MARK: - Save Methods
    
    // Save all app data
    func saveAllData(viewModel: PetViewModel) async {
        // Save on a background thread
        await MainActor.run {
            if let encoded = try? JSONEncoder().encode(viewModel.pet) {
                userDefaults.set(encoded, forKey: petKey)
                userDefaults.synchronize()
            }
        }
    }
    
    // MARK: - Load Methods
    
    // Load pet data
    func loadPet() -> Pet? {
        if let savedPetData = userDefaults.data(forKey: petKey),
           let savedPet = try? JSONDecoder().decode(Pet.self, from: savedPetData) {
            return savedPet
        }
        return nil
    }
    
    // Load streak data
    func loadDailyBonusData() -> (Date?, Int) {
        let lastBonusDate = userDefaults.object(forKey: lastDailyBonusKey) as? Date
        let streak = userDefaults.integer(forKey: dailyBonusStreakKey)
        return (lastBonusDate, streak)
    }
    
    // MARK: - Onboarding Data
    
    // Check if onboarding has been completed
    func hasCompletedOnboarding() -> Bool {
        return userDefaults.bool(forKey: onboardingCompleteKey)
    }
    
    // Save onboarding completion state
    func setOnboardingComplete(_ complete: Bool) {
        userDefaults.set(complete, forKey: onboardingCompleteKey)
        userDefaults.synchronize()
    }
    
    // Create a new pet from onboarding
    func createNewPet(name: String, type: PetType) -> Pet {
        print("DEBUG: AppDataManager creating new pet: \(name) the \(type.rawValue)")
        
        // Create a completely fresh pet with the specified type
        let newPet = Pet(
            id: UUID(), // Force a new ID
            name: name,
            type: type,
            birthDate: Date(),
            stage: .baby,
            hunger: 70,
            happiness: 70,
            health: 100,
            cleanliness: 70,
            energy: 70,
            currency: 50,
            experience: 0,
            level: 1,
            accessories: []
        )
        
        // Save the pet directly to UserDefaults
        do {
            let encoded = try JSONEncoder().encode(newPet)
            userDefaults.set(encoded, forKey: petKey)
            userDefaults.synchronize()
            print("DEBUG: AppDataManager directly saved new pet to UserDefaults")
            
            // Verify the save immediately
            if let data = userDefaults.data(forKey: petKey),
               let pet = try? JSONDecoder().decode(Pet.self, from: data) {
                print("DEBUG: VERIFICATION - Pet type is: \(pet.type.rawValue)")
            }
        } catch {
            print("DEBUG: CRITICAL ERROR - Failed to encode pet: \(error)")
        }
        
        return newPet
    }
    
    // MARK: - Tips Tracking
    
    // Mark a tip category as seen
    func markTipCategorySeen(_ category: String) {
        var seenCategories = userDefaults.stringArray(forKey: tipsSeenKey) ?? []
        if !seenCategories.contains(category) {
            seenCategories.append(category)
            userDefaults.set(seenCategories, forKey: tipsSeenKey)
        }
    }
    
    // Check if a tip category has been seen
    func hasTipCategoryBeenSeen(_ category: String) -> Bool {
        let seenCategories = userDefaults.stringArray(forKey: tipsSeenKey) ?? []
        return seenCategories.contains(category)
    }
    
    // MARK: - Data Management
    
    // Clear all data (for testing or resetting)
    func clearAllData() {
        userDefaults.removeObject(forKey: petKey)
        userDefaults.removeObject(forKey: lastPlayedKey)
        userDefaults.removeObject(forKey: currencyTransactionsKey)
        userDefaults.removeObject(forKey: lastDailyBonusKey)
        userDefaults.removeObject(forKey: dailyBonusStreakKey)
        userDefaults.removeObject(forKey: dailiesKey)
        userDefaults.removeObject(forKey: achievementsKey)
        userDefaults.removeObject(forKey: recentUnlocksKey)
        userDefaults.removeObject(forKey: onboardingCompleteKey)
        userDefaults.removeObject(forKey: tipsSeenKey)
        
        // Also clear data in specific managers
        CurrencyManager.shared.clearTransactions()
        DailiesManager.shared.resetAllActivities()
        AchievementManager.shared.resetAllAchievements()
        
        print("All app data cleared")
    }
    
    // MARK: - Data Backup & Restore
    
    // Export all data to a JSON file (for backup)
    func exportData() -> Data? {
        var exportDict: [String: Any] = [:]
        
        // Add UserDefaults data
        if let pet = loadPet(), let petData = try? JSONEncoder().encode(pet) {
            exportDict["pet"] = petData.base64EncodedString()
        }
        
        exportDict["dailyBonusStreak"] = userDefaults.integer(forKey: dailyBonusStreakKey)
        if let lastBonusDate = userDefaults.object(forKey: lastDailyBonusKey) as? Date {
            exportDict["lastDailyBonusDate"] = lastBonusDate.timeIntervalSince1970
        }
        
        // Convert to JSON
        return try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
    }
    
    // Import data from JSON (for restore)
    func importData(jsonData: Data) -> Bool {
        do {
            guard let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return false
            }
            
            // Restore pet data
            if let petBase64 = dict["pet"] as? String,
               let petData = Data(base64Encoded: petBase64),
               let pet = try? JSONDecoder().decode(Pet.self, from: petData) {
                if let encoded = try? JSONEncoder().encode(pet) {
                    userDefaults.set(encoded, forKey: petKey)
                }
            }
            
            // Restore other simple data
            if let streak = dict["dailyBonusStreak"] as? Int {
                userDefaults.set(streak, forKey: dailyBonusStreakKey)
            }
            
            if let lastBonusTimeInterval = dict["lastDailyBonusDate"] as? TimeInterval {
                let date = Date(timeIntervalSince1970: lastBonusTimeInterval)
                userDefaults.set(date, forKey: lastDailyBonusKey)
            }
            
            return true
        } catch {
            print("Error importing data: \(error)")
            return false
        }
    }
    
    func saveDailyBonusData(date: Date, streak: Int) {
        userDefaults.set(date, forKey: lastDailyBonusKey)
        userDefaults.set(streak, forKey: dailyBonusStreakKey)
        userDefaults.synchronize()
    }
}
