//
//  QuickTapGame.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import SwiftUI
import Combine

struct TapItem: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var emoji: String
    var points: Int
    var appearanceTime: Date
    var isTapped = false
    var lifespan: Double // seconds the item will be visible
    var velocity: CGFloat = 0 // For falling items (used in catch games)
    var acceleration: CGFloat = 0 // For falling items (used in catch games)
    var opacity: Double = 1.0
    var isFadingOut = false
    
    var isActive: Bool {
        // Item remains active even when fading out, until explicitly tapped
        !isTapped
    }
}

struct QuickTapGame: View {
    @ObservedObject var viewModel: PetViewModel
    let game: Minigame
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var items: [TapItem] = []
    @State private var score = 0
    @State private var timeRemaining = 30
    @State private var gameState: GameState = .notStarted
    @State private var earnedCoins = 0
    @State private var streak = 0
    @State private var missedCount = 0
    
    @State private var gameAreaSize: CGSize = .zero
    
    // Make timers cancellable
    @State private var timer: AnyCancellable?
    @State private var gameTimer: AnyCancellable?
    
    // Determine if this is a catch game (with falling items) or a pop game (with stationary items)
    private var isCatchGame: Bool {
        return game.name.contains("Catch")
    }
    
    // Pet-specific properties
    private var petEmojis: [String] {
        switch viewModel.pet.type {
        case .cat:
            return ["🐟", "🥛", "🐭", "🧶", "🐦", "🥩", "🐱", "🐾"]
        case .chicken:
            return ["🌾", "🌽", "🌱", "🥜", "🐛", "🦗", "🪱", "🐔"]
        case .cow:
            return ["🌱", "🍎", "🌽", "🥕", "🥬", "🥦", "🌿", "🐄"]
        case .pig:
            return ["🥔", "🥕", "🌽", "🍎", "🥗", "🍄", "🐖", "🥜"]
        case .sheep:
            return ["🌱", "🍀", "☘️", "🌿", "🥬", "🧶", "🐑", "🌾"]
        }
    }
    
    private var themeColor: Color {
        switch viewModel.pet.type {
        case .cat:
            return .blue
        case .chicken:
            return .yellow
        case .cow:
            return .brown
        case .pig:
            return .pink
        case .sheep:
            return .mint
        }
    }
    
    enum GameState {
        case notStarted, playing, won, lost
    }
    
