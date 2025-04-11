//
//  PatternGame.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import SwiftUI

struct PatternGame: View {
    @ObservedObject var viewModel: PetViewModel
    let game: Minigame
    
    @Environment(\.presentationMode) var presentationMode
    @State private var pattern: [Int] = []
    @State private var playerPattern: [Int] = []
    @State private var isShowingPattern = false
    @State private var currentIndex = 0
    @State private var round = 1
    @State private var score = 0
    @State private var gameState: GameState = .notStarted
    @State private var earnedCoins = 0
    
    enum GameState {
        case notStarted, showing, input, correct, incorrect, gameOver
    }
    
    // Pet-specific game colors
    var colors: [Color] {
        switch viewModel.pet.type {
        case .cat:
            return [.blue, .teal, .purple, .pink]
        case .chicken:
            return [.yellow, .orange, .red, .green]
        case .cow:
            return [.brown, .black, .white, .gray]
        case .pig:
            return [.pink, .red, .brown, .orange]
        case .sheep:
            return [.mint, .white, .gray, .black]
        }
    }
    
    // Pet-specific game sounds (these would be actual sound files in the project)
    var sounds: [String] {
        switch viewModel.pet.type {
        case .cat:
            return ["cat_note1", "cat_note2", "cat_note3", "cat_note4"]
        case .chicken:
            return ["chicken_note1", "chicken_note2", "chicken_note3", "chicken_note4"]
        case .cow:
            return ["cow_note1", "cow_note2", "cow_note3", "cow_note4"]
        case .pig:
            return ["pig_note1", "pig_note2", "pig_note3", "pig_note4"]
        case .sheep:
            return ["sheep_note1", "sheep_note2", "sheep_note3", "sheep_note4"]
        }
    }
    
    // Pet-specific background color
    var backgroundColor: Color {
        switch viewModel.pet.type {
        case .cat:
            return Color.blue.opacity(0.1)
        case .chicken:
            return Color.yellow.opacity(0.1)
        case .cow:
            return Color.brown.opacity(0.1)
        case .pig:
            return Color.pink.opacity(0.1)
        case .sheep:
            return Color.mint.opacity(0.1)
        }
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
                    Text("Round")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(round)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(score)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding()
            
            Text(statusMessage())
                .font(.headline)
                .foregroundColor(statusColor())
                .padding()
            
            // Progress indicators
            if gameState == .showing || gameState == .input {
                HStack {
                    ForEach(0..<pattern.count, id: \.self) { i in
                        Circle()
                            .fill(getProgressIndicatorColor(for: i))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.bottom, 5)
            }
            
            // Pattern buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    Button {
                        if gameState == .input {
                            tapButton(index)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors[index])
                                .opacity(isButtonActive(index) ? 1.0 : 0.5)
                                .frame(height: 130)
                            
                            // Enhanced visual feedback for showing phase
                            if gameState == .showing && isButtonActive(index) {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 110, height: 110)
                                
                                Circle()
                                    .fill(Color.white)
                                    .opacity(0.6)
                                    .frame(width: 50, height: 50)
                                    .scaleEffect(1.2)
                                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
                            }
                            
                            // Add number indicators to show sequence during input phase
                            if gameState == .input {
                                ForEach(0..<playerPattern.count, id: \.self) { i in
                                    if playerPattern[i] == index {
                                        Text("\(i+1)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                            .offset(x: CGFloat(i * 10 - 15), y: -40)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            
            if gameState == .notStarted {
                Button("Start Game") {
                    startGame()
                }
                .padding()
                .frame(minWidth: 120)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if gameState == .gameOver {
                VStack(spacing: 12) {
                    Text("Game Over!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Final Round: \(round)")
                        .font(.headline)
                    
                    Text("Score: \(score)")
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
            }
        }
        .onChange(of: gameState) { newState in
            if newState == .showing {
                showPattern()
            } else if newState == .correct {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    nextRound()
                }
            } else if newState == .incorrect {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    endGame()
                }
            }
        }
    }
    
    private func statusMessage() -> String {
        switch gameState {
        case .notStarted:
            return "Get ready to watch and repeat the pattern!"
        case .showing:
            return "Watch the pattern..."
        case .input:
            return "Repeat the pattern!"
        case .correct:
            return "Correct! Get ready for the next round."
        case .incorrect:
            return "Sorry, that wasn't right!"
        case .gameOver:
            return "Game Over!"
        }
    }
    
    private func statusColor() -> Color {
        switch gameState {
        case .correct: return .green
        case .incorrect, .gameOver: return .red
        default: return .primary
        }
    }
    
    private func isButtonActive(_ index: Int) -> Bool {
        // Guard against invalid currentIndex (source of crash)
        if gameState == .showing, currentIndex >= 0, currentIndex < pattern.count {
            return pattern[currentIndex] == index
        }
        
        // Check if this is the last button tapped during input phase
        if gameState == .input, let lastTapped = playerPattern.last {
            return lastTapped == index
        }
        
        return false
    }
    
    private func startGame() {
        pattern = []
        playerPattern = []
        round = 1
        score = 0
        gameState = .notStarted
        
        addToPattern()
        gameState = .showing
    }
    
    private func addToPattern() {
        pattern.append(Int.random(in: 0..<4))
    }
    
    private func showPattern() {
        // Reset state
        currentIndex = -1
        isShowingPattern = true
        
        // Create a sequence of timed events to display the pattern
        var displayDelay: TimeInterval = 0.5
        
        // Schedule each display event with increasing delays
        for (index, _) in pattern.enumerated() {
            // Turn on the button at the right time
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDelay) {
                if self.gameState == .showing {
                    self.currentIndex = index
                    print("Showing pattern item \(index): \(self.pattern[index])")
                }
            }
            
            // Turn off the button after a short display time
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDelay + 0.5) {
                if self.gameState == .showing {
                    self.currentIndex = -1
                }
            }
            
            // Increment delay for the next item
            displayDelay += 0.8
        }
        
        // Switch to input state after displaying all items
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDelay) {
            if self.gameState == .showing {
                self.currentIndex = -1
                self.isShowingPattern = false
                self.gameState = .input
                print("Pattern display complete, ready for input")
            }
        }
    }
    
