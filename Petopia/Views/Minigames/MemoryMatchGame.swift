//
//  MemoryMatchGame.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import SwiftUI

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    var isFaceUp = false
    var isMatched = false
    
    init(symbol: String) {
        self.symbol = symbol
    }
}

struct MemoryMatchGame: View {
    @ObservedObject var viewModel: PetViewModel
    let game: Minigame
    @Environment(\.presentationMode) var presentationMode
    @State private var cards: [MemoryCard] = []
    @State private var flippedIndices: Set<Int> = []
    @State private var matchedIndices: Set<Int> = []
    @State private var isProcessing = false
    @State private var movesCount = 0
    @State private var score = 0
    @State private var gameEnded = false
    @State private var showCountdown = true
    @State private var countdown = 3
    @State private var difficulty: GameDifficulty = .medium
    
    // Pet-specific emojis for the game
    private var symbols: [String] {
        switch viewModel.pet.type {
        case .cat:
            return ["🐱", "🐟", "🥛", "🧶", "🐭", "🐾", "🧃", "🏠", "🧸", "🦮", "🛌", "🦴"]
        case .chicken:
            return ["🐔", "🐣", "🐤", "🥚", "🌽", "🌱", "🐛", "🦗", "🐞", "🌾", "🌿", "🦅"]
        case .cow:
            return ["🐄", "🌱", "🌿", "🌾", "🥛", "🧀", "🍼", "🌽", "🥬", "🍎", "🏠", "☀️"]
        case .pig:
            return ["🐖", "🐷", "🥓", "🥔", "🥕", "🌽", "🍎", "🍄", "🥪", "🏠", "🧺", "🛁"]
        case .sheep:
            return ["🐑", "🌿", "🧶", "✂️", "☁️", "🌧️", "🧥", "🧦", "🧣", "💦", "🌈", "🏔️"]
        }
    }
    
    // Game theme color based on pet type
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
    
    // Pet-specific game title - use the game name from props
    private var gameTitle: String {
        return game.name
    }
    
