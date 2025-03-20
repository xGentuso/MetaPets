//
//  CurrencyBadge.swift
//  Petopia
//
//  Created for Petopia currency system
//

import SwiftUI

struct CurrencyBadge: View {
    let amount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.yellow)
            
            Text("\(amount)")
                .fontWeight(.bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.2))
        )
    }
}

struct CurrencyBadge_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyBadge(amount: 250)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
