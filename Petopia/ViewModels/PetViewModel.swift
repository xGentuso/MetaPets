//
//  PetViewModel.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI
import Combine

class PetViewModel: ObservableObject {
    @Published var pet: Pet
    @Published var availableFood: [Food] = []
    @Published var availableGames: [Game] = []
    @Published var availableMedicine: [Medicine] = []
    @Published var availableAccessories: [Accessory] = []
    
    private var lastUpdateTime: Date
    private var timer: AnyCancellable?
    
    init(pet: Pet? = nil) {
        if let pet = pet {
            self.pet = pet
        } else {
            // Create default pet
            self.pet = Pet(
                name: "Buddy",
                type: .cat,
                birthDate: Date()
            )
        }
        
        self.lastUpdateTime = Date()
        
        // Load items
        loadItems()
        
        // Setup timer to update pet stats periodically
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePetWithTimeElapsed()
            }
    }
    
    deinit {
        timer?.cancel()
    }
    
    private func loadItems() {
        // In a real app, you would load these from a data source
        availableFood = [
            Food(name: "Basic Kibble", nutritionValue: 20, healthValue: 5, messValue: 5, price: 10, imageName: "food_kibble"),
            Food(name: "Premium Meal", nutritionValue: 40, healthValue: 15, messValue: 10, price: 30, imageName: "food_premium"),
            Food(name: "Treat", nutritionValue: 10, healthValue: 0, messValue: 2, price: 5, imageName: "food_treat")
        ]
        
        availableGames = [
            Game(name: "Ball", funValue: 20, energyCost: 15, messValue: 5, imageName: "game_ball"),
            Game(name: "Puzzle", funValue: 30, energyCost: 10, messValue: 0, imageName: "game_puzzle"),
            Game(name: "Frisbee", funValue: 40, energyCost: 25, messValue: 10, imageName: "game_frisbee")
        ]
        
        availableMedicine = [
            Medicine(name: "Basic Medicine", healthValue: 30, bitternessValue: 15, price: 20, imageName: "medicine_basic"),
            Medicine(name: "Advanced Cure", healthValue: 70, bitternessValue: 25, price: 50, imageName: "medicine_advanced")
        ]
        
        availableAccessories = [
            Accessory(name: "Hat", position: .head, unlockLevel: 2, price: 50, imageName: "accessory_hat"),
            Accessory(name: "Bow Tie", position: .neck, unlockLevel: 3, price: 75, imageName: "accessory_bowtie"),
            Accessory(name: "Sweater", position: .body, unlockLevel: 5, price: 100, imageName: "accessory_sweater")
        ]
    }
    
    private func updatePetWithTimeElapsed() {
        let currentTime = Date()
        let timeInterval = currentTime.timeIntervalSince(lastUpdateTime)
        
        pet.updateWithTimeElapsed(timeInterval)
        lastUpdateTime = currentTime
        
        // Check if notifications should be sent
        checkForNotifications()
    }
    
    private func checkForNotifications() {
        // Send notifications if stats are low
        if pet.hunger < 20 {
            NotificationManager.shared.sendNotification(
                title: "\(pet.name) is hungry!",
                body: "Your pet needs food soon."
            )
        }
        
        if pet.health < 30 {
            NotificationManager.shared.sendNotification(
                title: "\(pet.name) is sick!",
                body: "Your pet needs medicine."
            )
        }
        
        if pet.cleanliness < 20 {
            NotificationManager.shared.sendNotification(
                title: "\(pet.name) needs a bath!",
                body: "Your pet is getting dirty."
            )
        }
    }
    
    // Actions
    func feed(food: Food) {
        pet.feed(food: food)
    }
    
    func play(game: Game) {
        pet.play(game: game)
    }
    
    func clean() {
        pet.clean()
    }
    
    func heal(medicine: Medicine) {
        pet.heal(medicine: medicine)
    }
    
    func sleep(hours: Int) {
        pet.sleep(hours: hours)
    }
    
    func rename(newName: String) {
        pet.name = newName
    }
    
    func addAccessory(_ accessory: Accessory) {
        // Check if an accessory in this position already exists
        if let index = pet.accessories.firstIndex(where: { $0.position == accessory.position }) {
            pet.accessories.remove(at: index)
        }
        
        pet.accessories.append(accessory)
    }
    
    func removeAccessory(at position: Accessory.AccessoryPosition) {
        pet.accessories.removeAll { $0.position == position }
    }
    
    // Save and load pet data
    func savePet() {
        if let encoded = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(encoded, forKey: "SavedPet")
        }
    }
    
    static func loadPet() -> Pet? {
        if let savedPetData = UserDefaults.standard.data(forKey: "SavedPet"),
           let pet = try? JSONDecoder().decode(Pet.self, from: savedPetData) {
            return pet
        }
        return nil
    }
}
