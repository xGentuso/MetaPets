//
//  PetType.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

enum PetType: String, CaseIterable, Codable {
    case cat, chicken, cow, pig, sheep
    
    var baseImage: String {
        self.rawValue
    }
}
