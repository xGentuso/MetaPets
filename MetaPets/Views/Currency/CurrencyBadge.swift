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
                .font(.system(size: 16, weight: .bold))
            
            Text("\(amount)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.2))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
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
