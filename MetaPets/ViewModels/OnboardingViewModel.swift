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
        
        print("DEBUG: CRITICAL: Creating new pet: \(petName) the \(petType.rawValue)")
        
        // Use AppDataManager to create a new pet
        let newPet = AppDataManager.shared.createNewPet(name: petName, type: petType)
        
        // Verification
        print("DEBUG: CRITICAL: Verification confirms pet type is: \(newPet.type.rawValue)")
        
        // Double-check that the type is correct
        if newPet.type.rawValue != petType.rawValue {
            print("DEBUG: CRITICAL: ERROR - Pet type mismatch after saving!")
        }
    }
    
    // Mark onboarding as complete
    func completeOnboarding() {
        print("DEBUG: CRITICAL: completeOnboarding() method called")
        
        // Ensure pet is saved before completing onboarding
        if let petType = selectedPetType, !petName.isEmpty {
            print("DEBUG: CRITICAL: Creating final pet before completing onboarding")
            createPet()
            
            // Verify the pet was saved correctly
            if let savedPet = AppDataManager.shared.loadPet() {
                print("DEBUG: CRITICAL: Final verification - loaded: \(savedPet.name) the \(savedPet.type.rawValue)")
            } else {
                print("DEBUG: CRITICAL: ERROR - Failed to load pet in final verification")
            }
        } else {
            print("DEBUG: CRITICAL: ERROR - Cannot complete onboarding without pet type and name")
            return
        }
        
        // Mark onboarding as complete
        AppDataManager.shared.setOnboardingComplete(true)
        
        // Set onboardingComplete flag and notify subscribers using the main thread
        DispatchQueue.main.async {
            self.onboardingComplete = true
            print("DEBUG: CRITICAL: Onboarding completion flag set to TRUE")
        }
    }
    
    // Reset onboarding status (for testing)
    func resetOnboarding() {
        AppDataManager.shared.setOnboardingComplete(false)
        onboardingComplete = false
        selectedPetType = nil
        petName = ""
    }
}
