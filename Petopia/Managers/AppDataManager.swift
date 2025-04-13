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
    private let petTypeKey = "PetType"
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
        do {
            // Encode and save the pet data
            let encoded = try JSONEncoder().encode(viewModel.pet)
            
            // Save on the main thread since UserDefaults is UI-related
            await MainActor.run {
                userDefaults.set(encoded, forKey: petKey)
                
                // Also ensure the pet type is saved to our single source of truth
                userDefaults.set(viewModel.pet.type.rawValue, forKey: petTypeKey)
            }
        } catch {
            print("Error saving pet data: \(error.localizedDescription)")
            // Log error for analytics in a real app
        }
    }
    
    // MARK: - Load Methods
    
    // Load pet data with better error handling
    func loadPet() -> Pet? {
        do {
            if let savedPetData = userDefaults.data(forKey: petKey) {
                return try JSONDecoder().decode(Pet.self, from: savedPetData)
            } else {
                print("No pet data found in UserDefaults")
            }
        } catch {
            print("Error decoding pet data: \(error.localizedDescription)")
            
            // Check if we can recover the pet type at least
            if let typeString = userDefaults.string(forKey: petTypeKey),
               let type = PetType(rawValue: typeString) {
                // Create a recovery pet with the correct type
                print("Creating recovery pet with type: \(type.rawValue)")
                return Pet(
                    name: "Buddy", 
                    type: type,
                    birthDate: Date()
                )
            }
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
        print("AppDataManager creating new pet: \(name) the \(type.rawValue)")
        
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
            
            // Save pet type to our single source of truth
            userDefaults.set(type.rawValue, forKey: petTypeKey)
            
            print("AppDataManager saved new pet to UserDefaults")
        } catch {
            print("ERROR - Failed to encode pet: \(error)")
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
        userDefaults.removeObject(forKey: petTypeKey)
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
        do {
            var exportDict: [String: Any] = [:]
            
            // Add UserDefaults data
            if let pet = loadPet() {
                if let petData = try? JSONEncoder().encode(pet) {
                    exportDict["pet"] = petData.base64EncodedString()
                    exportDict["petType"] = pet.type.rawValue // Export pet type separately too
                }
            }
            
            exportDict["dailyBonusStreak"] = userDefaults.integer(forKey: dailyBonusStreakKey)
            if let lastBonusDate = userDefaults.object(forKey: lastDailyBonusKey) as? Date {
                exportDict["lastDailyBonusDate"] = lastBonusDate.timeIntervalSince1970
            }
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            return jsonData
        } catch {
            print("Error exporting data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Import data from JSON (for restore)
    func importData(jsonData: Data) -> Bool {
        do {
            let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            
            guard let dictionary = dict else {
                print("Error importing data: Invalid JSON format")
                return false
            }
            
            // Restore pet data
            if let petBase64 = dictionary["pet"] as? String {
                if let petData = Data(base64Encoded: petBase64) {
                    do {
                        let pet = try JSONDecoder().decode(Pet.self, from: petData)
                        let encoded = try JSONEncoder().encode(pet)
                        userDefaults.set(encoded, forKey: petKey)
                        
                        // Also save pet type to our single source of truth
                        userDefaults.set(pet.type.rawValue, forKey: petTypeKey)
                    } catch {
                        print("Error decoding pet data during import: \(error.localizedDescription)")
                        
                        // Try to recover pet type at least
                        if let petType = dictionary["petType"] as? String {
                            userDefaults.set(petType, forKey: petTypeKey)
                        }
                    }
                }
            }
            
            // Restore other simple data
            if let streak = dictionary["dailyBonusStreak"] as? Int {
                userDefaults.set(streak, forKey: dailyBonusStreakKey)
            }
            
            if let lastBonusTimeInterval = dictionary["lastDailyBonusDate"] as? TimeInterval {
                let date = Date(timeIntervalSince1970: lastBonusTimeInterval)
                userDefaults.set(date, forKey: lastDailyBonusKey)
            }
            
            return true
        } catch {
            print("Error importing data: \(error.localizedDescription)")
            return false
        }
    }
    
    func saveDailyBonusData(date: Date, streak: Int) {
        userDefaults.set(date, forKey: lastDailyBonusKey)
        userDefaults.set(streak, forKey: dailyBonusStreakKey)
        userDefaults.synchronize()
    }
}
