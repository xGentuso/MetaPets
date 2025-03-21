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
