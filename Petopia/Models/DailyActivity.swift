//
//  DailyActivity.swift
//  Petopia
//
//  Created for Petopia dailies system
//

import Foundation
import SwiftUI

struct DailyActivity: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var imageName: String
    var lastCompletedDate: Date?
    var type: DailyActivityType
    var minReward: Int
    var maxReward: Int
    
    // Computed property to check if the activity can be done today
    var canCompleteToday: Bool {
        guard let lastCompleted = lastCompletedDate else {
            return true // Never completed before
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastCompletedDay = calendar.startOfDay(for: lastCompleted)
        
        return today != lastCompletedDay
    }
    
    // Helper method to mark this activity as completed
    mutating func markCompleted() {
        lastCompletedDate = Date()
    }
    
    // Get a random reward amount within the min-max range
    func getRandomReward() -> Int {
        return Int.random(in: minReward...maxReward)
    }
}

enum DailyActivityType: String, Codable, CaseIterable {
    case treasureChest
    case wheel
    case mysteryBox
    case foodBowl
    case petRock
    
    var displayName: String {
        switch self {
        case .treasureChest: return "Treasure Chest"
        case .wheel: return "Lucky Wheel"
        case .mysteryBox: return "Mystery Box"
        case .foodBowl: return "Food Bowl"
        case .petRock: return "Pet Rock"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .treasureChest: return "cube.box.fill"
        case .wheel: return "dial.medium"
        case .mysteryBox: return "shippingbox.fill"
        case .foodBowl: return "bowl.fill"
        case .petRock: return "fossil.shell.fill"
        }
    }
    
    var description: String {
        switch self {
        case .treasureChest: return "Find coins and treasures in this daily chest!"
        case .wheel: return "Spin the wheel for random rewards!"
        case .mysteryBox: return "What's inside today's mystery box?"
        case .foodBowl: return "Free daily pet food available here."
        case .petRock: return "Visit your pet rock for a guaranteed reward."
        }
    }
}
