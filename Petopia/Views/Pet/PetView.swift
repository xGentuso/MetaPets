//
//  PetView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct PetView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            // Pet name and level
            VStack(spacing: 4) {
                HStack {
                    Spacer()
                    
                    CurrencyBadge(amount: viewModel.pet.currency)
                }
                .padding(.horizontal)
                
                Text(viewModel.pet.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Level \(viewModel.pet.level) • \(viewModel.pet.stage.rawValue.capitalized)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Pet animation area
            ZStack {
                // Background based on pet's status
                Circle()
                    .fill(backgroundColorForStatus)
                    .frame(width: 280, height: 280)
                
                // Pet image
                Image(systemName: "pawprint.circle.fill") // Placeholder, would be a custom image
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(viewModel.pet.color)
                    .frame(width: 200, height: 200)
                    .offset(y: isAnimating ? -10 : 10)
                    .animation(
                        Animation.easeInOut(duration: animationDuration)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                
                // Status indicator
                Text(viewModel.pet.currentStatus.emoji)
                    .font(.system(size: 40))
                    .offset(x: 80, y: -80)
            }
            .padding()
            
            // Stats display
            VStack(spacing: 12) {
                StatBar(label: "Hunger", value: viewModel.pet.hunger, color: .orange)
                StatBar(label: "Happiness", value: viewModel.pet.happiness, color: .yellow)
                StatBar(label: "Health", value: viewModel.pet.health, color: .green)
                StatBar(label: "Cleanliness", value: viewModel.pet.cleanliness, color: .blue)
                StatBar(label: "Energy", value: viewModel.pet.energy, color: .purple)
                
                Text("Experience: \(viewModel.pet.experience)/\(viewModel.pet.level * 100)")
                    .font(.caption)
                    .padding(.top, 8)
            }
            .padding()
            
            // Quick action buttons
            HStack(spacing: 20) {
                ActionButton(title: "Feed", systemImage: "fork.knife") {
                    if let food = viewModel.availableFood.first {
                        viewModel.feed(food: food)
                    }
                }
                
                ActionButton(title: "Clean", systemImage: "shower.fill") {
                    viewModel.clean()
                }
                
                ActionButton(title: "Sleep", systemImage: "moon.fill") {
                    viewModel.sleep(hours: 2)
                }
            }
            .padding()
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
        switch viewModel.pet.currentStatus {
        case .happy: return 1.0  // Bouncy and energetic
        case .hungry: return 2.0  // Slower, lethargic
        case .sick: return 1.5    // Slightly shaky
        case .sleepy: return 3.0  // Very slow, sleepy
        case .dirty: return 1.8   // Uncomfortable
        }
    }
}

struct PetView_Previews: PreviewProvider {
    static var previews: some View {
        PetView(viewModel: PetViewModel())
    }
}
