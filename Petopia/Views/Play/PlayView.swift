//
//  PlayView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct PlayView: View {
    @ObservedObject var viewModel: PetViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.availableGames) { game in
                Button(action: {
                    viewModel.play(game: game)
                }) {
                    HStack {
                        Image(systemName: "gamecontroller")
                            .foregroundColor(.green)
                            .frame(width: 30, height: 30)
                        
                        VStack(alignment: .leading) {
                            Text(game.name)
                                .font(.headline)
                            Text("Fun: +\(Int(game.funValue)) • Energy: -\(Int(game.energyCost))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Play with \(viewModel.pet.name)")
        }
    }
}

struct PlayView_Previews: PreviewProvider {
    static var previews: some View {
        PlayView(viewModel: PetViewModel())
    }
}
