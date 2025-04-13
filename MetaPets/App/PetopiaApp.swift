//
//  PetopiaApp.swift
//  Meta Pets
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

@main
struct MetaPets: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: PetViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showLaunchScreen = true
    @State private var showingBackupRestoreAlert = false
    @State private var backupMessage = ""
    @State private var isBackupSuccess = true
    @State private var appRefreshID = UUID() // Add state for forcing app refresh
    
    // Add a state to track the current app flow
    @State private var appState: AppState = .initializing
    
    enum AppState {
        case initializing
        case login
        case onboarding
        case mainApp
    }
    
    init() {
        // For testing - Clear all data and force onboarding in debug mode
        #if DEBUG
        // Commenting out data clearing for normal development
        /*
        // Clear all UserDefaults data
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        AppDataManager.shared.clearAllData()
        AppDataManager.shared.setOnboardingComplete(false)
        UserDefaults.standard.synchronize()
        print("DEBUG: Cleared all data and reset onboarding")
        */
        // Add debug flag for data clearing if needed
        let shouldClearDataInDebug = false // Set to true when you want to reset app state

        if shouldClearDataInDebug {
            // Clear all UserDefaults data
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            AppDataManager.shared.clearAllData()
            AppDataManager.shared.setOnboardingComplete(false)
            print("DEBUG: Cleared all data and reset onboarding")
        }
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
                let _ = print("DEBUG: Current app state: \(appState)")
                #endif
                
                // Use appState to determine what to show instead of nested conditionals
                Group {
                    if appState == .login {
                        // Show login/signup view
                        LoginView()
                            .opacity(showLaunchScreen ? 0 : 1)
                            .environmentObject(authManager)
                            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                                if isAuthenticated {
                                    DispatchQueue.main.async {
                                        // Determine next screen based on onboarding status
                                        if AppDataManager.shared.hasCompletedOnboarding() {
                                            appState = .mainApp
                                        } else {
                                            appState = .onboarding
                                        }
                                    }
                                }
                            }
                    } else if appState == .onboarding {
                        // Onboarding flow
                        OnboardingView(viewModel: onboardingViewModel)
                            .opacity(showLaunchScreen ? 0 : 1)
                            .onChange(of: onboardingViewModel.onboardingComplete) { _, completed in
                                print("DEBUG: CRITICAL: OnboardingView detected onboardingComplete change to: \(completed)")
                                if completed {
                                    // Handle completion with a slight delay to ensure views are updated properly
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        handleOnboardingCompletion()
                                    }
                                }
                            }
                            // Add an additional timer check in case the onChange doesn't fire
                            .onAppear {
                                // Start a timer that checks onboardingComplete status regularly
                                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                                    if onboardingViewModel.onboardingComplete {
                                        print("DEBUG: CRITICAL: Timer detected onboardingComplete = true")
                                        timer.invalidate()
                                        handleOnboardingCompletion()
                                    }
                                }
                            }
                    } else if appState == .mainApp {
                        // Regular app flow
                        ContentView()
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
                            .environmentObject(authManager)
                            .environmentObject(viewModel)
                    } else {
                        // Initializing state - just show a blank view while determining state
                        Color.clear
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
                    
                    // Determine initial app state after launch screen
                    DispatchQueue.main.async {
                        determineInitialAppState()
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
                Task {
                    await AppDataManager.shared.saveAllData(viewModel: viewModel)
                    print("App state changed to \(newPhase) - Saving data")
                    
                    // Create auto-backup on background
                    if newPhase == .background {
                        createAutoBackup()
                    }
                }
            }
        }
    }
    
    // Helper function to determine initial app state
    private func determineInitialAppState() {
        // Check if user is authenticated (respects Remember Me setting via AuthenticationManager)
        if !authManager.isAuthenticated {
            appState = .login
            print("DEBUG: User not authenticated, showing login")
        } else if !AppDataManager.shared.hasCompletedOnboarding() {
            appState = .onboarding
            print("DEBUG: User authenticated but onboarding not complete")
        } else {
            appState = .mainApp
            print("DEBUG: User authenticated and onboarding complete, showing main app")
        }
        print("DEBUG: Initial app state set to: \(appState)")
    }
    
    // Handle onboarding completion - moved to a separate function
    private func handleOnboardingCompletion() {
        print("Onboarding completed - handling completion")
        
        // Ensure we're marking onboarding as complete
        AppDataManager.shared.setOnboardingComplete(true)
        
        // Force a reload of the saved pet data
        if let newPet = AppDataManager.shared.loadPet() {
            print("Loaded new pet: \(newPet.name) the \(newPet.type.rawValue)")
            
            // Replace the existing viewModel with the new one
            viewModel.updateWithNewPet(newPet)
            
            // Transition to main app view after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("Transitioning to main app")
                // Set app state to mainApp, which will trigger a full view hierarchy change
                self.appState = .mainApp
                
                // Also refresh view ID to force a complete rebuild
                self.appRefreshID = UUID()
            }
        } else {
            print("Failed to load pet after onboarding - Emergency fallback")
            
            // EMERGENCY FALLBACK: Try to create a default pet if loading fails
            let defaultPet = Pet(name: onboardingViewModel.petName, 
                               type: onboardingViewModel.selectedPetType ?? .cat,
                               birthDate: Date())
            
            viewModel.updateWithNewPet(defaultPet)
            
            // Still transition to main app even if pet loading failed
            DispatchQueue.main.async {
                self.appState = .mainApp
                self.appRefreshID = UUID()
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
            let backupURL = documentsDirectory.appendingPathComponent("metapets_autobackup.json")
            
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