    var body: some View {
        VStack {
            // Game header
            VStack(spacing: 4) {
                Text(game.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(game.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)
            
            // Game stats
            HStack(spacing: 24) {
                VStack {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(timeRemaining)s")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(timeRemaining < 10 ? .red : .primary)
                }
                
                VStack {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(score)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(streak)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(streak >= 3 ? .green : .primary)
                }
            }
            .padding()
            
            // Game area with reduced height
            GeometryReader { geometry in
                ZStack {
                    Rectangle()
                        .fill(themeColor.opacity(0.1))
                        .overlay(
                            Rectangle()
                                .stroke(themeColor, lineWidth: 2)
                                .opacity(0.5)
                        )
                    
                    // Items
                    ForEach(items.indices, id: \.self) { index in
                        if !items[index].isTapped {
                            Text(items[index].emoji)
                                .font(.system(size: items[index].size * 0.7))
                                .frame(width: items[index].size, height: items[index].size)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .shadow(radius: 2)
                                )
                                .position(items[index].position)
                                .opacity(items[index].opacity)
                                .onTapGesture {
                                    tapItem(with: items[index].id)
                                }
                        }
                    }
                }
                .onAppear {
                    // Use the full geometry size for game area
                    gameAreaSize = geometry.size
                    print("Game area size: \(gameAreaSize.width) x \(gameAreaSize.height)")
                }
            }
            .padding()
            
            // Game over message
            if gameState == .won || gameState == .lost {
                VStack(spacing: 12) {
                    Text("Game Over! 🎮")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Final Score: \(score)")
                        .font(.headline)
                    
                    Text("You earned \(earnedCoins) coins!")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .frame(minWidth: 120)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                .padding()
            } else if gameState == .notStarted {
                Button("Start Game") {
                    startGame()
                }
                .padding()
                .frame(minWidth: 120)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
        }
        .onAppear {
            initializeGame()
        }
        .onDisappear {
            // Make sure to cancel timers when view disappears
            timer?.cancel()
            gameTimer?.cancel()
        }
    }
    
    private func initializeGame() {
        // Set up game based on difficulty
        switch game.difficulty {
        case .easy:
            timeRemaining = 30
        case .medium:
            timeRemaining = 45
        case .hard:
            timeRemaining = 60
        }
        
        score = 0
        streak = 0
        missedCount = 0
        items = []
        gameState = .notStarted
    }
    
    private func startGame() {
        gameState = .playing
        
        // Set up the game update timer (runs frequently for physics/item updates)
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard gameState == .playing else { return }
                
                updateItems()
                
                // Spawn new items periodically
                let spawnProbability = (game.difficulty == .hard) ? 0.3 : 
                                      (game.difficulty == .medium) ? 0.2 : 0.15
                if Double.random(in: 0...1) < spawnProbability {
                    spawnItem()
                }
            }
        
        // Set up the countdown timer (runs every second)
        gameTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard gameState == .playing else { return }
                
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    print("Time remaining: \(timeRemaining)")
                } else {
                    endGame()
                }
            }
        
        // Spawn initial items
        for _ in 0..<3 {
            spawnItem()
        }
    }
    
    private func spawnItem() {
        guard gameAreaSize.width > 0 && gameAreaSize.height > 0 else { return }
        
        // Randomize item properties
        let sizeRange: ClosedRange<CGFloat> = (game.difficulty == .hard) ? 40...60 : 50...80
        let size = CGFloat.random(in: sizeRange)
        
        // Calculate safe area to ensure items spawn within the visible game area
        let margin: CGFloat = size * 0.6 // Use 60% of item size as margin
        let minX = margin
        let maxX = gameAreaSize.width - margin
        
        var position: CGPoint
        var velocity: CGFloat = 0
        var acceleration: CGFloat = 0
        
        if isCatchGame {
            // For catch games, items spawn at the top within the game boundaries
            position = CGPoint(
                x: CGFloat.random(in: minX...maxX),
                y: margin // Start just inside the top edge
            )
            
            // Debug
            print("Spawned item at \(position.x), \(position.y) with game area \(gameAreaSize.width) x \(gameAreaSize.height)")
            
            // Adjust velocity based on current streak and score
            // Higher streak/score = faster items
            let streakMultiplier = min(1.0 + (Double(streak) * 0.1), 2.0) // Up to 2x speed at streak 10
            let scoreMultiplier = min(1.0 + (Double(score) / 100.0), 2.5) // Gradual increase with score
            
            // Base velocity increases with difficulty
            let baseVelocity: CGFloat = game.difficulty == .easy ? 2.0 : (game.difficulty == .medium ? 3.0 : 4.0)
            velocity = baseVelocity * CGFloat(streakMultiplier) * CGFloat(scoreMultiplier)
            
            // Acceleration stays consistent to maintain predictable physics
            let baseAcceleration: CGFloat = game.difficulty == .easy ? 0.3 : (game.difficulty == .medium ? 0.4 : 0.5)
            acceleration = baseAcceleration
        } else {
            // For pop games, items appear randomly in the game area
            let minY = margin
            let maxY = gameAreaSize.height - margin
            position = CGPoint(
                x: CGFloat.random(in: minX...maxX),
                y: CGFloat.random(in: minY...maxY)
            )
        }
        
        // Select emoji from pet-specific list, filtered to avoid cow emojis in Apple Catch
        var filteredEmojis = petEmojis
        if game.name.contains("Apple") {
            // Remove cow emoji from Apple Catch game
            filteredEmojis = petEmojis.filter { $0 != "🐄" }
        }
        let selectedEmoji = filteredEmojis.randomElement() ?? filteredEmojis[0]
        
        // Points based on size and speed (smaller and faster items worth more)
        let basePoints = 10
        let sizeMultiplier = Int((80 - size) / 5)
        let velocityMultiplier = Int(velocity * 2)
        let points = basePoints + sizeMultiplier + velocityMultiplier
        
        // Lifespan based on estimated fall time (shorter than before for faster gameplay)
        let lifespan: Double
        if isCatchGame {
            // Use faster lifespan to keep the game challenging
            let estimatedFallTime = gameAreaSize.height / (velocity + (acceleration * 5))
            lifespan = Double(estimatedFallTime) * 1.1 // Just enough time to fall through
        } else {
            // Pop games get shorter lifespans for challenge
            lifespan = game.difficulty == .easy ? 2.5 : (game.difficulty == .medium ? 2.0 : 1.5)
        }
        
        // Create the item
        let item = TapItem(
            position: position,
            size: size,
            emoji: selectedEmoji,
            points: points,
            appearanceTime: Date(),
            lifespan: lifespan,
            velocity: velocity,
            acceleration: acceleration
        )
        
        items.append(item)
    }
    
