//
//  StatBar.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct StatBar: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.2)
                        .foregroundColor(color)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(value) * geometry.size.width / 100, geometry.size.width), height: 8)
                        .foregroundColor(color)
                        .cornerRadius(4)
                        .animation(.spring(), value: value)
                }
            }
            .frame(height: 8)
        }
    }
}

struct StatBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatBar(label: "Health", value: 75, color: .green)
            StatBar(label: "Hunger", value: 45, color: .orange)
            StatBar(label: "Happiness", value: 90, color: .blue)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
