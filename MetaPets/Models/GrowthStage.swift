//
//  GrowthStage.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

enum GrowthStage: String, CaseIterable, Codable {
    case baby, child, teen, adult
    
    var nextStage: GrowthStage? {
        switch self {
        case .baby: return .child
        case .child: return .teen
        case .teen: return .adult
        case .adult: return nil
        }
    }
}