    private func updateItems() {
        // Check for expired items and update positions for falling items
        var itemsExpired = false
        
        for index in items.indices {
            if isCatchGame && !items[index].isTapped && items[index].isActive {
                // Update position for falling items in catch games
                var newPosition = items[index].position
                
                // Update velocity with acceleration
                items[index].velocity += items[index].acceleration * 0.1 // 0.1 is the timer interval
                
                // Update y position based on velocity
                newPosition.y += items[index].velocity
                
                // Calculate the bottom edge of the item
                let itemBottomEdge = newPosition.y + items[index].size

                // ABSOLUTE FINAL FIX
                
                // Hardcoded value significantly increased to ensure items reach the bottom
                let fadeStartPoint: CGFloat = 580
                
                if !items[index].isFadingOut && itemBottomEdge >= fadeStartPoint {
                    // Only start fading when the item has reached our known bottom boundary value
                    items[index].isFadingOut = true
                    
                    // Use a longer fade animation (1.5 seconds) to ensure it's more visible
                    withAnimation(.easeOut(duration: 1.5)) {
                        items[index].opacity = 0.0
                    }
                    
                    print("FADE START: y=\(newPosition.y), bottom edge=\(itemBottomEdge), hardcoded fade point=\(fadeStartPoint)")
                }
                
                // Always update position to continue movement
                items[index].position = newPosition
                
                // Only remove the item after it's been fading for a while and has moved past visible area
                // Wait until the animation is completely finished before removing the item
                // This ensures the full fade animation is visible
                if items[index].isFadingOut && (Date().timeIntervalSince(items[index].appearanceTime) > items[index].lifespan + 1.5) {
                    // Only remove when animation is complete
                    items[index].isTapped = true
                    streak = max(0, streak - 1)
                    missedCount += 1
                    itemsExpired = true
                    print("REMOVED: item at y=\(newPosition.y), animation complete")
                }
            } else if !items[index].isTapped && !items[index].isActive {
                // Item expired without being tapped
                items[index].isTapped = true
                streak = max(0, streak - 1) // Reduce streak instead of resetting
                missedCount += 1
                itemsExpired = true
            }
        }
        
        // Clean up only items that have been explicitly tapped or fully faded out
        items.removeAll { item in 
            // Remove if explicitly tapped by user
            if item.isTapped {
                return true
            }
            
            // For non-fading items, remove if they've expired normally
            if !item.isFadingOut && Date().timeIntervalSince(item.appearanceTime) > item.lifespan {
                return true
            }
            
            // For fading items, only remove after animation is complete (when opacity is near 0)
            if item.isFadingOut && item.opacity < 0.1 {
                return true
            }
            
            return false
        }
        
        // Penalize score for expired items
        if itemsExpired && score > 0 {
            score = max(0, score - 3)
        }
        
        // Dynamic spawn logic based on player's performance
        if isCatchGame && gameState == .playing {
            // Calculate how many items should be active based on streak and score
            let baseItemCount = 2 // Baseline item count
            let streakBonus = min(streak / 2, 3) // +1 item per 2 streak, max +3
            let scoreBonus = min(score / 50, 3) // +1 item per 50 points, max +3
            
            let targetItemCount = baseItemCount + streakBonus + scoreBonus
            let activeItemCount = items.filter({ !$0.isTapped && $0.isActive }).count
            
            // Spawn new items if we're below target count
            if activeItemCount < targetItemCount {
                spawnItem()
            }
        }
    }
    
