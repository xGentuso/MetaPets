//
//  Game.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

struct Game: Identifiable, Codable {
    var id = UUID()
    var name: String
    var funValue: Double
    var energyCost: Double
    var messValue: Double
    var imageName: String
}
