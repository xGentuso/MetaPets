//
//  Accessory.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

struct Accessory: Identifiable, Codable {
    var id = UUID()
    var name: String
    var position: AccessoryPosition
    var unlockLevel: Int
    var price: Int
    var imageName: String
    
    enum AccessoryPosition: String, Codable {
        case head, neck, body
    }
}
