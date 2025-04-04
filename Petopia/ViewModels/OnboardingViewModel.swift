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
            return
        }
        
        // Use AppDataManager to create and save the pet
        _ = AppDataManager.shared.createNewPet(name: petName, type: petType)
        print("New pet created and saved: \(petName) the \(petType.rawValue)")
    }
    
    // Mark onboarding as complete
    func completeOnboarding() {
        AppDataManager.shared.setOnboardingComplete(true)
        onboardingComplete = true
    }
    
    // Reset onboarding status (for testing)
    func resetOnboarding() {
        AppDataManager.shared.setOnboardingComplete(false)
        onboardingComplete = false
        selectedPetType = nil
        petName = ""
    }
}
