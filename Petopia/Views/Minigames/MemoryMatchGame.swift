//
//  MemoryMatchGame.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import SwiftUI

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    var isFaceUp = false
    var isMatched = false
}

struct MemoryMatchGame: View {
    @ObservedObject var viewModel: PetViewModel
    let game: Minigame
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var cards: [MemoryCard] = []
    @State private var flippedCardIndices: [Int] = []
    @State private var matchedPairs = 0
    @State private var moves = 0
    @State private var score = 0
    @State private var timeRemaining = 60
    @State private var gameState: GameState = .notStarted
    @State private var earnedCoins = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let totalPairs = 8
    
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
                        .foregroundColor(timeRemaining < 15 ? .red : .primary)
                }
                
                VStack {
                    Text("Pairs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(matchedPairs)/\(totalPairs)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Moves")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(moves)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding()
            
            // Card grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card)
                        .aspectRatio(2/3, contentMode: .fit)
                        .onTapGesture {
                            if gameState == .notStarted {
                                gameState = .playing
                            }
                            
                            if gameState == .playing && canFlipCard(at: index) {
                                flipCard(at: index)
                            }
                        }
                }
            }
            .padding()
            
            // Game over message
            if gameState == .won || gameState == .lost {
                VStack(spacing: 12) {
                    Text(gameState == .won ? "You Won! 🎉" : "Time's Up! ⏰")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(gameState == .won ? .green : .red)
                    
                    if gameState == .won {
                        Text("You earned \(earnedCoins) coins!")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
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
                    gameState = .playing
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
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    endGame(won: false)
                }
            }
        }
    }
    
    private func initializeGame() {
        // Generate pairs of emojis for cards
        let emojis = ["🐶", "🐱", "🐭", "🐰", "🦊", "🐻", "🐼", "🐨", "🦁", "🐮", "🐷", "🐸"]
        let selectedEmojis = Array(emojis.shuffled().prefix(totalPairs))
        
        // Create card pairs and shuffle
        var newCards: [MemoryCard] = []
        for emoji in selectedEmojis {
            newCards.append(MemoryCard(emoji: emoji))
            newCards.append(MemoryCard(emoji: emoji))
        }
        
        cards = newCards.shuffled()
        timeRemaining = difficulty(for: game.difficulty)
        gameState = .notStarted
        matchedPairs = 0
        moves = 0
        score = 0
        flippedCardIndices = []
    }
    
    private func difficulty(for difficulty: MinigameDifficulty) -> Int {
        switch difficulty {
        case .easy: return 90
        case .medium: return 60
        case .hard: return 45
        }
    }
    
    private func canFlipCard(at index: Int) -> Bool {
        // Cannot flip if already face up or matched
        if cards[index].isFaceUp || cards[index].isMatched {
            return false
        }
        
        // Cannot flip if already have two cards flipped
        if flippedCardIndices.count >= 2 {
            return false
        }
        
        return true
    }
    
    private func flipCard(at index: Int) {
        cards[index].isFaceUp = true
        flippedCardIndices.append(index)
        
        // If we have two cards flipped, check for a match
        if flippedCardIndices.count == 2 {
            moves += 1
            
            // Check if cards match
            let firstIndex = flippedCardIndices[0]
            let secondIndex = flippedCardIndices[1]
            
            if cards[firstIndex].emoji == cards[secondIndex].emoji {
                // Cards match
                cards[firstIndex].isMatched = true
                cards[secondIndex].isMatched = true
                matchedPairs += 1
                
                // Update score
                score += 10 + min(10, timeRemaining / 2)
                
                // Check if game is won
                if matchedPairs == totalPairs {
                    endGame(won: true)
                }
            }
            
            // Reset flipped cards after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                for index in flippedCardIndices where !cards[index].isMatched {
                    cards[index].isFaceUp = false
                }
                flippedCardIndices = []
            }
        }
    }
    
    private func endGame(won: Bool) {
        gameState = won ? .won : .lost
        
        if won {
            // Calculate the final score based on time remaining and moves
            let timeBonus = timeRemaining
            let moveEfficiency = max(0, 30 - max(0, moves - totalPairs * 2))
            score += timeBonus + moveEfficiency
            
            // Record the game played for cooldown
            viewModel.recordMinigamePlayed(game)
            
            // Award currency based on score
            // Estimate max possible score
            let maxScore = 10 * totalPairs + 60 + 30
            earnedCoins = calculateReward(score: score, maxScore: maxScore)
            viewModel.awardMinigameReward(minigame: game, score: score, maxScore: maxScore)
        }
    }
    
    private func calculateReward(score: Int, maxScore: Int) -> Int {
        let baseReward = game.possibleReward
        let percentage = min(1.0, Double(score) / Double(maxScore))
        return Int(Double(baseReward) * percentage)
    }
}

struct CardView: View {
    let card: MemoryCard
    
    var body: some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: 12)
            
            if card.isFaceUp {
                shape.fill().foregroundColor(.white)
                shape.strokeBorder(lineWidth: 3)
                    .foregroundColor(card.isMatched ? .green : .blue)
                Text(card.emoji)
                    .font(.system(size: 32))
            } else {
                shape.fill().foregroundColor(card.isMatched ? .green.opacity(0.3) : .blue)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .opacity(card.isMatched ? 0.6 : 1)
    }
}

struct MemoryMatchGame_Previews: PreviewProvider {
    static var previews: some View {
        MemoryMatchGame(
            viewModel: PetViewModel(),
            game: Minigame(
                name: "Pet Match",
                description: "Match pairs of pet cards before time runs out!",
                difficulty: .medium,
                type: .memoryMatch,
                rewardAmount: 15,
                imageName: "game_memory",
                cooldownMinutes: 30
            )
        )
    }
}
