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
        
        // Load currency data
        loadCurrencyData()
        
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
    
    private func loadCurrencyData() {
        if let savedDate = UserDefaults.standard.object(forKey: "LastDailyBonusDate") as? Date {
            lastDailyBonusDate = savedDate
        }
        
        dailyBonusStreak = UserDefaults.standard.integer(forKey: "DailyBonusStreak")
    }
    
    private func saveCurrencyData() {
        if let lastDate = lastDailyBonusDate {
            UserDefaults.standard.set(lastDate, forKey: "LastDailyBonusDate")
        }
        
        UserDefaults.standard.set(dailyBonusStreak, forKey: "DailyBonusStreak")
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
    
    // Currency methods
    func earnCurrency(amount: Int, description: String) {
        CurrencyManager.shared.addCurrency(to: &pet, amount: amount, description: description)
    }
    
    func spendCurrency(amount: Int, description: String) -> Bool {
        return CurrencyManager.shared.spendCurrency(from: &pet, amount: amount, description: description)
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
        
        // Save streak data
        saveCurrencyData()
        
        // Get bonus amount and add currency
        let bonusAmount = CurrencyManager.shared.getDailyBonusAmount(streak: dailyBonusStreak)
        earnCurrency(amount: bonusAmount, description: "Daily login bonus (Day \(dailyBonusStreak))")
        
        return bonusAmount
    }
    
    func getTransactionHistory() -> [CurrencyTransaction] {
        return CurrencyManager.shared.transactions
    }
    
    // Minigame properties and methods
    var availableMinigames: [Minigame] {
        return MinigameManager.shared.availableMinigames
    }
    
    func canPlayMinigame(_ minigame: Minigame) -> Bool {
        return MinigameManager.shared.canPlay(minigame: minigame)
    }
    
    func timeUntilMinigameAvailable(_ minigame: Minigame) -> TimeInterval {
        return MinigameManager.shared.timeUntilAvailable(minigame: minigame)
    }
    
    func recordMinigamePlayed(_ minigame: Minigame) {
        MinigameManager.shared.recordGamePlayed(minigame: minigame)
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
        }
    }
    
    // Actions with currency rewards
    func feed(food: Food) {
        pet.feed(food: food)
        
        // Earn some currency for feeding
        earnCurrency(amount: 5, description: "Fed pet with \(food.name)")
    }
    
    func play(game: Game) {
        pet.play(game: game)
        
        // Earn some currency for playing
        earnCurrency(amount: 8, description: "Played \(game.name) with pet")
    }
    
    func clean() {
        pet.clean()
        
        // Earn some currency for cleaning
        earnCurrency(amount: 6, description: "Cleaned pet")
    }
    
    func heal(medicine: Medicine) {
        pet.heal(medicine: medicine)
        
        // Earn some currency for healing (only if pet was sick)
        if pet.health < 50 {
            earnCurrency(amount: 10, description: "Healed pet when sick")
        }
    }
    
    func sleep(hours: Int) {
        pet.sleep(hours: hours)
        
        // Earn some currency for proper rest
        earnCurrency(amount: hours * 2, description: "Pet slept for \(hours) hours")
    }
    
    // Purchase methods
    func buyFood(food: Food) -> Bool {
        if spendCurrency(amount: food.price, description: "Purchased \(food.name)") {
            // Add logic for adding to inventory if needed
            return true
        }
        return false
    }
    
    func buyMedicine(medicine: Medicine) -> Bool {
        if spendCurrency(amount: medicine.price, description: "Purchased \(medicine.name)") {
            // Add logic for adding to inventory if needed
            return true
        }
        return false
    }
    
    func buyAccessory(accessory: Accessory) -> Bool {
        if spendCurrency(amount: accessory.price, description: "Purchased \(accessory.name)") {
            addAccessory(accessory)
            return true
        }
        return false
    }
    
    // Original methods
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
