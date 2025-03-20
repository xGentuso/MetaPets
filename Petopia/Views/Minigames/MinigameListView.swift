//
//  MinigamesListView.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import SwiftUI

struct MinigamesListView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var selectedGameType: MinigameType?
    @State private var showGameView = false
    @State private var selectedGame: Minigame?
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            VStack {
                // Currency display
                HStack {
                    Spacer()
                    CurrencyBadge(amount: viewModel.pet.currency)
                }
                .padding(.horizontal)
                
                // Game type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(title: "All", isSelected: selectedGameType == nil) {
                            selectedGameType = nil
                        }
                        
                        ForEach(MinigameType.allCases, id: \.self) { type in
                            FilterButton(title: type.description, isSelected: selectedGameType == type) {
                                selectedGameType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Games list
                List {
                    ForEach(filteredGames) { game in
                        Button {
                            selectedGame = game
                            showGameView = true
                        } label: {
                            MinigameCell(viewModel: viewModel, game: game)
                                .id("\(refreshID)-\(game.id)")
                        }
                        .disabled(!viewModel.canPlayMinigame(game))
                    }
                }
            }
            .navigationTitle("Minigames")
            .onReceive(timer) { _ in
                // Refresh view to update cooldown timers
                refreshID = UUID()
            }
            .sheet(isPresented: $showGameView) {
                if let game = selectedGame {
                    gameView(for: game)
                }
            }
        }
    }
    
    private var filteredGames: [Minigame] {
        if let type = selectedGameType {
            return viewModel.availableMinigames.filter { $0.type == type }
        } else {
            return viewModel.availableMinigames
        }
    }
    
    private func gameView(for game: Minigame) -> some View {
        switch game.type {
        case .memoryMatch:
            return AnyView(MemoryMatchGame(viewModel: viewModel, game: game))
        case .quickTap:
            return AnyView(QuickTapGame(viewModel: viewModel, game: game))
        case .patternRecognition:
            return AnyView(PatternGame(viewModel: viewModel, game: game))
        case .petCare:
            return AnyView(PetCareQuiz(viewModel: viewModel, game: game))
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct MinigameCell: View {
    let viewModel: PetViewModel
    let game: Minigame
    
    var body: some View {
        HStack {
            Image(systemName: "gamecontroller.fill")
                .foregroundColor(.purple)
                .frame(width: 40, height: 40)
                .background(Color.purple.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.headline)
                
                Text(game.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(game.difficulty.description)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(difficultyColor(game.difficulty).opacity(0.2))
                        )
                        .foregroundColor(difficultyColor(game.difficulty))
                    
                    Spacer()
                    
                    if viewModel.canPlayMinigame(game) {
                        Text("Reward: \(game.possibleReward) coins")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text(formatTimeRemaining(viewModel.timeUntilMinigameAvailable(game)))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(viewModel.canPlayMinigame(game) ? 1.0 : 0.6)
    }
    
    private func difficultyColor(_ difficulty: MinigameDifficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return "Available in: \(minutes)m \(seconds)s"
    }
}

struct MinigamesListView_Previews: PreviewProvider {
    static var previews: some View {
        MinigamesListView(viewModel: PetViewModel())
    }
}
