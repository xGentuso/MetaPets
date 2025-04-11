//
//  DailiesView.swift
//  Petopia
//
//  Created for Petopia dailies system
//

import SwiftUI

struct DailiesView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var dailyActivities: [DailyActivity] = []
    @State private var selectedActivity: DailyActivity?
    @State private var showingActivitySheet = false
    @State private var showRewardAlert = false
    @State private var currentReward = 0
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Header with currency badge
                    HStack {
                        Text("Daily Activities")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        CurrencyBadge(amount: viewModel.pet.currency)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Section title
                    HStack {
                        Text("Available Today")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Refresh button
                        Button(action: {
                            loadActivities()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    if isLoading {
                        // Loading indicator
                        ProgressView()
                            .padding()
                    } else if dailyActivities.isEmpty {
                        // Empty state
                        VStack(spacing: 15) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("You've completed all activities today!")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Come back tomorrow for more rewards")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else {
                        // List of daily activities
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(dailyActivities) { activity in
                                    DailyActivityCard(activity: activity)
                                        .onTapGesture {
                                            selectedActivity = activity
                                            showingActivitySheet = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                    }
                    
                    Spacer()
                    
                    // Info text at bottom
                    Text("Activities reset daily at midnight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .onAppear {
                loadActivities()
            }
            .sheet(isPresented: $showingActivitySheet) {
                if let activity = selectedActivity {
                    if activity.type == .wheel {
                        // Use our new interactive spinning wheel view
                        SpinningWheelView(
                            viewModel: viewModel,
                            activity: activity,
                            showingActivity: $showingActivitySheet,
                            onComplete: { reward in
                                // Handle the returned reward
                                currentReward = reward
                                loadActivities() // Refresh the list after completion
                                showRewardAlert = true
                            }
                        )
                    } else if activity.type == .treasureChest {
                        // Use our new treasure chest view
                        TreasureChestView(
                            viewModel: viewModel,
                            activity: activity,
                            showingActivity: $showingActivitySheet,
                            onComplete: { reward in
                                currentReward = reward
                                loadActivities() // Refresh the list after completion
                                showRewardAlert = true
                            }
                        )
                    } else {
                        // Use existing generic view for other activities
                        DailyActivityDetailView(
                            activity: activity,
                            isPresented: $showingActivitySheet,
                            onComplete: { reward in
                                currentReward = reward
                                viewModel.earnCurrency(amount: reward, description: "Completed daily activity: \(activity.name)")
                                loadActivities() // Refresh the list
                                showRewardAlert = true
                            }
                        )
                    }
                }
            }
            .alert(isPresented: $showRewardAlert) {
                Alert(
                    title: Text("Reward Collected!"),
                    message: Text("You received \(currentReward) coins from this activity."),
                    dismissButton: .default(Text("Nice!"))
                )
            }
        }
    }
    
    private func loadActivities() {
        isLoading = true
        
        // Small delay to make the loading state visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dailyActivities = DailiesManager.shared.getAvailableActivities()
            isLoading = false
        }
    }
}

// Card view for a daily activity
struct DailyActivityCard: View {
    let activity: DailyActivity
    
    var body: some View {
        HStack(spacing: 15) {
            // Activity icon
            Image(systemName: activity.type.systemImageName)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(activityColor(for: activity.type))
                .cornerRadius(12)
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Reward range
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text("\(activity.minReward)-\(activity.maxReward) coins")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .bold))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Color for each activity type
    private func activityColor(for type: DailyActivityType) -> Color {
        switch type {
        case .treasureChest: return .orange
        case .wheel: return .blue
        case .mysteryBox: return .purple
        case .foodBowl: return .green
        case .petRock: return .gray
        }
    }
}

// Detail view for an activity (shown in sheet)
struct DailyActivityDetailView: View {
    let activity: DailyActivity
    @Binding var isPresented: Bool
    let onComplete: (Int) -> Void
    
    @State private var isAnimating = false
    @State private var showReward = false
    @State private var reward = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with close button
            HStack {
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Spacer()
            
            // Activity visualization
            ZStack {
                if showReward {
                    // Reward view
                    VStack(spacing: 15) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Text("\(reward) Coins!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Button(action: {
                            // Pass reward back to parent and close sheet
                            onComplete(reward)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isPresented = false
                            }
                        }) {
                            Text("Collect Reward")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(12)
                                .padding(.horizontal, 50)
                        }
                    }
                } else {
                    // Activity specific visualization
                    activityVisualization()
                }
            }
            .frame(height: 300)
            
            Spacer()
            
            // Activity title and description
            VStack(spacing: 10) {
                Text(activity.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(activity.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action button
            if !showReward {
                Button(action: {
                    activateReward()
                }) {
                    Text(actionText())
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 50)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    // Action text based on activity type
    private func actionText() -> String {
        switch activity.type {
        case .treasureChest: return "Open Chest"
        case .wheel: return "Spin Wheel"
        case .mysteryBox: return "Open Box"
        case .foodBowl: return "Collect Food"
        case .petRock: return "Visit Pet Rock"
        }
    }
    
    // Activity visualization based on type
    @ViewBuilder
    private func activityVisualization() -> some View {
        switch activity.type {
        case .treasureChest:
            Image(systemName: "cube.box.fill")
                .font(.system(size: 100))
                .foregroundColor(.orange)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            
        case .wheel:
            Image(systemName: "dial.medium")
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 3)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
        case .mysteryBox:
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 100))
                .foregroundColor(.purple)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            
        case .foodBowl:
            Image(systemName: "bowl.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            
        case .petRock:
            Image(systemName: "fossil.shell.fill")
                .font(.system(size: 100))
                .foregroundColor(.gray)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    // Generate a random reward and show it
    private func activateReward() {
        // Generate a random reward amount
        reward = Int.random(in: activity.minReward...activity.maxReward)
        
        // Animate the transition to reward view
        withAnimation(.spring()) {
            showReward = true
        }
    }
}

struct DailiesView_Previews: PreviewProvider {
    static var previews: some View {
        DailiesView(viewModel: PetViewModel())
    }
}