    private func tapButton(_ index: Int) {
        playerPattern.append(index)
        
        // Check if the pattern is correct so far
        let playerIndex = playerPattern.count - 1
        if playerIndex < pattern.count && pattern[playerIndex] == index {
            // Correct input so far
            if playerPattern.count == pattern.count {
                // Completed the pattern correctly
                score += round * 10
                gameState = .correct
            }
        } else {
            // Incorrect input
            gameState = .incorrect
        }
    }
    
    private func nextRound() {
        round += 1
        playerPattern = []
        addToPattern()
        gameState = .showing
    }
    
    private func endGame() {
        gameState = .gameOver
        
        // Record the game played for cooldown
        viewModel.recordMinigamePlayed(game)
        
        // Award currency based on score
        let maxScore = 500 // Arbitrary max score for this game
        earnedCoins = calculateReward(score: score, maxScore: maxScore)
        viewModel.awardMinigameReward(minigame: game, score: score, maxScore: maxScore)
    }
    
    private func calculateReward(score: Int, maxScore: Int) -> Int {
        let baseReward = game.possibleReward
        let percentage = min(1.0, Double(score) / Double(maxScore))
        return Int(Double(baseReward) * percentage)
    }
    
    private func getProgressIndicatorColor(for index: Int) -> Color {
        if gameState == .showing && index < currentIndex {
            return .green
        } else if gameState == .input && index < playerPattern.count {
            return .blue
        } else {
            return .gray
        }
    }
}

struct PatternGame_Previews: PreviewProvider {
    static var previews: some View {
        PatternGame(
            viewModel: PetViewModel(),
            game: Minigame(
                name: "Pet Simon",
                description: "Remember and repeat the pattern of sounds and colors!",
                difficulty: .medium,
                type: .patternRecognition,
                rewardAmount: 18,
                imageName: "game_pattern",
                cooldownMinutes: 45,
                petType: .cat
            )
        )
    }
}
