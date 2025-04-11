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
        
        // First, clear any existing pet data
        UserDefaults.standard.removeObject(forKey: "SavedPet")
        UserDefaults.standard.synchronize()
        
        // Create a completely fresh pet with the specified type
        let newPet = Pet(
            id: UUID(),
            name: petName,
            type: petType,
            birthDate: Date(),
            stage: .baby,
            hunger: 70,
            happiness: 70,
            health: 100,
            cleanliness: 70,
            energy: 70,
            currency: 50,
            experience: 0,
            level: 1,
            accessories: []
        )
        
        // Save directly to UserDefaults
        if let encoded = try? JSONEncoder().encode(newPet) {
            UserDefaults.standard.set(encoded, forKey: "SavedPet")
            UserDefaults.standard.synchronize()
            
            // Force verification
            if let data = UserDefaults.standard.data(forKey: "SavedPet"),
               let pet = try? JSONDecoder().decode(Pet.self, from: data) {
                print("DEBUG: CRITICAL: Verification confirms pet type is: \(pet.type.rawValue)")
            }
        }
        
        // Also store the pet type separately for redundancy
        UserDefaults.standard.set(petType.rawValue, forKey: "SelectedPetType")
        UserDefaults.standard.synchronize()
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
                print("DEBUG: Final verification - loaded: \(savedPet.name) the \(savedPet.type.rawValue)")
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
