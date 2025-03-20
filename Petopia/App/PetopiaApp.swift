//
//  PetopiaApp.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

@main
struct Petopia: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: PetViewModel
    
    init() {
        // Initialize with saved pet data or create a new pet
        let pet = AppDataManager.shared.loadPet()
        _viewModel = StateObject(wrappedValue: PetViewModel(pet: pet))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Save data when app goes to background or becomes inactive
                AppDataManager.shared.saveAllData(viewModel: viewModel)
                print("App state changed to \(newPhase) - Saving data")
            }
        }
    }
}
