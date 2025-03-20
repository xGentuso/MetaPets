//
//  Pet.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct Pet: Codable, Identifiable {
    var id = UUID()
    var name: String
    var type: PetType
    var birthDate: Date
    var stage: GrowthStage = .baby
    
    // Stats (0-100)
    var hunger: Double = 70
    var happiness: Double = 70
    var health: Double = 100
    var cleanliness: Double = 70
    var energy: Double = 70
    
    // Experience and leveling
    var experience: Int = 0
    var level: Int = 1
    
    // Custom appearance options
    var accessories: [Accessory] = []
    var color: Color = .blue
    
    // Current primary status based on lowest stat
    var currentStatus: PetStatus {
        switch min(hunger, min(happiness, min(health, min(cleanliness, energy)))) {
        case _ where health < 30: return .sick
        case _ where hunger < 30: return .hungry
        case _ where cleanliness < 30: return .dirty
        case _ where energy < 30: return .sleepy
        default: return .happy
        }
    }
    
    // Time-based calculations
    var age: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: Date()).day ?? 0
    }
    
    // Mutating functions to update pet
    mutating func feed(food: Food) {
        hunger = min(100, hunger + food.nutritionValue)
        health = min(100, health + food.healthValue)
        cleanliness = max(0, cleanliness - food.messValue)
        
        addExperience(5)
    }
    
    mutating func play(game: Game) {
        happiness = min(100, happiness + game.funValue)
        energy = max(0, energy - game.energyCost)
        cleanliness = max(0, cleanliness - game.messValue)
        
        addExperience(10)
    }
    
    mutating func clean() {
        cleanliness = 100
        happiness = max(0, happiness - 5) // Pets don't always like baths
        
        addExperience(5)
    }
    
    mutating func sleep(hours: Int) {
        energy = min(100, energy + Double(hours) * 10)
        hunger = max(0, hunger - Double(hours) * 5)
        
        addExperience(hours * 2)
    }
    
    mutating func heal(medicine: Medicine) {
        health = min(100, health + medicine.healthValue)
        happiness = max(0, happiness - medicine.bitternessValue)
        
        addExperience(15)
    }
    
    private mutating func addExperience(_ amount: Int) {
        experience += amount
        
        // Check for level up
        let nextLevelThreshold = level * 100
        if experience >= nextLevelThreshold {
            level += 1
            
            // Check for evolution
            if level % 5 == 0, let nextStage = stage.nextStage {
                stage = nextStage
            }
        }
    }
    
    // Time-based stat decreases
    mutating func updateWithTimeElapsed(_ timeInterval: TimeInterval) {
        // Decrease stats based on time passing (in hours)
        let hours = timeInterval / 3600
        hunger = max(0, hunger - hours * 5)
        happiness = max(0, happiness - hours * 3)
        cleanliness = max(0, cleanliness - hours * 2)
        energy = max(0, energy - hours * 4)
        
        // Health decreases if other stats are too low
        if hunger < 20 || cleanliness < 20 || energy < 20 {
            health = max(0, health - hours * 10)
        }
    }
}

// MARK: - Codable extensions for Color
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        guard let colorComponents = UIColor(self).cgColor.components else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Could not get color components"))
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Double(colorComponents[0]), forKey: .red)
        try container.encode(Double(colorComponents[1]), forKey: .green)
        try container.encode(Double(colorComponents[2]), forKey: .blue)
        try container.encode(Double(colorComponents[3]), forKey: .opacity)
    }
}