    // Grid dimensions based on difficulty
    private var gridDimensions: (columns: Int, rows: Int) {
        switch difficulty {
        case .easy:
            return (4, 3) // 12 cards (6 pairs)
        case .medium:
            return (4, 4) // 16 cards (8 pairs)
        case .hard:
            return (5, 4) // 20 cards (10 pairs)
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Game header
                HStack {
                    VStack(alignment: .leading) {
                        Text(gameTitle)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Score: \(score)")
                            .font(.headline)
                            .foregroundColor(themeColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Moves: \(movesCount)")
                            .foregroundColor(.secondary)
                        
                        Text("Pairs: \(matchedIndices.count/2) of \(cards.count/2)")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Game board
                VStack(spacing: 10) {
                    ForEach(0..<gridDimensions.rows, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<gridDimensions.columns, id: \.self) { column in
                                let index = row * gridDimensions.columns + column
                                if index < cards.count {
                                    cardView(for: cards[index], at: index)
                                }
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Difficulty picker (only visible before start or after game ends)
                if gameEnded {
                    VStack {
                        Text("Choose Difficulty")
                            .font(.headline)
                        
                        Picker("Difficulty", selection: $difficulty) {
                            Text("Easy").tag(GameDifficulty.easy)
                            Text("Medium").tag(GameDifficulty.medium)
                            Text("Hard").tag(GameDifficulty.hard)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        Button(action: resetGame) {
                            Text("Play Again")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                
                // Game controls
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Exit")
                        }
                        .padding()
                        .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    if !gameEnded && !showCountdown {
                        Button(action: resetGame) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Restart")
                            }
                            .padding()
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Game over overlay
            if gameEnded {
                gameOverView
                    .transition(.opacity)
                    .animation(.easeInOut, value: gameEnded)
            }
            
            // Countdown overlay
            if showCountdown {
                countdownView
                    .transition(.opacity)
                    .animation(.easeInOut, value: showCountdown)
            }
        }
        .onAppear(perform: initializeGame)
    }
    
    // Card view
    private func cardView(for card: MemoryCard, at index: Int) -> some View {
        let isFlipped = flippedIndices.contains(index)
        let isMatched = matchedIndices.contains(index)
        
        return Button(action: {
            if !isProcessing && !isFlipped && !isMatched && !gameEnded {
                flipCard(at: index)
            }
        }) {
            ZStack {
                // Card back
                RoundedRectangle(cornerRadius: 10)
                    .fill(isMatched ? Color.green.opacity(0.3) : themeColor)
                    .frame(width: 70, height: 90)
                    .shadow(radius: 2)
                    .opacity(isFlipped || isMatched ? 0 : 1)
                
                // Card front
                RoundedRectangle(cornerRadius: 10)
                    .fill(isMatched ? Color.green.opacity(0.3) : Color.white)
                    .frame(width: 70, height: 90)
                    .shadow(radius: 2)
                    .opacity(isFlipped || isMatched ? 1 : 0)
                
                // Card emoji (instead of SF Symbol)
                Text(card.symbol)
                    .font(.system(size: 40))
                    .opacity(isFlipped || isMatched ? 1 : 0)
            }
            .rotation3DEffect(
                .degrees(isFlipped || isMatched ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeInOut(duration: 0.3), value: isFlipped)
            .animation(.easeInOut(duration: 0.3), value: isMatched)
        }
    }
    
    // Countdown view
    private var countdownView: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Get Ready!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(countdown)")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            startCountdown()
        }
    }
    
    // Game over view
    private var gameOverView: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Game Over!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You completed the game in \(movesCount) moves")
                    .font(.headline)
                
                Text("Score: \(score)")
                    .font(.title)
                    .foregroundColor(.blue)
                
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("+ \(calculateReward())")
                        .font(.headline)
                }
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(10)
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - Game Logic
    
    // Initialize the game
    private func initializeGame() {
        resetGame()
    }
    
    // Reset the game
    private func resetGame() {
        // Reset game state
        flippedIndices = []
        matchedIndices = []
        isProcessing = false
        movesCount = 0
        score = 0
        gameEnded = false
        showCountdown = true
        countdown = 3
        
        // Generate new cards
        let pairsCount = difficulty == .easy ? 6 : (difficulty == .medium ? 8 : 10)
        let gameSymbols = Array(symbols.prefix(pairsCount))
        
        // Create pairs
        var newCards: [MemoryCard] = []
        for symbol in gameSymbols {
            newCards.append(MemoryCard(symbol: symbol))
            newCards.append(MemoryCard(symbol: symbol)) // Duplicate for pairs
        }
        
        // Shuffle the cards
        cards = newCards.shuffled()
        
        // Start the countdown
        startCountdown()
    }
    
    // Start the countdown timer
    private func startCountdown() {
        countdown = 3
        showCountdown = true
        
        // Countdown timer
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                showCountdown = false
                timer.invalidate()
            }
        }
    }
    
    // Flip a card
    private func flipCard(at index: Int) {
        // Flip the card
        flippedIndices.insert(index)
        cards[index].isFaceUp = true
        
        // Check for matches if we have flipped two cards
        if flippedIndices.count == 2 {
            isProcessing = true
            movesCount += 1
            
            // Get the indices of the two flipped cards
            let flippedIndicesArray = Array(flippedIndices)
            let firstIndex = flippedIndicesArray[0]
            let secondIndex = flippedIndicesArray[1]
            
            // Check if they match
            if cards[firstIndex].symbol == cards[secondIndex].symbol {
                // Match found
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    matchedIndices.insert(firstIndex)
                    matchedIndices.insert(secondIndex)
                    cards[firstIndex].isMatched = true
                    cards[secondIndex].isMatched = true
                    flippedIndices = []
                    isProcessing = false
                    
                    // Update score
                    score += 10
                    
                    // Check if game is complete
                    if matchedIndices.count == cards.count {
                        endGame()
                    }
                }
            } else {
                // No match
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Flip cards back over
                    for index in flippedIndices {
                        cards[index].isFaceUp = false
                    }
                    flippedIndices = []
                    isProcessing = false
                    
                    // Penalty for wrong match
                    score = max(0, score - 2)
                }
            }
        }
    }
    
    // End the game
    private func endGame() {
        // Calculate final score and reward
        let reward = calculateReward()
        
        // Add reward to pet currency
        viewModel.pet.currency += reward
        
        // Save data
        AppDataManager.shared.saveAllData(viewModel: viewModel)
        
        // Mark game as ended
        gameEnded = true
    }
    
    // Calculate reward based on performance
    private func calculateReward() -> Int {
        let basePayout = difficulty == .easy ? 15 : (difficulty == .medium ? 25 : 40)
        let movesPenalty = movesCount - cards.count / 2 // Penalty for extra moves beyond perfect play
        let adjustedPayout = max(basePayout - movesPenalty, basePayout / 2)
        return adjustedPayout
    }
}

// MARK: - Supporting Types

// Game difficulty
enum GameDifficulty {
    case easy, medium, hard
}

// Preview
struct MemoryMatchGame_Previews: PreviewProvider {
    static var previews: some View {
        MemoryMatchGame(
            viewModel: PetViewModel(),
            game: Minigame(
                name: "Memory Match",
                description: "Match pairs of cards before time runs out!",
                difficulty: .medium,
                type: .memoryMatch,
                rewardAmount: 15,
                imageName: "game_memory",
                cooldownMinutes: 30,
                petType: .cat
            )
        )
    }
}
