import SwiftUI
import Foundation

struct SpinningWheelView: View {
    @ObservedObject var viewModel: PetViewModel
    let activity: DailyActivity
    @Binding var showingActivity: Bool
    var onComplete: ((Int) -> Void)? = nil
    
    @State private var rotation = 0.0
    @State private var isSpinning = false
    @State private var showReward = false
    @State private var winningReward = 0
    
    private let wheelColors: [Color] = [
        .blue, .purple, .green, .orange,
        .pink, .red, .yellow, .teal
    ]
    
    // Reorder rewards to match the visual order (starting from top, going clockwise)
    private let rewards = [75, 100, 150, 200, 250, 300, 20, 50]
    
    var body: some View {
        ZStack {
            // Background
            Color.blue.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Daily Spin")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Wheel Container
                ZStack {
                    // Main wheel background
                    Circle()
                        .fill(Color.white)
                        .frame(width: 300, height: 300)
                        .shadow(color: .black.opacity(0.2), radius: 10)
                    
                    // Wheel segments
                    ForEach(0..<8) { index in
                        let angle = Double(index) * 45.0
                        let colors = [wheelColors[index], wheelColors[index].opacity(0.7)]
                        
                        WheelSegmentShape(startAngle: angle, endAngle: angle + 45)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: colors),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .overlay(
                                WheelSegmentShape(startAngle: angle, endAngle: angle + 45)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .frame(width: 280, height: 280)
                        
                        // Reward display
                        let rewardAngle = angle + 22.5
                        VStack(spacing: 2) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.yellow)
                            Text("\(rewards[index])")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 16))
                        .rotationEffect(.degrees(-rotation))
                        .rotationEffect(.degrees(-rewardAngle))
                        .offset(y: -100)
                        .rotationEffect(.degrees(rewardAngle))
                        .zIndex(1) // Ensure text is always on top
                    }
                    .rotationEffect(.degrees(rotation))
                    
                    // Center decoration
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [.white, .gray.opacity(0.3)]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .shadow(color: .black.opacity(0.2), radius: 2)
                        )
                    
                    // Pointer
                    VStack(spacing: -2) {
                        Triangle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Triangle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .offset(y: -150)
                }
                .frame(height: 320)
                
                Spacer()
                
                // Spin Button
                Button(action: spinWheel) {
                    Text("SPIN")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 150, height: 60)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5)
                }
                .disabled(isSpinning)
                .opacity(isSpinning ? 0.5 : 1.0)
            }
            .padding()
            
            // Reward Popup
            if showReward {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                RewardPopupView(
                    reward: winningReward,
                    onCollect: collectReward,
                    title: "You Won!",
                    backgroundColor: .blue.opacity(0.9)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func spinWheel() {
        isSpinning = true
        let spinDuration = 3.0
        
        // Calculate final rotation
        let additionalSpins = Double.random(in: 2...4) * 360
        let randomAngle = Double.random(in: 0...360)
        let targetRotation = rotation + additionalSpins + randomAngle
        
        // Calculate winning segment
        let normalizedRotation = targetRotation.truncatingRemainder(dividingBy: 360)
        let segmentIndex = Int(floor(normalizedRotation / 45.0)) % 8
        winningReward = rewards[7 - segmentIndex]
        
        withAnimation(.easeInOut(duration: spinDuration)) {
            rotation = targetRotation
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration + 0.2) {
            isSpinning = false
            withAnimation {
                showReward = true
            }
        }
    }
    
    private func collectReward() {
        if let actualReward = DailiesManager.shared.completeActivity(id: activity.id) {
            viewModel.earnCurrency(amount: actualReward, description: "Lucky Wheel reward")
            onComplete?(actualReward)
            showingActivity = false
        }
    }
}

struct WheelSegmentShape: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SpinningWheelView_Previews: PreviewProvider {
    static var previews: some View {
        SpinningWheelView(
            viewModel: PetViewModel(),
            activity: DailyActivity(
                name: "Lucky Wheel",
                description: "Spin the wheel for rewards",
                imageName: "lucky_wheel",
                type: .wheel,
                minReward: 20,
                maxReward: 300
            ),
            showingActivity: .constant(true)
        )
    }
} 