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
                    .padding(.top, 2) // Reduce top padding to prevent cut-off
                    
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
                .padding(.top, 8) // Reduce from 12 to 8 to prevent cut-off
                
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
                        .accessibilityLabel("Your pet \(viewModel.pet.name), a \(viewModel.pet.type.rawValue)")
                        .accessibilityHint("Current status: \(viewModel.pet.currentStatus.description)")
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
                    print("DEBUG: PetView animation area appeared with pet type: \(viewModel.pet.type.rawValue)")
                    
                    // Force refresh the view when it appears to ensure correct pet type is shown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.objectWillChange.send()
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
                    .padding(.vertical, 6) // Increased from 4 to 6
                    .padding(.horizontal, 12)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(10) // Increased from 8 to 10
                    .padding(.horizontal)
                    .padding(.top, 4) // Added top padding for better spacing
                    .padding(.bottom, 4) // Added bottom padding for better spacing
                }
                
                // Stats display with reduced spacing
                VStack(spacing: 8) { // Reduced spacing between stats
                    StatBar(label: "Hunger", value: viewModel.pet.hunger, color: .orange)
                        .accessibilityLabel("Hunger: \(Int(viewModel.pet.hunger))%")
                    StatBar(label: "Happiness", value: viewModel.pet.happiness, color: .yellow)
                        .accessibilityLabel("Happiness: \(Int(viewModel.pet.happiness))%")
                    StatBar(label: "Health", value: viewModel.pet.health, color: .green)
                        .accessibilityLabel("Health: \(Int(viewModel.pet.health))%")
                    StatBar(label: "Cleanliness", value: viewModel.pet.cleanliness, color: .blue)
                        .accessibilityLabel("Cleanliness: \(Int(viewModel.pet.cleanliness))%")
                    StatBar(label: "Energy", value: viewModel.pet.energy, color: .purple)
                        .accessibilityLabel("Energy: \(Int(viewModel.pet.energy))%")
                    
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
            }
            
            Spacer() // Use remaining space
            
            // Action buttons fixed at the bottom but above tab bar
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 30) {
                    // Feed button - colored based on hunger level
                    SmallerActionButton(
                        title: "Feed", 
                        systemImage: "fork.knife",
                        action: {
                            if let food = viewModel.availableFood.first {
                                viewModel.feed(food: food)
                            }
                        },
                        isPrimaryAction: viewModel.pet.hunger < 40,
                        buttonColor: viewModel.pet.hunger < 30 ? .orange : .blue,
                        isDisabled: viewModel.availableFood.isEmpty || viewModel.pet.hunger >= 100,
                        disabledMessage: viewModel.pet.hunger >= 100 ? "Pet is full" : "No food available"
                    )
                    
                    // Clean button - colored based on cleanliness level
                    SmallerActionButton(
                        title: "Clean",
                        systemImage: "shower.fill",
                        action: {
                            viewModel.clean()
                        },
                        isPrimaryAction: viewModel.pet.cleanliness < 40,
                        buttonColor: viewModel.pet.cleanliness < 30 ? .cyan : .blue,
                        isDisabled: viewModel.pet.cleanliness >= 100,
                        disabledMessage: "Already clean"
                    )
                    
                    // Sleep button - colored based on energy level
                    SmallerActionButton(
                        title: "Sleep",
                        systemImage: "moon.fill",
                        action: {
                            viewModel.sleep(hours: 2)
                        },
                        isPrimaryAction: viewModel.pet.energy < 40,
                        buttonColor: viewModel.pet.energy < 30 ? .purple : .blue,
                        isDisabled: viewModel.pet.energy >= 100,
                        disabledMessage: "Not tired"
                    )
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
            }
        }
        // Add safe area respect
        .ignoresSafeArea(edges: .bottom)
        // Increase bottom padding to prevent overlap with tab bar
        .padding(.bottom, 80)
        .onAppear {
            // Notify the ViewModel that the view appeared
            viewModel.viewDidAppear()
        }
        .onDisappear {
            // Notify the ViewModel that the view disappeared
            viewModel.viewDidDisappear()
        }
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
    var isPrimaryAction: Bool = false
    var buttonColor: Color = .blue
    var isDisabled: Bool = false
    var disabledMessage: String = "Not available" // Add default message
    @State private var isPressed = false
    @State private var isActionTriggered = false
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                
                // Set the action triggered flag for micro-animation
                withAnimation {
                    isActionTriggered = true
                }
                
                // Add a slight delay before performing the action and resetting the animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    action()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    
                    // Reset the action trigger after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isActionTriggered = false
                        }
                    }
                }
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                    
                    // Action triggered animation overlay
                    if isActionTriggered {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 30, height: 30)
                            .scaleEffect(isActionTriggered ? 2 : 0)
                            .opacity(isActionTriggered ? 0 : 1)
                            .animation(.easeOut(duration: 0.5), value: isActionTriggered)
                    }
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(width: 70, height: 48)
            .background(
                // Gradient background with dynamic color based on status/availability
                LinearGradient(
                    gradient: Gradient(colors: [
                        isDisabled ? Color.gray : buttonColor,
                        isDisabled ? Color.gray.opacity(0.7) : buttonColor.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(isDisabled ? .gray.opacity(0.6) : .white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isDisabled ? 0.05 : 0.15), radius: 3, x: 0, y: 2)
            // Add scale effect when pressed - only if not disabled
            .scaleEffect((isPressed && !isDisabled) ? 0.95 : 1.0)
            // Add slight upward movement for 3D effect when pressed
            .offset(y: (isPressed && !isDisabled) ? 2 : 0)
            // Add shine effect for primary action buttons
            .overlay(
                isPrimaryAction && !isDisabled ? 
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(12)
                : nil
            )
            // Add a text overlay for disabled buttons to explain why
            .overlay(
                isDisabled ?
                    VStack {
                        Spacer()
                        Text(disabledMessage)
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .padding(.bottom, 4)
                    }
                : nil
            )
            // Add interactive spring animation
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .opacity(isDisabled ? 0.7 : 1.0)
            .accessibilityLabel("\(title) \(isDisabled ? disabledMessage : "")")
            .accessibilityHint(getAccessibilityHint())
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(isDisabled ? [] : .isButton)
        }
        .buttonStyle(PlainButtonStyle()) // Use plain style to customize our own feedback
        .disabled(isDisabled)
    }
    
    // Add a helper method for accessibility hints
    private func getAccessibilityHint() -> String {
        switch title {
        case "Feed":
            return "Feeds your pet to increase hunger level"
        case "Clean":
            return "Cleans your pet to increase cleanliness"
        case "Sleep":
            return "Puts your pet to sleep to recover energy"
        default:
            return "Interacts with your pet"
        }
    }
}

struct PetView_Previews: PreviewProvider {
    static var previews: some View {
        PetView(viewModel: PetViewModel())
    }
}
