//
//  MinigameManager.swift
//  Petopia
//
//  Created for Petopia minigames system
//

//
//  MinigameManager.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import Foundation

class MinigameManager {
    static let shared = MinigameManager()
    
    var availableMinigames: [Minigame] = []
    private var lastPlayedTimes: [UUID: Date] = [:]
    
    private init() {
        loadMinigames()
        loadLastPlayedTimes()
    }
    
    // Load minigames with default pet type (will be refreshed later with correct type)
    private func loadMinigames(petType: PetType = .cat) {
        // In a real app, you might load these from a data source
        availableMinigames = [
            // Memory Match games - only keep one per pet type
            Minigame(
                name: getPetSpecificName("Food Pairs", petType: petType),
                description: getPetSpecificDescription("Match pairs of pet food to earn rewards!", petType: petType),
                difficulty: .medium,
                type: .memoryMatch,
                rewardAmount: 15,
                imageName: "game_memory",
                cooldownMinutes: 30,
                petType: petType
            ),
            
            // Quick Tap games
            Minigame(
                name: getPetSpecificName("Treat Catch", petType: petType),
                description: getPetSpecificDescription("Tap falling treats before they hit the ground!", petType: petType),
                difficulty: .easy,
                type: .quickTap,
                rewardAmount: 8,
                imageName: "game_tap",
                cooldownMinutes: 10,
                petType: petType
            ),
            
            Minigame(
                name: getPetSpecificName("Bubble Pop", petType: petType),
                description: getPetSpecificDescription("Pop as many bubbles as you can in 30 seconds!", petType: petType),
                difficulty: .medium,
                type: .quickTap,
                rewardAmount: 12,
                imageName: "game_tap",
                cooldownMinutes: 20,
                petType: petType
            ),
            
            // Pattern games
            Minigame(
                name: getPetSpecificName("Pet Simon", petType: petType),
                description: getPetSpecificDescription("Remember and repeat the pattern of sounds and colors!", petType: petType),
                difficulty: .medium,
                type: .patternRecognition,
                rewardAmount: 18,
                imageName: "game_pattern",
                cooldownMinutes: 45,
                petType: petType
            ),
            
            // Quiz game
            Minigame(
                name: getPetSpecificName("Pet Care Quiz", petType: petType),
                description: getPetSpecificDescription("Test your pet care knowledge and earn rewards!", petType: petType),
                difficulty: .hard,
                type: .petCare,
                rewardAmount: 25,
                imageName: "game_quiz",
                cooldownMinutes: 60,
                petType: petType
            )
        ]
    }
    
    // Get pet-specific name for a game
    private func getPetSpecificName(_ baseName: String, petType: PetType) -> String {
        switch (baseName, petType) {
        case ("Food Pairs", .cat): return "Cat Food Pairs"
        case ("Food Pairs", .chicken): return "Chicken Feed Pairs"
        case ("Food Pairs", .cow): return "Hay & Grain Pairs"
        case ("Food Pairs", .pig): return "Pig Feed Pairs"
        case ("Food Pairs", .sheep): return "Sheep Feed Pairs"
            
        case ("Treat Catch", .cat): return "Cat Treat Chase"
        case ("Treat Catch", .chicken): return "Seed Catch"
        case ("Treat Catch", .cow): return "Apple Catch"
        case ("Treat Catch", .pig): return "Veggie Catch"
        case ("Treat Catch", .sheep): return "Clover Catch"
            
        case ("Pet Simon", .cat): return "Cat Simon"
        case ("Pet Simon", .chicken): return "Chicken Simon"
        case ("Pet Simon", .cow): return "Cow Simon"
        case ("Pet Simon", .pig): return "Pig Simon"
        case ("Pet Simon", .sheep): return "Sheep Simon"
            
        case ("Pet Care Quiz", .cat): return "Cat Care Quiz"
        case ("Pet Care Quiz", .chicken): return "Chicken Care Quiz"
        case ("Pet Care Quiz", .cow): return "Cow Care Quiz"
        case ("Pet Care Quiz", .pig): return "Pig Care Quiz"
        case ("Pet Care Quiz", .sheep): return "Sheep Care Quiz"
            
        default: return baseName
        }
    }
    
    // Get pet-specific description for a game
    private func getPetSpecificDescription(_ baseDescription: String, petType: PetType) -> String {
        switch petType {
        case .cat:
            if baseDescription.contains("pet") {
                return baseDescription.replacingOccurrences(of: "pet", with: "cat")
            }
        case .chicken:
            if baseDescription.contains("pet") {
                return baseDescription.replacingOccurrences(of: "pet", with: "chicken")
            }
        case .cow:
            if baseDescription.contains("pet") {
                return baseDescription.replacingOccurrences(of: "pet", with: "cow")
            }
        case .pig:
            if baseDescription.contains("pet") {
                return baseDescription.replacingOccurrences(of: "pet", with: "pig")
            }
        case .sheep:
            if baseDescription.contains("pet") {
                return baseDescription.replacingOccurrences(of: "pet", with: "sheep")
            }
        }
        return baseDescription
    }
    
    // Refresh minigames with current pet type
    func refreshMinigames(petType: PetType) {
        // Save currently played times
        let savedLastPlayedTimes = lastPlayedTimes
        
        // Reload minigames with the specific pet type
        loadMinigames(petType: petType)
        
        // Restore play times
        lastPlayedTimes = savedLastPlayedTimes
    }
    
    func canPlay(minigame: Minigame) -> Bool {
        guard let lastPlayed = lastPlayedTimes[minigame.id] else {
            return true
        }
        
        let cooldownSeconds = minigame.cooldownMinutes * 60
        let timeElapsed = Date().timeIntervalSince(lastPlayed)
        
        return timeElapsed >= Double(cooldownSeconds)
    }
    
    func timeUntilAvailable(minigame: Minigame) -> TimeInterval {
        guard let lastPlayed = lastPlayedTimes[minigame.id] else {
            return 0
        }
        
        let cooldownSeconds = minigame.cooldownMinutes * 60
        let timeElapsed = Date().timeIntervalSince(lastPlayed)
        
        return max(0, Double(cooldownSeconds) - timeElapsed)
    }
    
    func recordGamePlayed(minigame: Minigame) {
        lastPlayedTimes[minigame.id] = Date()
        saveLastPlayedTimes()
    }
    
    private func saveLastPlayedTimes() {
        var storedTimes: [String: Date] = [:]
        
        for (id, date) in lastPlayedTimes {
            storedTimes[id.uuidString] = date
        }
        
        // Use PropertyListEncoder for more robust Date encoding
        if let encoded = try? PropertyListEncoder().encode(storedTimes) {
            UserDefaults.standard.set(encoded, forKey: "MinigameLastPlayed")
        }
    }
    
    private func loadLastPlayedTimes() {
        guard let data = UserDefaults.standard.data(forKey: "MinigameLastPlayed") else {
            return
        }
        
        do {
            let storedTimes = try PropertyListDecoder().decode([String: Date].self, from: data)
            
            for (idString, date) in storedTimes {
                if let id = UUID(uuidString: idString) {
                    lastPlayedTimes[id] = date
                }
            }
        } catch {
            print("Error loading minigame times: \(error)")
        }
    }
    
    // For testing or resetting
    func clearPlayTimes() {
        lastPlayedTimes = [:]
        saveLastPlayedTimes()
    }
}
