import SwiftUI

struct PetView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area with reduced padding and spacing
            VStack(spacing: 5) {
                // Pet name, level, and currency badge
                ZStack {
                    // Center pet information
                    VStack(alignment: .center, spacing: 0) {
                        Text(viewModel.pet.name)
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Level \(viewModel.pet.level) • \(viewModel.pet.stage.rawValue.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Settings icon placeholder on the left (for visual balance)
                    HStack {
                        Color.clear
                            .frame(width: 38, height: 38)
                        Spacer()
                    }
                    
                    // Currency badge on the right
                    HStack {
                        Spacer()
                        CurrencyBadge(amount: viewModel.pet.currency)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Pet animation area (reduced size)
                ZStack {
                    // Background based on pet's status
                    Circle()
                        .fill(backgroundColorForStatus)
                        .frame(width: 220, height: 220) // Smaller circle
                    
                    // Get the pet type and log it for debugging
                    let petType = viewModel.pet.type.rawValue
                    
                    // Use a single Image with controlled animation
                    Image(petType)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        // Use a more controlled offset animation to prevent doubling
                        .offset(y: isAnimating ? -5 : 5)
                        // Keep the animation smooth
                        .animation(
                            Animation
                                .easeInOut(duration: animationDuration)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        // Make sure we have a stable ID that doesn't regenerate on state changes
                        .id("pet-image-\(petType)")
                    
                    // Status indicator (moved outside to prevent interference with pet animation)
                    Text(viewModel.pet.currentStatus.emoji)
                        .font(.system(size: 36))
                        .offset(x: 65, y: -65)
                        // No animation on the emoji
                        .animation(nil, value: isAnimating)
                }
                .padding(.vertical, 5) // Reduced padding
                .onAppear {
                    // Set animation flag only once on appear
                    isAnimating = true
                    print("DEBUG: PetView appeared with pet type: \(viewModel.pet.type.rawValue)")
                    
                    // Force refresh the view when it appears to ensure correct pet type is shown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.objectWillChange.send()
                    }
                    
                    // Verify pet type one more time on view appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        print("DEBUG: CRITICAL: Re-verifying pet type on view appear")
                        viewModel.verifyAndRefreshPetType()
                    }
                }
                
                // Quick Tip based on pet status
                if let tip = quickTip() {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text(tip)
                            .font(.caption)
                            .italic()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Stats display with reduced spacing
                VStack(spacing: 8) { // Reduced spacing between stats
                    StatBar(label: "Hunger", value: viewModel.pet.hunger, color: .orange)
                    StatBar(label: "Happiness", value: viewModel.pet.happiness, color: .yellow)
                    StatBar(label: "Health", value: viewModel.pet.health, color: .green)
                    StatBar(label: "Cleanliness", value: viewModel.pet.cleanliness, color: .blue)
                    StatBar(label: "Energy", value: viewModel.pet.energy, color: .purple)
                    
                    Text("Experience: \(viewModel.pet.experience)/\(viewModel.pet.level * 100)")
                        .font(.caption)
                        .padding(.top, 2) // Reduced top padding
                }
                .padding(.horizontal)
                .padding(.vertical, 3) // Reduced vertical padding
                
                // Evolution Timeline
                if let nextStage = viewModel.pet.stage.nextStage {
                    VStack(spacing: 2) {
                        HStack {
                            Text("Next Evolution:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(nextStage.rawValue.capitalized) at Level \(evolutionLevel())")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                        
                        EvolutionProgressBar(currentLevel: viewModel.pet.level, targetLevel: evolutionLevel())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 3)
                }
                
                // Pet age display
                HStack {
                    Text("Age: \(viewModel.pet.age) days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 3)
                
                // Pet accessories section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessories:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        ForEach(viewModel.pet.accessories) { accessory in
                            VStack {
                                Image(systemName: accessoryIcon(for: accessory.position))
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                    .frame(width: 30, height: 30)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                
                                Text(accessory.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                        
                        // Show empty slots for missing accessories
                        if !viewModel.pet.accessories.contains(where: { $0.position == .head }) {
                            emptyAccessorySlot(position: .head)
                        }
                        
                        if !viewModel.pet.accessories.contains(where: { $0.position == .neck }) {
                            emptyAccessorySlot(position: .neck)
                        }
                        
                        if !viewModel.pet.accessories.contains(where: { $0.position == .body }) {
                            emptyAccessorySlot(position: .body)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal)
                .padding(.top, 3)
            }
            
            Spacer() // Use remaining space
            
            // Action buttons fixed at the bottom but above tab bar
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 30) {
                    SmallerActionButton(title: "Feed", systemImage: "fork.knife") {
                        if let food = viewModel.availableFood.first {
                            viewModel.feed(food: food)
                        }
                    }
                    
                    SmallerActionButton(title: "Clean", systemImage: "shower.fill") {
                        viewModel.clean()
                    }
                    
                    SmallerActionButton(title: "Sleep", systemImage: "moon.fill") {
                        viewModel.sleep(hours: 2)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
            }
        }
        // Add safe area respect
        .ignoresSafeArea(edges: .bottom)
        // Add specific extra padding for the tab bar
        .padding(.bottom, 60)
    }
    
    // Helper function to get the evolution level
    private func evolutionLevel() -> Int {
        // Evolution happens every 5 levels - find the next one
        let currentLevel = viewModel.pet.level
        return ((currentLevel / 5) + 1) * 5
    }
    
    // Quick tip based on pet's needs
    private func quickTip() -> String? {
        if viewModel.pet.hunger < 40 {
            return "Your pet is getting hungry! Try feeding it."
        } else if viewModel.pet.cleanliness < 40 {
            return "Your pet could use a bath soon."
        } else if viewModel.pet.energy < 40 {
            return "Your pet is tired. Let it sleep to recover energy."
        } else if viewModel.pet.happiness < 40 {
            return "Your pet seems bored. Try playing with it!"
        } else if viewModel.pet.health < 70 {
            return "Your pet's health is declining. Consider medicine."
        }
        return nil
    }
    
    // Helper function to get icon for accessory position
    private func accessoryIcon(for position: Accessory.AccessoryPosition) -> String {
        switch position {
        case .head: return "crown.fill"
        case .neck: return "bowtie"
        case .body: return "tshirt.fill"
        }
    }
    
    // Empty accessory slot view
    private func emptyAccessorySlot(position: Accessory.AccessoryPosition) -> some View {
        VStack {
            Image(systemName: accessoryIcon(for: position))
                .font(.system(size: 18))
                .foregroundColor(.gray.opacity(0.5))
                .frame(width: 30, height: 30)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            Text(position.rawValue.capitalized)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var backgroundColorForStatus: Color {
        switch viewModel.pet.currentStatus {
        case .happy: return Color.green.opacity(0.2)
        case .hungry: return Color.orange.opacity(0.2)
        case .sick: return Color.red.opacity(0.2)
        case .sleepy: return Color.purple.opacity(0.2)
        case .dirty: return Color.brown.opacity(0.2)
        }
    }
    
    private var animationDuration: Double {
        // Use a consistent animation duration to avoid timing issues
        return 1.5
    }
}

// Evolution progress bar
struct EvolutionProgressBar: View {
    let currentLevel: Int
    let targetLevel: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple.opacity(0.2))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple)
                    .frame(width: progressWidth(for: geometry.size.width), height: 8)
            }
        }
        .frame(height: 8)
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let progress = min(1.0, Double(currentLevel % 5) / 5.0)
        return CGFloat(progress) * totalWidth
    }
}

// Smaller action button component
struct SmallerActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 60, height: 40)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct PetView_Previews: PreviewProvider {
    static var previews: some View {
        PetView(viewModel: PetViewModel())
    }
}
