import SwiftUI

struct DailyBonusView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var isCollecting = false
    @State private var showConfetti = false
    
    // Bonus tiers based on streak length
    private let bonusTiers = [
        1: 10,  // Day 1: 10 coins
        2: 15,  // Day 2: 15 coins
        3: 20,  // Day 3: 20 coins
        4: 25,  // Day 4: 25 coins
        5: 35,  // Day 5: 35 coins
        6: 45,  // Day 6: 45 coins
        7: 60   // Day 7+: 60 coins
    ]
    
    // Max tier for UI display
    private let maxTier = 7
    
    // Calculate today's bonus amount
    private var todaysBonus: Int {
        let streak = min(max(viewModel.dailyBonusStreak, 0) + 1, 7)
        return bonusTiers[streak] ?? bonusTiers[7]!
    }
    
    // Check if bonus is available
    private var isBonusAvailable: Bool {
        if let lastDate = viewModel.lastDailyBonusDate {
            // Check if the last bonus was claimed on a different calendar day
            return !Calendar.current.isDate(lastDate, inSameDayAs: Date())
        }
        return true // First time user, bonus is available
    }
    
    // Time until next bonus
    private var timeUntilNextBonus: String {
        guard let lastDate = viewModel.lastDailyBonusDate else {
            return "Now" // No previous claim
        }
        
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: lastDate) {
            let components = calendar.dateComponents([.hour, .minute], from: Date(), to: tomorrow)
            let hours = components.hour ?? 0
            let minutes = components.minute ?? 0
            
            if hours < 0 || minutes < 0 {
                return "Now" // Available now (past midnight)
            }
            
            return String(format: "%02d:%02d", hours, minutes)
        }
        
        return "Soon"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Daily Bonus")
                .font(.title2)
                .fontWeight(.bold)
            
            // Current streak
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Current streak: \(viewModel.dailyBonusStreak) days")
                    .fontWeight(.medium)
            }
            .padding(.bottom, 5)
            
            // Bonus progression
            VStack(spacing: 8) {
                ForEach(1...maxTier, id: \.self) { day in
                    HStack {
                        // Streak marker
                        ZStack {
                            Circle()
                                .fill(day <= viewModel.dailyBonusStreak + 1 
                                     ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                            
                            if day <= viewModel.dailyBonusStreak {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            } else if day == viewModel.dailyBonusStreak + 1 {
                                Text("\(day)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else {
                                Text("\(day)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Reward description
                        Text("Day \(day)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        // Bonus amount
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.yellow)
                            Text("\(bonusTiers[day] ?? 0)")
                                .fontWeight(day == viewModel.dailyBonusStreak + 1 ? .bold : .regular)
                        }
                        .opacity(day <= viewModel.dailyBonusStreak + 1 ? 1.0 : 0.5)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(day == viewModel.dailyBonusStreak + 1 
                               ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 10)
            
            Spacer()
            
            // Claim button
            VStack(spacing: 6) {
                if isBonusAvailable {
                    Button(action: claimBonus) {
                        HStack {
                            Image(systemName: "gift.fill")
                            Text("Claim \(todaysBonus) Coins")
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.yellow)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isCollecting)
                } else {
                    // Next bonus counter
                    VStack(spacing: 4) {
                        Text("Next bonus available in:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(timeUntilNextBonus)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Additional message
                if viewModel.dailyBonusStreak >= 6 {
                    Text("Maximum streak bonus achieved!")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Come back tomorrow for a bigger bonus!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            ZStack {
                if showConfetti {
                    // Simple confetti effect
                    ForEach(0..<20) { i in
                        Circle()
                            .fill(confettiColor(for: i))
                            .frame(width: CGFloat.random(in: 5...15))
                            .position(
                                x: CGFloat.random(in: 0...300),
                                y: CGFloat.random(in: -50...500)
                            )
                            .animation(
                                Animation.easeOut(duration: 1)
                                    .delay(Double.random(in: 0...0.3)),
                                value: showConfetti
                            )
                    }
                }
            }
        )
    }
    
    // Claim the daily bonus
    private func claimBonus() {
        isCollecting = true
        
        // Animate button press
        withAnimation(.spring()) {
            // Add the bonus to currency
            viewModel.pet.currency += todaysBonus
            
            // Update streak counter
            if let lastDate = viewModel.lastDailyBonusDate, 
               Calendar.current.isDateInYesterday(lastDate) {
                viewModel.dailyBonusStreak += 1
            } else if viewModel.lastDailyBonusDate == nil || 
                     !Calendar.current.isDateInYesterday(viewModel.lastDailyBonusDate!) {
                viewModel.dailyBonusStreak = 1
            }
            
            // Update last claimed date
            viewModel.lastDailyBonusDate = Date()
            
            // Show confetti
            showConfetti = true
            
            // Save data
            AppDataManager.shared.saveAllData(viewModel: viewModel)
        }
        
        // Reset state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showConfetti = false
            isCollecting = false
        }
    }
    
    // Get a random confetti color
    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors[index % colors.count]
    }
}

struct DailyBonusView_Previews: PreviewProvider {
    static var previews: some View {
        DailyBonusView(viewModel: PetViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 