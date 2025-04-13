//
//  AchievementsView.swift
//  Petopia
//
//  Created for Petopia achievement system
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject var viewModel: PetViewModel
    @ObservedObject private var achievementManager = AchievementManager.shared
    @State private var selectedCategory: AchievementCategory?
    @State private var selectedAchievement: Achievement?
    @State private var showDetailSheet = false
    @State private var animateUnlocks = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with currency badge
                HStack {
                    Text("Achievements")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    CurrencyBadge(amount: viewModel.pet.currency)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Stats summary
                achievementSummary
                    .padding(.top, 5)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    categoryFilters
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Achievement list
                if filteredAchievements.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementCell(achievement: achievement)
                                    .onTapGesture {
                                        selectedAchievement = achievement
                                        showDetailSheet = true
                                    }
                                    .opacity(shouldShow(achievement) ? 1 : 0.6)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDetailSheet) {
                if let achievement = selectedAchievement {
                    AchievementDetailView(achievement: achievement)
                }
            }
            .overlay(
                unlockedAchievementToast
                    .opacity(animateUnlocks && !achievementManager.recentlyUnlocked.isEmpty ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: animateUnlocks)
            )
            .onAppear {
                // Animate recent unlocks after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateUnlocks = true
                    
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        animateUnlocks = false
                        
                        // Clear after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            achievementManager.clearRecentlyUnlocked()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var achievementSummary: some View {
        HStack(spacing: 20) {
            // Bronze count
            StatisticView(
                title: "Bronze",
                value: "\(achievementManager.getAchievements(difficulty: .bronze).filter { $0.isUnlocked }.count)/\(achievementManager.getAchievements(difficulty: .bronze).count)",
                color: AchievementDifficulty.bronze.color
            )
            
            // Silver count
            StatisticView(
                title: "Silver",
                value: "\(achievementManager.getAchievements(difficulty: .silver).filter { $0.isUnlocked }.count)/\(achievementManager.getAchievements(difficulty: .silver).count)",
                color: AchievementDifficulty.silver.color
            )
            
            // Gold count
            StatisticView(
                title: "Gold",
                value: "\(achievementManager.getAchievements(difficulty: .gold).filter { $0.isUnlocked }.count)/\(achievementManager.getAchievements(difficulty: .gold).count)",
                color: AchievementDifficulty.gold.color
            )
            
            // Platinum count
            StatisticView(
                title: "Platinum",
                value: "\(achievementManager.getAchievements(difficulty: .platinum).filter { $0.isUnlocked }.count)/\(achievementManager.getAchievements(difficulty: .platinum).count)",
                color: AchievementDifficulty.platinum.color
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var categoryFilters: some View {
        HStack(spacing: 12) {
            CategoryButton(
                title: "All",
                isSelected: selectedCategory == nil,
                color: .gray
            ) {
                selectedCategory = nil
            }
            
            ForEach(AchievementCategory.allCases, id: \.self) { category in
                CategoryButton(
                    title: category.displayName,
                    isSelected: selectedCategory == category,
                    color: category.themeColor
                ) {
                    selectedCategory = category
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No achievements in this category")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
    }
    
    private var unlockedAchievementToast: some View {
        VStack {
            if let achievement = achievementManager.recentlyUnlocked.first {
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28))
                        .foregroundColor(achievement.difficulty.color)
                    
                    Text("Achievement Unlocked!")
                        .font(.headline)
                    
                    Text(achievement.title)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                    
                    Text("+\(achievement.rewardAmount) coins")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 100)
    }
    
    // MARK: - Helper Methods
    
    // Filter achievements based on selected category
    private var filteredAchievements: [Achievement] {
        let achievements = achievementManager.getAchievements(for: selectedCategory)
        
        // Sort by unlocked status, then by difficulty
        return achievements.sorted {
            if $0.isUnlocked && !$1.isUnlocked {
                return false
            } else if !$0.isUnlocked && $1.isUnlocked {
                return true
            } else {
                return difficultyRank($0.difficulty) < difficultyRank($1.difficulty)
            }
        }
    }
    
    // Helper for sorting by difficulty
    private func difficultyRank(_ difficulty: AchievementDifficulty) -> Int {
        switch difficulty {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .platinum: return 3
        }
    }
    
    // Determine if an achievement should be fully visible
    private func shouldShow(_ achievement: Achievement) -> Bool {
        return achievement.isUnlocked || !achievement.hidden
    }
}

// MARK: - Supporting Views

// Cell for displaying an achievement
struct AchievementCell: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 15) {
            // Medal icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.difficulty.color : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.isUnlocked ? "trophy.fill" : "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.isUnlocked || !achievement.hidden ? achievement.title : "Hidden Achievement")
                    .font(.headline)
                
                Text(achievement.isUnlocked || !achievement.hidden ? achievement.description : "Complete special conditions to unlock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Progress bar
                ProgressView(value: achievement.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: achievement.difficulty.color))
                    .frame(height: 5)
                
                // Progress text
                HStack {
                    Text("\(achievement.progress)/\(achievement.goal)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Reward text
                    Text("\(achievement.rewardAmount) coins")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// Achievement detail view (shown in sheet)
struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Close button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                // Trophy icon
                ZStack {
                    Circle()
                        .fill(achievement.difficulty.color.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: achievement.isUnlocked ? "trophy.fill" : "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(achievement.difficulty.color)
                }
                
                // Achievement details
                VStack(spacing: 10) {
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack {
                        Text(achievement.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(achievement.category.themeColor.opacity(0.2))
                            )
                            .foregroundColor(achievement.category.themeColor)
                        
                        Text(achievement.difficulty.displayName)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(achievement.difficulty.color.opacity(0.2))
                            )
                            .foregroundColor(achievement.difficulty.color)
                    }
                }
                .padding(.horizontal)
                
                // Progress section
                VStack(spacing: 12) {
                    Text("Progress")
                        .font(.headline)
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(achievement.difficulty.color)
                            .frame(width: max(15, CGFloat(achievement.progressPercentage) * 300), height: 20)
                        
                        Text("\(Int(achievement.progressPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.leading, 8)
                    }
                    .frame(width: 300)
                    
                    Text("\(achievement.progress)/\(achievement.goal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Reward section
                VStack(spacing: 8) {
                    Text("Reward")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                        
                        Text("\(achievement.rewardAmount) coins")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Unlocked date if applicable
                if let date = achievement.dateUnlocked {
                    VStack {
                        Text("Unlocked on")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(formattedDate(date))
                            .font(.subheadline)
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Category filter button
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? color : .gray)
        }
    }
}

// Statistic summary view
struct StatisticView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(value)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
            }
        }
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView(viewModel: PetViewModel())
    }
}
