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
    
    private func loadMinigames() {
        // In a real app, you might load these from a data source
        availableMinigames = [
            // Memory Match games
            Minigame(
                name: "Pet Match",
                description: "Match pairs of pet cards before time runs out!",
                difficulty: .easy,
                type: .memoryMatch,
                rewardAmount: 10,
                imageName: "game_memory",
                cooldownMinutes: 15
            ),
            
            Minigame(
                name: "Food Pairs",
                description: "Match pairs of pet food to earn rewards!",
                difficulty: .medium,
                type: .memoryMatch,
                rewardAmount: 15,
                imageName: "game_memory",
                cooldownMinutes: 30
            ),
            
            // Quick Tap games
            Minigame(
                name: "Treat Catch",
                description: "Tap falling treats before they hit the ground!",
                difficulty: .easy,
                type: .quickTap,
                rewardAmount: 8,
                imageName: "game_tap",
                cooldownMinutes: 10
            ),
            
            Minigame(
                name: "Bubble Pop",
                description: "Pop as many bubbles as you can in 30 seconds!",
                difficulty: .medium,
                type: .quickTap,
                rewardAmount: 12,
                imageName: "game_tap",
                cooldownMinutes: 20
            ),
            
            // Pattern games
            Minigame(
                name: "Pet Simon",
                description: "Remember and repeat the pattern of sounds and colors!",
                difficulty: .medium,
                type: .patternRecognition,
                rewardAmount: 18,
                imageName: "game_pattern",
                cooldownMinutes: 45
            ),
            
            // Quiz game
            Minigame(
                name: "Pet Care Quiz",
                description: "Test your pet care knowledge and earn rewards!",
                difficulty: .hard,
                type: .petCare,
                rewardAmount: 25,
                imageName: "game_quiz",
                cooldownMinutes: 60
            )
        ]
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
