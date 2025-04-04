//
//  ContentView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var selectedTab = 0
    @State private var saveTimer: Timer?
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                PetView(viewModel: viewModel)
                    .navigationBarItems(trailing:
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    )
            }
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
            
            DailiesView(viewModel: viewModel)
                .tabItem {
                    Label("Dailies", systemImage: "calendar.badge.clock")
                }
                .tag(3)
            
            AchievementsView(viewModel: viewModel)
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }
                .tag(4)
            
            StoreTabView(viewModel: viewModel)
                .tabItem {
                    Label("Store", systemImage: "bag.fill")
                }
                .tag(5)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onAppear {
            // Request notification permissions
            NotificationManager.shared.requestPermissions()
            
            // Create auto-save timer (every 30 seconds)
            saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                AppDataManager.shared.saveAllData(viewModel: viewModel)
                print("Auto-save triggered")
            }
        }
        .onDisappear {
            // Cancel the timer when the view disappears
            saveTimer?.invalidate()
            
            // Final save when view disappears
            AppDataManager.shared.saveAllData(viewModel: viewModel)
            print("ContentView disappeared - Saving data")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let previewViewModel = PetViewModel()
        ContentView(viewModel: previewViewModel)
    }
}
