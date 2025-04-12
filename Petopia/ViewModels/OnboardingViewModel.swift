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
        // Also clear the separate pet type record
        UserDefaults.standard.removeObject(forKey: "SelectedPetType")
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
        do {
            let encoded = try JSONEncoder().encode(newPet)
            UserDefaults.standard.set(encoded, forKey: "SavedPet")
            UserDefaults.standard.synchronize()
            
            // Force verification
            if let data = UserDefaults.standard.data(forKey: "SavedPet"),
               let pet = try? JSONDecoder().decode(Pet.self, from: data) {
                print("DEBUG: CRITICAL: Verification confirms pet type is: \(pet.type.rawValue)")
                
                // Double-check that the type is correct
                if pet.type.rawValue != petType.rawValue {
                    print("DEBUG: CRITICAL: ERROR - Pet type mismatch after saving!")
                }
            }
        } catch {
            print("DEBUG: CRITICAL: Error saving pet: \(error)")
        }
        
        // Also store the pet type separately for redundancy
        UserDefaults.standard.set(petType.rawValue, forKey: "SelectedPetType")
        UserDefaults.standard.synchronize()
        
        // Final verification of stored pet type
        if let storedTypeString = UserDefaults.standard.string(forKey: "SelectedPetType") {
            print("DEBUG: CRITICAL: Verified stored pet type: \(storedTypeString)")
        } else {
            print("DEBUG: CRITICAL: ERROR - Failed to store pet type separately!")
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
        UserDefaults.standard.synchronize()
        
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