    private func tapItem(with id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        // Allow tapping items that are fading out but not yet fully tapped
        if !items[index].isTapped {
            items[index].isTapped = true
            
            // Update score and streak
            streak += 1
            
            // Points calculation with increasing rewards for higher streaks
            let streakMultiplier = min(3, streak) // Cap multiplier at 3x
            let pointsEarned = items[index].points * streakMultiplier
            
            // Add visual feedback with animation
            withAnimation(.easeOut(duration: 0.2)) {
                score += pointsEarned
            }
            
            // Show tap feedback visually
            withAnimation(.easeOut(duration: 0.3)) {
                items[index].opacity = 0.0 // Fade out immediately when tapped
            }
            
            // Spawn a new item on successful tap for more dynamic gameplay
            if isCatchGame && Double.random(in: 0...1) < 0.7 { // 70% chance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    spawnItem()
                }
            }
            
            print("TAPPED: item at position y=\(items[index].position.y)")
        }
    }
    
    private func endGame() {
        // Cancel timers first to prevent any further updates
        timer?.cancel()
        gameTimer?.cancel()
        
        gameState = .won
        
        // Calculate final score adjustments
        let difficultyMultiplier: Double
        switch game.difficulty {
        case .easy: difficultyMultiplier = 1.0
        case .medium: difficultyMultiplier = 1.25
        case .hard: difficultyMultiplier = 1.5
        }
        
        let finalScore = Int(Double(score) * difficultyMultiplier)
        
        // Record the game played for cooldown
        viewModel.recordMinigamePlayed(game)
        
        // Award currency based on score
        // Estimate max possible score for the time limit
        let maxScore: Int
        switch game.difficulty {
        case .easy: maxScore = 300
        case .medium: maxScore = 500
        case .hard: maxScore = 750
        }
        
        earnedCoins = calculateReward(score: finalScore, maxScore: maxScore)
        viewModel.awardMinigameReward(minigame: game, score: finalScore, maxScore: maxScore)
    }
    
    private func calculateReward(score: Int, maxScore: Int) -> Int {
        let baseReward = game.possibleReward
        let percentage = min(1.0, Double(score) / Double(maxScore))
        return Int(Double(baseReward) * percentage)
    }
}

struct TapItemView: View {
    let item: TapItem
    
    var body: some View {
        Text(item.emoji)
            .font(.system(size: item.size * 0.7))
            .frame(width: item.size, height: item.size)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .shadow(radius: 2)
            )
            .transition(.scale)
            .animation(.easeOut(duration: 0.2), value: item.size)
    }
}

struct QuickTapGame_Previews: PreviewProvider {
    static var previews: some View {
        QuickTapGame(
            viewModel: PetViewModel(),
            game: Minigame(
                name: "Treat Catch",
                description: "Tap falling treats before they disappear!",
                difficulty: .medium,
                type: .quickTap,
                rewardAmount: 12,
                imageName: "game_tap",
                cooldownMinutes: 20,
                petType: .cat
            )
        )
    }
}
