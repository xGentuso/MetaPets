
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
    @State private var showLaunchScreen = true
    
    init() {
        // Initialize with saved pet data or create a new pet
        let pet = AppDataManager.shared.loadPet()
        _viewModel = StateObject(wrappedValue: PetViewModel(pet: pet))
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(viewModel: viewModel)
                    .opacity(showLaunchScreen ? 0 : 1)
                
                if showLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.3), value: showLaunchScreen)
                }
            }
            .onAppear {
                // Simulate a delay for the launch screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showLaunchScreen = false
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Save data when app goes to background or becomes inactive
                AppDataManager.shared.saveAllData(viewModel: viewModel)
                print("App state changed to \(newPhase) - Saving data")
            }
        }
    }
}
