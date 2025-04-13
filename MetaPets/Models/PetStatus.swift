//
//  PetStatus.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

enum PetStatus: String, Codable {
    case happy, hungry, sick, sleepy, dirty
    
    var description: String {
        switch self {
        case .happy: return "Happy"
        case .hungry: return "Hungry"
        case .sick: return "Sick"
        case .sleepy: return "Sleepy"
        case .dirty: return "Dirty"
        }
    }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .hungry: return "🍽️"
        case .sick: return "🤒"
        case .sleepy: return "😴"
        case .dirty: return "🧼"
        }
    }
}
