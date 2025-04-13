//
//  Medicine.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

struct Medicine: Identifiable, Codable {
    var id = UUID()
    var name: String
    var healthValue: Double
    var bitternessValue: Double
    var price: Int
    var imageName: String
}
