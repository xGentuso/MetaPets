//
//  OnboardingView.swift
//
//  OnboardingView.swift
//  Petopia
//
//  Created for Petopia
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showWelcome = true
    @State private var showPetSelection = false
    @State private var showPetNaming = false
    @State private var showTutorial = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            if showWelcome {
                welcomeView
            } else if showPetSelection {
                petSelectionView
            } else if showPetNaming {
                petNamingView
            } else if showTutorial {
                tutorialView
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: showWelcome)
        .animation(.easeInOut, value: showPetSelection)
        .animation(.easeInOut, value: showPetNaming)
        .animation(.easeInOut, value: showTutorial)
    }
    
    // MARK: - Welcome View
    var welcomeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("PetopiaLaunch")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            Text("Welcome to Petopia!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your virtual pet awaits! Create your new friend and begin your adventure together.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showWelcome = false
                    showPetSelection = true
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Pet Selection View
    var petSelectionView: some View {
        VStack {
            Text("Choose Your Pet")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("What type of pet would you like to care for?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
            
            // Pet options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(PetType.allCases, id: \.self) { petType in
                    PetSelectionCard(
                        petType: petType,
                        isSelected: viewModel.selectedPetType == petType,
                        action: {
                            viewModel.selectedPetType = petType
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showPetSelection = false
                    showPetNaming = true
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 50)
                    .background(viewModel.selectedPetType != nil ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(viewModel.selectedPetType == nil)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Pet Naming View
    var petNamingView: some View {
        VStack {
            Text("Name Your Pet")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("What would you like to name your new \(viewModel.selectedPetType?.rawValue ?? "pet")?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                if let petType = viewModel.selectedPetType {
                    Image(petType.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                }
            }
            .padding(.bottom, 30)
            
            TextField("Enter pet name", text: $viewModel.petName)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showPetNaming = false
                    showTutorial = true
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 50)
                    .background(!viewModel.petName.isEmpty ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(viewModel.petName.isEmpty)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Tutorial View
    var tutorialView: some View {
        VStack {
            Text("How to Play")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 30)
            
            TabView {
                // Tutorial Page 1: Caring for your pet
                TutorialPage(
                    title: "Caring for Your Pet",
                    description: "Feed, clean, and play with your pet regularly to keep them happy and healthy.",
                    imageName: "heart.fill",
                    backgroundColor: Color.pink.opacity(0.2)
                )
                
                // Tutorial Page 2: Growing your pet
                TutorialPage(
                    title: "Watch Your Pet Grow",
                    description: "Your pet will evolve through different stages as they level up.",
                    imageName: "arrow.up.forward",
                    backgroundColor: Color.green.opacity(0.2)
                )
                
                // Tutorial Page 3: Earning currency
                TutorialPage(
                    title: "Earn Currency",
                    description: "Play minigames and complete daily activities to earn coins for buying items.",
                    imageName: "dollarsign.circle",
                    backgroundColor: Color.yellow.opacity(0.2)
                )
                
                // Tutorial Page 4: Achievements
                TutorialPage(
                    title: "Collect Achievements",
                    description: "Complete special tasks to unlock achievements and earn rewards.",
                    imageName: "trophy.fill",
                    backgroundColor: Color.purple.opacity(0.2)
                )
                
                // Final Page
                VStack(spacing: 25) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.red)
                    
                    Text("You're Ready!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your journey with \(viewModel.petName) begins now.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.createPet()
                        viewModel.completeOnboarding()
                    }) {
                        Text("Start Playing")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 220, height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal, 30)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

// MARK: - Supporting Views
struct PetSelectionCard: View {
    let petType: PetType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(petType.rawValue)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(isSelected ? .blue : .gray)
                        .frame(width: 80, height: 80)
                }
                
                Text(petType.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct TutorialPage: View {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 30)
        .background(backgroundColor)
        .cornerRadius(20)
        .padding(.horizontal, 30)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: OnboardingViewModel())
    }
}
