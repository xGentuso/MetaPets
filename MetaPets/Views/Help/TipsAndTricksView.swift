//
//  TipsAndTricksView.swift
//  Petopia
//
//  Created for Petopia
//

import SwiftUI

struct TipsAndTricksView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory = "Basics"
    
    let categories = ["Basics", "Stats", "Activities", "Growth", "Economy"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Categories selector
                Picker("Select Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tips content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(tipsForCategory(selectedCategory), id: \.title) { tip in
                            TipCard(tip: tip)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Tips & Tricks")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Return tips for the selected category
    private func tipsForCategory(_ category: String) -> [Tip] {
        switch category {
        case "Basics":
            return [
                Tip(title: "Check Stats Regularly",
                    description: "Keep an eye on your pet's hunger, happiness, health, cleanliness, and energy to ensure they're well cared for.",
                    icon: "chart.bar.fill"),
                
                Tip(title: "Follow Status Indicators",
                    description: "The emoji above your pet indicates their current primary need. Address this first!",
                    icon: "face.smiling.fill"),
                
                Tip(title: "Use Quick Actions",
                    description: "The buttons at the bottom of the Pet screen provide quick access to common care actions.",
                    icon: "bolt.fill")
            ]
        case "Stats":
            return [
                Tip(title: "Balanced Stats",
                    description: "Try to keep all stats above 50% for optimal pet happiness and health.",
                    icon: "scale.3d"),
                
                Tip(title: "Health Priority",
                    description: "Health decreases faster when other stats are low, so address hunger and cleanliness promptly.",
                    icon: "heart.fill"),
                
                Tip(title: "Energy Management",
                    description: "Playing games costs energy, but sleeping will restore it. Balance activity and rest.",
                    icon: "bolt.fill")
            ]
        case "Activities":
            return [
                Tip(title: "Daily Bonuses",
                    description: "Don't forget to claim your daily bonus! The rewards increase with consecutive logins.",
                    icon: "gift.fill"),
                
                Tip(title: "Minigames",
                    description: "Play minigames to earn currency. Higher difficulty levels offer better rewards.",
                    icon: "gamecontroller.fill"),
                
                Tip(title: "Cooldown Periods",
                    description: "Minigames have cooldown periods before you can play them again.",
                    icon: "clock.fill")
            ]
        case "Growth":
            return [
                Tip(title: "Leveling Up",
                    description: "Your pet gains experience from all care activities. Higher levels unlock new accessories.",
                    icon: "arrow.up.circle.fill"),
                
                Tip(title: "Evolution Stages",
                    description: "Your pet will evolve at levels 5, 10, and 15, changing their appearance and abilities.",
                    icon: "arrow.triangle.2.circlepath"),
                
                Tip(title: "Long-term Care",
                    description: "Consistent care over time leads to better pet development and special achievements.",
                    icon: "calendar.badge.clock")
            ]
        case "Economy":
            return [
                Tip(title: "Currency Sources",
                    description: "Earn currency from daily activities, minigames, and regular pet care actions.",
                    icon: "dollarsign.circle"),
                
                Tip(title: "Strategic Purchases",
                    description: "Save for accessories that provide stat bonuses rather than just cosmetic effects.",
                    icon: "cart.fill"),
                
                Tip(title: "Streak Bonuses",
                    description: "Maintain your daily login streak for increasingly valuable rewards.",
                    icon: "calendar.badge.plus")
            ]
        default:
            return []
        }
    }
}

struct Tip {
    let title: String
    let description: String
    let icon: String
}

struct TipCard: View {
    let tip: Tip
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: tip.icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(tip.title)
                    .font(.headline)
                
                Text(tip.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TipsAndTricksView_Previews: PreviewProvider {
    static var previews: some View {
        TipsAndTricksView()
    }
}
