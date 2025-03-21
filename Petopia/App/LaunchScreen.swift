//
//  LaunchScreen.swift
//  Petopia
//
//  Created for Petopia
//

import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var logoScale = 0.8
    
    var body: some View {
        ZStack {
            // Background gradient for more visual appeal
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(#colorLiteral(red: 0.9, green: 0.95, blue: 1, alpha: 1))]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Subtle background pattern
            VStack {
                ForEach(0..<20) { i in
                    HStack {
                        ForEach(0..<10) { j in
                            Circle()
                                .fill(Color.blue.opacity(0.03))
                                .frame(width: 15, height: 15)
                        }
                    }
                }
            }
            .rotationEffect(.degrees(45))
            .offset(y: isAnimating ? 0 : 500)
            .animation(.easeInOut(duration: 2).delay(0.2), value: isAnimating)
            
            VStack(spacing: 30) {
                // Logo with shadow and enhanced animation
                Image("PetopiaLaunch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .scaleEffect(logoScale)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: logoScale)
                
                VStack(spacing: 15) {
                    // Tagline with a slightly larger font and softer color
                    Text("Your virtual pet awaits!")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.8))
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeIn(duration: 0.8).delay(0.7), value: isAnimating)
                    
                    // Add a decorative element
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.blue.opacity(0.5))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeIn(duration: 0.6).delay(1.0), value: isAnimating)
                }
            }
            
            // Version number at the bottom for professional touch
            VStack {
                Spacer()
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(Color.gray.opacity(0.6))
                    .padding(.bottom, 10)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(1.2), value: isAnimating)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = true
                logoScale = 1.0
            }
        }
    }
}

struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
