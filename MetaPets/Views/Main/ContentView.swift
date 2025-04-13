//
//  ContentView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var petViewModel: PetViewModel
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            TabView {
                PetView(viewModel: petViewModel)
                    .tabItem {
                        Label("Pet", systemImage: "pawprint.fill")
                    }
                
                FoodView(viewModel: petViewModel)
                    .tabItem {
                        Label("Food", systemImage: "fork.knife")
                    }
                
                PlayTabView(viewModel: petViewModel)
                    .tabItem {
                        Label("Play", systemImage: "gamecontroller.fill")
                    }
                
                DailiesView(viewModel: petViewModel)
                    .tabItem {
                        Label("Dailies", systemImage: "calendar.badge.clock")
                    }
                
                AchievementsView(viewModel: petViewModel)
                    .tabItem {
                        Label("Achievements", systemImage: "trophy.fill")
                    }
                
                StoreTabView(viewModel: petViewModel)
                    .tabItem {
                        Label("Store", systemImage: "bag.fill")
                    }
            }
            .padding(.bottom, 4)
            .accentColor(.blue)
            .navigationBarItems(leading:
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                .padding(.leading, 12)
                .padding(.top, 4)
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: petViewModel)
        }
        .task {
            // Request notification permissions
            await NotificationManager.shared.requestPermissions()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PetViewModel())
    }
}
