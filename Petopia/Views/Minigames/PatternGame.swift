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
    
    let colors: [Color] = [.red, .green, .blue, .yellow]
    let sounds = ["note1", "note2", "note3", "note4"]
    
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
            
            // Pattern buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    Button {
                        if gameState == .input {
                            tapButton(index)
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors[index])
                            .opacity(isButtonActive(index) ? 1.0 : 0.5)
                            .frame(height: 130)
                    }
                }
            }
            .padding()
            
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
        if gameState == .showing, currentIndex < pattern.count, pattern[currentIndex] == index {
            return true
        }
        if gameState == .input, playerPattern.last == index {
            return true
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
        currentIndex = 0
        isShowingPattern = true
        
        func showNextInPattern() {
            if currentIndex < pattern.count {
                // Briefly show the current pattern item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentIndex += 1
                    if currentIndex < pattern.count {
                        showNextInPattern()
                    } else {
                        // Done showing pattern
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            currentIndex = -1
                            isShowingPattern = false
                            gameState = .input
                        }
                    }
                }
            }
        }
        
        showNextInPattern()
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
                cooldownMinutes: 45
            )
        )
    }
}
