import SwiftUI

struct RewardPopupView: View {
    let reward: Int
    let onCollect: () -> Void
    let title: String
    let backgroundColor: Color
    
    init(
        reward: Int,
        onCollect: @escaping () -> Void,
        title: String = "Congratulations!",
        backgroundColor: Color = .blue.opacity(0.9)
    ) {
        self.reward = reward
        self.onCollect = onCollect
        self.title = title
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                
                Text("\(reward)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Button(action: onCollect) {
                Text("Collect")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.5), radius: 10)
        )
    }
} 