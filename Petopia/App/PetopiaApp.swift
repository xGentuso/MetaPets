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
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var showLaunchScreen = true
    @State private var showingBackupRestoreAlert = false
    @State private var backupMessage = ""
    @State private var isBackupSuccess = true
    @State private var appRefreshID = UUID() // Add state for forcing app refresh
    
    init() {
        // For testing - Clear all data and force onboarding in debug mode
        #if DEBUG
        // Clear all UserDefaults data
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        AppDataManager.shared.clearAllData()
        AppDataManager.shared.setOnboardingComplete(false)
        UserDefaults.standard.synchronize()
        print("DEBUG: Cleared all data and reset onboarding")
        #endif
        
        // Perform any necessary data migrations
        DataMigrationHelper.shared.performMigrationsIfNeeded()
        
        // Initialize with saved pet data or wait for onboarding
        if AppDataManager.shared.hasCompletedOnboarding(),
           let pet = AppDataManager.shared.loadPet() {
            print("DEBUG: Loading existing pet for completed onboarding")
            _viewModel = StateObject(wrappedValue: PetViewModel(pet: pet))
        } else {
            print("DEBUG: Creating temporary pet for onboarding")
            // Create a temporary pet that will be replaced after onboarding
            _viewModel = StateObject(wrappedValue: PetViewModel())
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                #if DEBUG
                // Debug logging
                let _ = print("DEBUG: Onboarding complete? \(onboardingViewModel.onboardingComplete)")
                let _ = print("DEBUG: AppDataManager onboarding status: \(AppDataManager.shared.hasCompletedOnboarding())")
                #endif
                
                if AppDataManager.shared.hasCompletedOnboarding() {
                    // Regular app flow
                    ContentView(viewModel: viewModel)
                        .opacity(showLaunchScreen ? 0 : 1)
                        .environment(\.openURL, OpenURLAction { url in
                            // Handle backup file opening for restores
                            if url.pathExtension == "json" {
                                handleBackupFileOpen(url)
                                return .handled
                            }
                            return .systemAction
                        })
                        // Force view refresh with ID
                        .id("main-view-\(appRefreshID)")
                } else {
                    // Onboarding flow
                    OnboardingView(viewModel: onboardingViewModel)
                        .opacity(showLaunchScreen ? 0 : 1)
                        .onChange(of: onboardingViewModel.onboardingComplete) { _, completed in
                            if completed {
                                print("DEBUG: CRITICAL: ************* ONBOARDING COMPLETED *************")
                                
                                // Ensure we're really marking onboarding as complete
                                AppDataManager.shared.setOnboardingComplete(true)
                                UserDefaults.standard.synchronize()
                                
                                // Force a reload of the saved pet data
                                if let newPet = AppDataManager.shared.loadPet() {
                                    print("DEBUG: CRITICAL: Loaded new pet: \(newPet.name) the \(newPet.type.rawValue)")
                                    
                                    // Completely replace the pet type directly in UserDefaults
                                    UserDefaults.standard.removeObject(forKey: "SavedPet")
                                    UserDefaults.standard.synchronize()
                                    
                                    // Re-save the pet with forced type
                                    do {
                                        let encoder = JSONEncoder()
                                        let petData = try encoder.encode(newPet)
                                        UserDefaults.standard.set(petData, forKey: "SavedPet")
                                        UserDefaults.standard.set(newPet.type.rawValue, forKey: "SelectedPetType")
                                        UserDefaults.standard.synchronize()
                                        print("DEBUG: CRITICAL: Re-saved pet with enforced type: \(newPet.type.rawValue)")
                                    } catch {
                                        print("DEBUG: CRITICAL: Error encoding pet: \(error)")
                                    }
                                    
                                    // Create a new view model with the loaded pet
                                    let newViewModel = PetViewModel(pet: newPet)
                                    viewModel.updateWithNewPet(newPet)
                                    
                                    // Force a view refresh by updating refresh ID
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        print("DEBUG: CRITICAL: ************* REFRESHING APP VIEWS *************")
                                        appRefreshID = UUID()
                                    }
                                } else {
                                    print("DEBUG: CRITICAL: Failed to load new pet after onboarding")
                                }
                            }
                        }
                }
                
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
            .alert(isPresented: $showingBackupRestoreAlert) {
                Alert(
                    title: Text(isBackupSuccess ? "Success" : "Error"),
                    message: Text(backupMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Save data when app goes to background or becomes inactive
                AppDataManager.shared.saveAllData(viewModel: viewModel)
                print("App state changed to \(newPhase) - Saving data")
                
                // Create auto-backup on background
                if newPhase == .background {
                    createAutoBackup()
                }
            }
        }
    }
    
    // Create an automatic backup when app goes to background
    private func createAutoBackup() {
        #if DEBUG
        print("Skipping auto-backup in debug mode")
        #else
        // In production, create a backup file in app's documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let backupURL = documentsDirectory.appendingPathComponent("petopia_autobackup.json")
            
            if let data = AppDataManager.shared.exportData() {
                do {
                    try data.write(to: backupURL)
                    print("Auto-backup created successfully")
                } catch {
                    print("Failed to create auto-backup: \(error)")
                }
            }
        }
        #endif
    }
    
    // Handle backup file opening (for restore)
    private func handleBackupFileOpen(_ url: URL) {
        let success = DataMigrationHelper.shared.restoreFromBackup(fileURL: url)
        
        backupMessage = success ?
            "Your pet data has been successfully restored. The app will now restart." :
            "There was a problem restoring the backup. Please try again with a different file."
        
        isBackupSuccess = success
        showingBackupRestoreAlert = true
        
        if success {
            // Restart the app after successful restore
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                exit(0) // Force restart to load new data
            }
        }
    }
}
