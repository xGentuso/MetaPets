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
    private let onboardingCompleteKey = "HasCompletedOnboarding"
    private let tipsSeenKey = "TipsTopicsSeen"
    
    // MARK: - Save Methods
    
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
    
    // MARK: - Load Methods
    
    // Load pet data
    func loadPet() -> Pet? {
        print("DEBUG: AppDataManager attempting to load pet")
        
        if let savedPetData = UserDefaults.standard.data(forKey: petKey) {
            do {
                let pet = try JSONDecoder().decode(Pet.self, from: savedPetData)
                print("DEBUG: AppDataManager successfully loaded pet: \(pet.name) the \(pet.type.rawValue)")
                return pet
            } catch {
                print("DEBUG: ERROR - AppDataManager failed to decode pet: \(error)")
                
                // In case of decoding error, try to recover what we can
                print("DEBUG: Attempting data recovery, raw data: \(savedPetData.count) bytes")
                
                // Clear data in case of corruption
                UserDefaults.standard.removeObject(forKey: petKey)
                UserDefaults.standard.synchronize()
                
                return nil
            }
        } else {
            print("DEBUG: AppDataManager found no saved pet data")
            return nil
        }
    }
    
    // Load streak data
    func loadDailyBonusData() -> (Date?, Int) {
        let lastDate = UserDefaults.standard.object(forKey: lastDailyBonusKey) as? Date
        let streak = UserDefaults.standard.integer(forKey: dailyBonusStreakKey)
        return (lastDate, streak)
    }
    
    // MARK: - Onboarding Data
    
    // Check if onboarding has been completed
    func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: onboardingCompleteKey)
    }
    
    // Save onboarding completion state
    func setOnboardingComplete(_ complete: Bool) {
        UserDefaults.standard.set(complete, forKey: onboardingCompleteKey)
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
            UserDefaults.standard.set(encoded, forKey: petKey)
            UserDefaults.standard.synchronize()
            print("DEBUG: AppDataManager directly saved new pet to UserDefaults")
            
            // Verify the save immediately
            if let data = UserDefaults.standard.data(forKey: petKey),
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
        var seenCategories = UserDefaults.standard.stringArray(forKey: tipsSeenKey) ?? []
        if !seenCategories.contains(category) {
            seenCategories.append(category)
            UserDefaults.standard.set(seenCategories, forKey: tipsSeenKey)
        }
    }
    
    // Check if a tip category has been seen
    func hasTipCategoryBeenSeen(_ category: String) -> Bool {
        let seenCategories = UserDefaults.standard.stringArray(forKey: tipsSeenKey) ?? []
        return seenCategories.contains(category)
    }
    
    // MARK: - Data Management
    
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
        UserDefaults.standard.removeObject(forKey: onboardingCompleteKey)
        UserDefaults.standard.removeObject(forKey: tipsSeenKey)
        
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
        
        exportDict["dailyBonusStreak"] = UserDefaults.standard.integer(forKey: dailyBonusStreakKey)
        if let lastBonusDate = UserDefaults.standard.object(forKey: lastDailyBonusKey) as? Date {
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
                    UserDefaults.standard.set(encoded, forKey: petKey)
                }
            }
            
            // Restore other simple data
            if let streak = dict["dailyBonusStreak"] as? Int {
                UserDefaults.standard.set(streak, forKey: dailyBonusStreakKey)
            }
            
            if let lastBonusTimeInterval = dict["lastDailyBonusDate"] as? TimeInterval {
                let date = Date(timeIntervalSince1970: lastBonusTimeInterval)
                UserDefaults.standard.set(date, forKey: lastDailyBonusKey)
            }
            
            return true
        } catch {
            print("Error importing data: \(error)")
            return false
        }
    }
}
