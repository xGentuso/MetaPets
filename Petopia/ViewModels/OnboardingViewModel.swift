//
//  OnboardingViewModel.swift
//  Petopia
//
//  Created for Petopia
//

import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var selectedPetType: PetType?
    @Published var petName: String = ""
    @Published var onboardingComplete: Bool = false
    
    init() {
        // Check if onboarding has already been completed
        onboardingComplete = AppDataManager.shared.hasCompletedOnboarding()
    }
    
    // Create a new pet based on user selections
    func createPet() {
        guard let petType = selectedPetType, !petName.isEmpty else {
            print("DEBUG: Cannot create pet - missing type or name")
            return
        }
        
        print("DEBUG: Creating new pet: \(petName) the \(petType.rawValue)")
        
        // Create and save the new pet
        let newPet = AppDataManager.shared.createNewPet(name: petName, type: petType)
        print("DEBUG: New pet created: \(newPet.name) the \(newPet.type.rawValue)")
        
        // Force save to ensure it persists
        if let encoded = try? JSONEncoder().encode(newPet) {
            UserDefaults.standard.set(encoded, forKey: "SavedPet")
            UserDefaults.standard.synchronize()
            
            // Double-check the save was successful
            if let savedPetData = UserDefaults.standard.data(forKey: "SavedPet"),
               let savedPet = try? JSONDecoder().decode(Pet.self, from: savedPetData) {
                print("DEBUG: Verified pet save - loaded: \(savedPet.name) the \(savedPet.type.rawValue)")
                
                // Verify the type matches
                if savedPet.type != petType {
                    print("DEBUG: ERROR - Saved pet type (\(savedPet.type)) does not match selected type (\(petType))")
                }
            } else {
                print("DEBUG: ERROR - Failed to verify pet save")
            }
        } else {
            print("DEBUG: ERROR - Failed to encode pet for saving")
        }
    }
    
    // Mark onboarding as complete
    func completeOnboarding() {
        print("DEBUG: Completing onboarding")
        
        // Ensure pet is saved before completing onboarding
        if let petType = selectedPetType, !petName.isEmpty {
            print("DEBUG: Creating final pet before completing onboarding")
            createPet()
            
            // Verify the pet was saved correctly
            if let savedPet = AppDataManager.shared.loadPet() {
                print("DEBUG: Final verification - loaded pet: \(savedPet.name) the \(savedPet.type.rawValue)")
            } else {
                print("DEBUG: ERROR - Failed to load pet in final verification")
            }
        } else {
            print("DEBUG: ERROR - Cannot complete onboarding without pet type and name")
            return
        }
        
        AppDataManager.shared.setOnboardingComplete(true)
        UserDefaults.standard.synchronize()
        onboardingComplete = true
        print("DEBUG: Onboarding completed successfully")
    }
    
    // Reset onboarding status (for testing)
    func resetOnboarding() {
        AppDataManager.shared.setOnboardingComplete(false)
        onboardingComplete = false
        selectedPetType = nil
        petName = ""
    }
}
