//
//  Food.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

struct Food: Identifiable, Codable {
    var id = UUID()
    var name: String
    var nutritionValue: Double
    var healthValue: Double
    var messValue: Double
    var price: Int
    var imageName: String
}
