//
//  PlayTabView.swift
//  Petopia
//
//  Created for Petopia
//

import SwiftUI

struct PlayTabView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var selection = 0
    
    var body: some View {
        VStack {
            Picker("Play Type", selection: $selection) {
                Text("Activities").tag(0)
                Text("Minigames").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selection == 0 {
                // Standard pet play activities
                PlayView(viewModel: viewModel)
            } else {
                // Minigames
                MinigamesListView(viewModel: viewModel)
            }
        }
    }
}

struct PlayTabView_Previews: PreviewProvider {
    static var previews: some View {
        PlayTabView(viewModel: PetViewModel())
    }
}
