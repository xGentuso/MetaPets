import SwiftUI

struct TipsView: View {
    @ObservedObject var viewModel: PetViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var currentTipIndex = 0
    
    // Tips organized by category
    let tipCategories = [
        "Basics": [
            "Feed your pet regularly to keep its hunger level high",
            "Clean your pet when its cleanliness drops below 50%",
            "Let your pet sleep to restore energy",
            "Play with your pet to increase happiness"
        ],
        "Growth": [
            "Your pet will evolve at levels 5, 10, and 15",
            "Different pet types have unique traits and preferences",
            "Balanced care leads to healthier and happier pets",
            "Check your pet's age on the main screen"
        ],
        "Economy": [
            "Complete daily activities to earn extra coins",
            "Log in daily to increase your bonus streak",
            "Play minigames to earn additional currency",
            "Save coins for special accessories in the store"
        ],
        "Health": [
            "Low health can be restored with medicine",
            "A pet with low energy will become tired",
            "Unhappy pets may refuse to play games",
            "Balance all stats for optimal pet growth"
        ]
    ]
    
    // Computed property to get all tips as a flat array
    var allTips: [String] {
        return Array(tipCategories.values).flatMap { $0 }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Tip display area
                VStack(alignment: .leading, spacing: 15) {
                    Text("Did you know?")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(allTips[currentTipIndex])
                        .font(.body)
                        .padding()
                        .frame(minHeight: 100)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding()
                
                // Category selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(tipCategories.keys), id: \.self) { category in
                            Button(action: {
                                if let firstIndex = tipCategories[category]?.first,
                                   let newIndex = allTips.firstIndex(of: firstIndex) {
                                    currentTipIndex = newIndex
                                }
                            }) {
                                Text(category)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(isCategoryActive(category) ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Tip navigation
                HStack(spacing: 30) {
                    Button(action: previousTip) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: randomTip) {
                        Image(systemName: "shuffle.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: nextTip) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Context-specific tip based on pet state
                if let contextTip = contextualTip() {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Suggested Action")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text(contextTip)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Tips & Tricks")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Helper function to check if a category is active
    private func isCategoryActive(_ category: String) -> Bool {
        if let tips = tipCategories[category],
           let firstIndex = tips.first,
           let startIndex = allTips.firstIndex(of: firstIndex),
           let lastTip = tips.last,
           let endIndex = allTips.firstIndex(of: lastTip) {
            return currentTipIndex >= startIndex && currentTipIndex <= endIndex
        }
        return false
    }
    
    // Navigation functions
    private func nextTip() {
        currentTipIndex = (currentTipIndex + 1) % allTips.count
    }
    
    private func previousTip() {
        currentTipIndex = (currentTipIndex - 1 + allTips.count) % allTips.count
    }
    
    private func randomTip() {
        let newIndex = Int.random(in: 0..<allTips.count)
        currentTipIndex = newIndex
    }
    
    // Generate contextual tip based on pet's current state
    private func contextualTip() -> String? {
        let pet = viewModel.pet
        
        if pet.hunger < 30 {
            return "Your pet is very hungry! Go to the Food tab to feed it."
        } else if pet.energy < 30 {
            return "Your pet is tired. Let it sleep to restore energy."
        } else if pet.cleanliness < 30 {
            return "Your pet needs a bath. Use the Clean action on the main screen."
        } else if pet.happiness < 30 {
            return "Your pet is unhappy. Play a game to cheer it up!"
        } else if pet.health < 50 {
            return "Your pet's health is low. Consider giving it medicine from the Store."
        }
        
        return nil
    }
}

struct TipsView_Previews: PreviewProvider {
    static var previews: some View {
        TipsView(viewModel: PetViewModel())
    }
} 