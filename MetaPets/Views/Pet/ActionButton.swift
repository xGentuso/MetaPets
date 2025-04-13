//
//  ActionButton.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct ActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .frame(width: 60, height: 60)
            .padding(8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ActionButton(title: "Feed", systemImage: "fork.knife") {
                print("Feed action")
            }
            
            ActionButton(title: "Play", systemImage: "gamecontroller") {
                print("Play action")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
