import SwiftUI

struct TreasureChestView: View {
    @ObservedObject var viewModel: PetViewModel
    let activity: DailyActivity
    @Binding var showingActivity: Bool
    var onComplete: ((Int) -> Void)? = nil
    
    @State private var isOpening = false
    @State private var showReward = false
    @State private var reward = 0
    @State private var showParticles = false
    @State private var particleOffset: CGSize = .zero
    
    // Particle system states
    @State private var particles: [(id: Int, offset: CGSize, scale: Double)] = []
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Treasure Chest")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Treasure chest
                ZStack {
                    // Chest base
                    Image(systemName: "cube.box.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brown, .orange.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                        .overlay(
                            // Chest lid
                            Image(systemName: "cube.box.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 100)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .brown],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .rotationEffect(.degrees(isOpening ? -60 : 0), anchor: .top)
                                .offset(y: -50)
                        )
                    
                    // Lock
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                        .opacity(isOpening ? 0 : 1)
                        .offset(y: 20)
                    
                    // Particles
                    ForEach(particles, id: \.id) { particle in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .offset(particle.offset)
                            .scaleEffect(particle.scale)
                            .opacity(showParticles ? 0 : 1)
                    }
                }
                .scaleEffect(showReward ? 0.8 : 1.0)
                
                Spacer()
                
                // Open button
                Button(action: openChest) {
                    Text(isOpening ? "Opening..." : "Open Chest")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .brown]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5)
                }
                .disabled(isOpening)
                .opacity(isOpening ? 0.5 : 1.0)
            }
            .padding()
            
            // Reward Popup
            if showReward {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                RewardPopupView(
                    reward: reward,
                    onCollect: collectReward,
                    title: "Treasure Found!",
                    backgroundColor: .brown.opacity(0.9)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func openChest() {
        isOpening = true
        
        // Generate random reward
        reward = Int.random(in: activity.minReward...activity.maxReward)
        
        // Create particles
        particles = (0..<12).map { i in
            let angle = Double(i) * (360.0 / 12.0)
            let distance = CGFloat.random(in: 50...150)
            let offset = CGSize(
                width: cos(angle * .pi / 180) * distance,
                height: sin(angle * .pi / 180) * distance
            )
            return (id: i, offset: .zero, scale: 1.0)
        }
        
        // Animate chest opening
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isOpening = true
        }
        
        // Animate particles
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            showParticles = true
            particles = particles.map { particle in
                var new = particle
                new.offset = CGSize(
                    width: cos(Double(particle.id) * (360.0 / 12.0) * .pi / 180) * 150,
                    height: sin(Double(particle.id) * (360.0 / 12.0) * .pi / 180) * 150
                )
                new.scale = 0.1
                return new
            }
        }
        
        // Show reward
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showReward = true
            }
        }
    }
    
    private func collectReward() {
        if let actualReward = DailiesManager.shared.completeActivity(id: activity.id) {
            viewModel.earnCurrency(amount: actualReward, description: "Treasure Chest reward")
            onComplete?(actualReward)
            showingActivity = false
        }
    }
}

struct TreasureChestView_Previews: PreviewProvider {
    static var previews: some View {
        TreasureChestView(
            viewModel: PetViewModel(),
            activity: DailyActivity(
                name: "Treasure Chest",
                description: "Open the chest for rewards",
                imageName: "treasure_chest",
                type: .treasureChest,
                minReward: 20,
                maxReward: 300
            ),
            showingActivity: .constant(true)
        )
    }
} 
