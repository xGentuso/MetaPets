//
//  QuickTapGame.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import SwiftUI

struct TapItem: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var emoji: String
    var points: Int
    var appearanceTime: Date
    var isTapped = false
    var lifespan: Double // seconds the item will be visible
    
    var isActive: Bool {
        !isTapped && Date().timeIntervalSince(appearanceTime) < lifespan
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
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            
            // Game area
            GeometryReader { geometry in
                ZStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 2)
                                .opacity(0.5)
                        )
                    
                    ForEach(items.filter { $0.isActive }) { item in
                        TapItemView(item: item)
                            .position(item.position)
                            .onTapGesture {
                                tapItem(with: item.id)
                            }
                    }
                }
                .onAppear {
                    gameAreaSize = geometry.size
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
        .onReceive(timer) { _ in
            if gameState == .playing {
                updateItems()
                
                // Spawn new items periodically
                let spawnProbability = (game.difficulty == .hard) ? 0.3 : (game.difficulty == .medium) ? 0.2 : 0.15
                if Double.random(in: 0...1) < spawnProbability {
                    spawnItem()
                }
            }
        }
        .onReceive(gameTimer) { _ in
            if gameState == .playing {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    endGame()
                }
            }
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
        
        let maxX = gameAreaSize.width - size
        let maxY = gameAreaSize.height - size
        
        let position = CGPoint(
            x: CGFloat.random(in: size/2...maxX-size/2),
            y: CGFloat.random(in: size/2...maxY-size/2)
        )
        
        // Select emoji
        let emojis = ["🍖", "🍗", "🦴", "🍪", "🥩", "🥕", "🍎", "🍌"]
        let selectedEmoji = emojis.randomElement() ?? "🍖"
        
        // Points based on size (smaller items worth more)
        let basePoints = 10
        let sizeMultiplier = Int((80 - size) / 5)
        let points = basePoints + sizeMultiplier
        
        // Lifespan based on difficulty
        let lifespan: Double
        switch game.difficulty {
        case .easy: lifespan = 3.0
        case .medium: lifespan = 2.5
        case .hard: lifespan = 2.0
        }
        
        // Create the item
        let item = TapItem(
            position: position,
            size: size,
            emoji: selectedEmoji,
            points: points,
            appearanceTime: Date(),
            lifespan: lifespan
        )
        
        items.append(item)
    }
    
    private func updateItems() {
        // Check for expired items
        var itemsExpired = false
        
        for index in items.indices {
            if !items[index].isTapped && !items[index].isActive {
                // Item expired without being tapped
                items[index].isTapped = true
                streak = 0
                missedCount += 1
                itemsExpired = true
            }
        }
        
        // Clean up tapped or expired items periodically
        if items.count > 20 {
            items.removeAll { !$0.isActive }
        }
        
        // Penalize score for expired items
        if itemsExpired && score > 0 {
            score = max(0, score - 5)
        }
    }
    
    private func tapItem(with id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        if items[index].isActive && !items[index].isTapped {
            items[index].isTapped = true
            
            // Update score and streak
            streak += 1
            let streakMultiplier = min(3, streak) // Cap multiplier at 3x
            let pointsEarned = items[index].points * streakMultiplier
            score += pointsEarned
        }
    }
    
    private func endGame() {
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
                cooldownMinutes: 20
            )
        )
    }
}
