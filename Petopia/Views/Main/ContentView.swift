//
//  ContentView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: PetViewModel
    @State private var selectedTab = 0
    
    init() {
        let pet = PetViewModel.loadPet()
        _viewModel = StateObject(wrappedValue: PetViewModel(pet: pet))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PetView(viewModel: viewModel)
                .tabItem {
                    Label("Pet", systemImage: "pawprint.fill")
                }
                .tag(0)
            
            FoodView(viewModel: viewModel)
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }
                .tag(1)
            
            PlayTabView(viewModel: viewModel)
                .tabItem {
                    Label("Play", systemImage: "gamecontroller.fill")
                }
                .tag(2)
            
            StoreTabView(viewModel: viewModel)
                .tabItem {
                    Label("Store", systemImage: "bag.fill")
                }
                .tag(3)
        }
        .onAppear {
            // Request notification permissions
            NotificationManager.shared.requestPermissions()
        }
        .onDisappear {
            // Save pet data when app closes
            viewModel.savePet()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
