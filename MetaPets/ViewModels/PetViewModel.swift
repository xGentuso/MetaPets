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
    
    // Currency-related properties
    @Published var lastDailyBonusDate: Date?
    @Published var dailyBonusStreak: Int = 0
    
    private var lastUpdateTime: Date
    private var timer: AnyCancellable?
    private var autoSaveTimer: AnyCancellable?
    
    // Mark when the ViewModel is active
    private var isActive = false
    
    // Updated method to use AppDataManager
    static func getStoredPetType() -> PetType {
        return AppDataManager.shared.getPetType()
    }
    
    // We don't need this anymore - pet type is stored with the pet
    private func savePetType() {
        // Method intentionally left empty - pet type is now
        // automatically saved when we save the Pet object
    }
    
    // Verify the pet type - no longer needed as we're using a single source of truth
    func verifyAndRefreshPetType() {
        // This method remains for backwards compatibility but does nothing
        print("Pet type verification no longer needed - using single source of truth")
    }
    
    // Private auto-save method
    private func autoSave() {
        Task { [weak self] in
            guard let self = self else { return }
            await AppDataManager.shared.saveAllData(viewModel: self)
        }
    }
    
    deinit {
        print("PetViewModel deinitializing - cleaning up timers")
        stopAllTimers()
    }
    
    // Stop all timers
    private func stopAllTimers() {
        print("Stopping all timers")
        timer?.cancel()
        timer = nil
        autoSaveTimer?.cancel()
        autoSaveTimer = nil
    }
    
    // Start all timers
    private func startAllTimers() {
        print("Starting all timers")
        
        // Only start if not already active
        if timer == nil {
            // Set up the main update timer
            timer = Timer.publish(every: 60, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updatePetWithTimeElapsed()
                }
        }
        
        // Setup auto-save timer (every 5 minutes)
        if autoSaveTimer == nil {
            autoSaveTimer = Timer.publish(every: 300, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    Task {
                        await AppDataManager.shared.saveAllData(viewModel: self)
                    }
                }
        }
    }
    
    // Public method to notify when the ViewModel's view appears
    func viewDidAppear() {
        print("PetViewModel view did appear")
        isActive = true
        startAllTimers()
    }
    
    // Public method to notify when the ViewModel's view disappears
    func viewDidDisappear() {
        print("PetViewModel view did disappear")
        isActive = false
        
        // Immediately save the current state
        autoSave()
        
        // We could stop timers here, but it would stop background updates
        // Instead, we'll keep timers running for background updates
        // stopAllTimers()
    }
    
    init(pet: Pet? = nil) {
        print("PetViewModel initializing")
        
        // Initialize lastUpdateTime first
        self.lastUpdateTime = Date()
        
        // Initialize pet before any other operations
        if let providedPet = pet {
            print("Using provided pet with type: \(providedPet.type.rawValue)")
            self.pet = providedPet
        } else if let savedPet = AppDataManager.shared.loadPet() {
            print("Loading saved pet: \(savedPet.name) the \(savedPet.type.rawValue)")
            self.pet = savedPet
        } else {
            print("Creating default pet")
            // Use our AppDataManager method to get the pet type
            let petType = PetViewModel.getStoredPetType()
            self.pet = Pet(
                name: "Buddy",
                type: petType,
                birthDate: Date()
            )
        }
        
        // Now that pet is initialized, we can perform other setup
        loadItems()
        loadCurrencyData()
        refreshMinigames()
        
        // Don't start timers here, wait until view appears
        
        // Save the pet to ensure it's properly stored
        autoSave()
        
        print("PetViewModel initialization complete with pet type: \(self.pet.type.rawValue)")
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
    
    private func loadCurrencyData() {
        // Load from AppDataManager instead of directly from UserDefaults
        let bonusData = AppDataManager.shared.loadDailyBonusData()
        lastDailyBonusDate = bonusData.0
        dailyBonusStreak = bonusData.1
    }
    
    private func updatePetWithTimeElapsed() {
        let currentTime = Date()
        let timeInterval = currentTime.timeIntervalSince(lastUpdateTime)
        
        pet.updateWithTimeElapsed(timeInterval)
        lastUpdateTime = currentTime
        
        // Check if notifications should be sent
        checkForNotifications()
        
        // Auto-save after stats update
        autoSave()
    }
    
    private func checkForNotifications() {
        // Send notifications if stats are low
        if pet.hunger < 20 {
            NotificationManager.shared.schedulePetNeedNotification(
                for: .hunger,
                timeInterval: 1
            )
        }
        
        if pet.health < 30 {
            NotificationManager.shared.schedulePetNeedNotification(
                for: .health,
                timeInterval: 1
            )
        }
        
        if pet.cleanliness < 20 {
            NotificationManager.shared.schedulePetNeedNotification(
                for: .cleanliness,
                timeInterval: 1
            )
        }
        
        // Check for overall pet state and schedule appropriate notifications
        NotificationManager.shared.scheduleNotificationsBasedOnPetState(pet: pet)
    }
    
    // Achievement tracking methods
    private func trackAchievements() {
        // Check for perfect pet achievement
        if pet.hunger >= 90 && pet.happiness >= 90 && pet.health >= 90 &&
           pet.cleanliness >= 90 && pet.energy >= 90 {
            AchievementManager.shared.trackPerfectStatus()
        }
        
        // Track level achievements
        AchievementManager.shared.trackLevelUp(newLevel: pet.level)
        
        // Track evolution achievement when the stage changes
        AchievementManager.shared.trackEvolution(stage: pet.stage)
    }
    
    // Method to update the pet with a new pet
    func updateWithNewPet(_ newPet: Pet) {
        print("Updating pet from \(pet.type.rawValue) to \(newPet.type.rawValue)")
        
        // Clear existing state and cancel all timers
        timer?.cancel()
        autoSaveTimer?.cancel()
        
        // Replace the pet
        self.pet = newPet
        
        // Save the pet type to our single source of truth
        savePetType()
        
        // Reset time tracking
        self.lastUpdateTime = Date()
        
        // Refresh minigames for the new pet type
        refreshMinigames()
        
        // Restart timer
        setupTimers()
        
        // Force UI refresh
        objectWillChange.send()
        
        // Save the updated pet to ensure it's persisted
        Task { [weak self] in
            guard let self = self else { return }
            await AppDataManager.shared.saveAllData(viewModel: self)
        }
        
        print("PetViewModel updated with new pet: \(newPet.name) the \(newPet.type.rawValue)")
    }
    
    // Currency methods
    func earnCurrency(amount: Int, description: String) {
        CurrencyManager.shared.addCurrency(to: &pet, amount: amount, description: description)
        
        // Track currency earned achievement
        AchievementManager.shared.trackCurrencyEarned(amount: amount)
        
        autoSave() // Save after earning currency
    }
    
    func spendCurrency(amount: Int, description: String) -> Bool {
        let result = CurrencyManager.shared.spendCurrency(from: &pet, amount: amount, description: description)
        if result {
            autoSave() // Save after successful currency spend
        }
        return result
    }
    
    func claimDailyBonus() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if already claimed today
        if let lastDate = lastDailyBonusDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return 0
        }
        
        // Check if streak should continue or reset
        if let lastDate = lastDailyBonusDate,
           let dayDifference = Calendar.current.dateComponents([.day],
                                                            from: Calendar.current.startOfDay(for: lastDate),
                                                            to: today).day,
           dayDifference == 1 {
            // Continue streak
            dailyBonusStreak += 1
        } else {
            // Reset streak
            dailyBonusStreak = 1
        }
        
        // Update last claim date
        lastDailyBonusDate = today
        
        // Track streak achievements
        AchievementManager.shared.trackDailyStreak(streak: dailyBonusStreak)
        
        // Get bonus amount and add currency
        let bonusAmount = CurrencyManager.shared.getDailyBonusAmount(streak: dailyBonusStreak)
        earnCurrency(amount: bonusAmount, description: "Daily login bonus (Day \(dailyBonusStreak))")
        
        // Save after claiming bonus
        autoSave()
        
        return bonusAmount
    }
    
    func getTransactionHistory() -> [CurrencyTransaction] {
        return CurrencyManager.shared.transactions
    }
    
    // Minigame properties and methods
    var availableMinigames: [Minigame] {
        return MinigameManager.shared.availableMinigames
    }
    
    func refreshMinigames() {
        MinigameManager.shared.refreshMinigames(petType: pet.type)
    }
    
    func canPlayMinigame(_ minigame: Minigame) -> Bool {
        return MinigameManager.shared.canPlay(minigame: minigame)
    }
    
    func timeUntilMinigameAvailable(_ minigame: Minigame) -> TimeInterval {
        return MinigameManager.shared.timeUntilAvailable(minigame: minigame)
    }
    
    func recordMinigamePlayed(_ minigame: Minigame) {
        MinigameManager.shared.recordGamePlayed(minigame: minigame)
        
        // Track minigame played achievement
        AchievementManager.shared.trackMinigamePlayed()
        
        autoSave() // Save after recording minigame play
    }
    
    func awardMinigameReward(minigame: Minigame, score: Int, maxScore: Int) {
        // Calculate reward based on score and difficulty
        let percentage = min(1.0, Double(score) / Double(maxScore))
        let baseReward = minigame.possibleReward
        let earnedReward = Int(Double(baseReward) * percentage)
        
        if earnedReward > 0 {
            earnCurrency(amount: earnedReward, description: "Played \(minigame.name) minigame")
            
            // Also increase pet happiness
            let happinessBoost = min(100 - pet.happiness, 10.0 * percentage)
            pet.happiness += happinessBoost
            
            // Save after awarding reward
            autoSave()
        }
    }
    
    // Daily activity methods
    func completeDailyActivity(activityId: UUID) -> Int? {
        if let reward = DailiesManager.shared.completeActivity(id: activityId) {
            // Add currency
            earnCurrency(amount: reward, description: "Completed daily activity")
            
            // Also boost pet happiness a little
            let happinessBoost = min(100 - pet.happiness, 5.0)
            pet.happiness += happinessBoost
            
            // Track daily activity achievement
            AchievementManager.shared.trackDailyActivity()
            
            // Auto-save after completing a daily activity
            autoSave()
            
            return reward
        }
        return nil
    }
    
    func getAvailableDailyActivities() -> [DailyActivity] {
        return DailiesManager.shared.getAvailableActivities()
    }
    
    func getAllDailyActivities() -> [DailyActivity] {
        return DailiesManager.shared.dailyActivities
    }
    
    // Method to ensure consistency in data saving
    private func updatePetStateAndSave(action: () -> Void) {
        // Execute the action that modifies pet state
        action()
        
        // Save the updated state
        autoSave()
        
        // Track relevant achievements
        trackAchievements()
    }
    
    // Actions with currency rewards
    func feed(food: Food) {
        updatePetStateAndSave {
            pet.feed(food: food)
            
            // Earn some currency for feeding
            earnCurrency(amount: 5, description: "Fed pet with \(food.name)")
            
            // Track feeding achievement
            AchievementManager.shared.trackFeeding()
        }
    }
    
    func play(game: Game) {
        updatePetStateAndSave {
            pet.play(game: game)
            
            // Earn some currency for playing
            earnCurrency(amount: 8, description: "Played \(game.name) with pet")
        }
    }
    
    func clean() {
        updatePetStateAndSave {
            pet.clean()
            
            // Earn some currency for cleaning
            earnCurrency(amount: 5, description: "Cleaned pet")
            
            // Track cleaning achievement
            AchievementManager.shared.trackCleaning()
        }
    }
    
    func sleep(hours: Int) {
        updatePetStateAndSave {
            pet.sleep(hours: hours)
            
            // Earn some currency for sleep care
            earnCurrency(amount: 3 * hours, description: "Let pet sleep for \(hours) hours")
            
            // Track sleep achievement
            AchievementManager.shared.trackSleeping(hours: hours)
        }
    }
    
    func heal(medicine: Medicine) {
        updatePetStateAndSave {
            pet.heal(medicine: medicine)
            
            // Earn some currency for health care
            earnCurrency(amount: 10, description: "Healed pet with \(medicine.name)")
            
            // Track medicine achievement
            AchievementManager.shared.trackHealing()
        }
    }
    
    // Purchase methods
    func buyFood(food: Food) -> Bool {
        if spendCurrency(amount: food.price, description: "Purchased \(food.name)") {
            // Add logic for adding to inventory if needed
            autoSave() // Save after purchase
            return true
        }
        return false
    }
    
    func buyMedicine(medicine: Medicine) -> Bool {
        if spendCurrency(amount: medicine.price, description: "Purchased \(medicine.name)") {
            // Add logic for adding to inventory if needed
            autoSave() // Save after purchase
            return true
        }
        return false
    }
    
    func buyAccessory(accessory: Accessory) -> Bool {
        if spendCurrency(amount: accessory.price, description: "Purchased \(accessory.name)") {
            addAccessory(accessory)
            
            // Track accessory collection achievement
            AchievementManager.shared.trackAccessoryCollected()
            
            autoSave() // Save after purchase
            return true
        }
        return false
    }
    
    // Other methods
    func rename(newName: String) {
        pet.name = newName
        autoSave() // Save after renaming
    }
    
    func addAccessory(_ accessory: Accessory) {
        // Check if an accessory in this position already exists
        if let index = pet.accessories.firstIndex(where: { $0.position == accessory.position }) {
            pet.accessories.remove(at: index)
        }
        
        pet.accessories.append(accessory)
        autoSave() // Save after adding accessory
    }
    
    func removeAccessory(at position: Accessory.AccessoryPosition) {
        pet.accessories.removeAll { $0.position == position }
        autoSave() // Save after removing accessory
    }
    
    // Reset the view model state with a new pet
    func resetStateWith(newPet: Pet) {
        print("DEBUG: CRITICAL: Resetting view model with new pet: \(newPet.name) the \(newPet.type.rawValue)")
        
        // Cancel any existing timers
        timer?.cancel()
        
        // Update the pet
        self.pet = newPet
        
        // Reset time tracking
        self.lastUpdateTime = Date()
        
        // Reset all stats to initial values
        self.pet.happiness = 100
        self.pet.hunger = 100
        self.pet.energy = 100
        self.pet.cleanliness = 100
        self.pet.health = 100
        
        // Reload all items and data
        loadItems()
        loadCurrencyData()
        
        // Restart timer
        setupTimers()
        
        // Save the updated state
        Task {
            await AppDataManager.shared.saveAllData(viewModel: self)
        }
        UserDefaults.standard.synchronize()
        
        print("DEBUG: CRITICAL: View model reset complete with pet type: \(newPet.type.rawValue)")
    }
    
    // Method to clear all app data
    func clearAllData() {
        // Clear all UserDefaults data
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Reset the pet to default state
        self.pet = Pet(
            name: "",
            type: .cat,
            birthDate: Date()
        )
        
        // Reset all other properties
        self.lastUpdateTime = Date()
        self.lastDailyBonusDate = nil
        self.dailyBonusStreak = 0
        
        // Reload items
        loadItems()
        
        print("DEBUG: All app data has been cleared")
    }
    
    // Force refresh to ensure pet type is correctly applied
    func forceRefresh() {
        print("DEBUG: CRITICAL: Refreshing pet view model")
        
        // Get the correct pet type from AppDataManager
        let storedType = AppDataManager.shared.getPetType()
        if pet.type != storedType {
            print("DEBUG: CRITICAL: Updating pet type from \(pet.type.rawValue) to \(storedType.rawValue)")
            pet.type = storedType
            
            // Simple notification of change
            objectWillChange.send()
        }
    }
    
    // Replace the duplicate timer setup with a single unified method
    private func setupTimers() {
        // This is now a deprecated method, using startAllTimers() instead
        startAllTimers()
    }
}
