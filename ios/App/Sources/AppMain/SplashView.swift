//
//  SplashView.swift
//  ThriveBody
//
//  Created by Claude on 2025/10/22.
//

import SwiftUI

struct SplashView: View {
    @State private var pulse = false
    @State private var glow = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.black,
                    Color(red: 0.01, green: 0.08, blue: 0.05)
                ],
                center: .center,
                startRadius: 40,
                endRadius: 450
            )
            .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulse ? 1.25 : 0.85)
                    .blur(radius: 32)

                Circle()
                    .fill(Color.green.opacity(0.45))
                    .frame(width: 90, height: 90)
                    .scaleEffect(glow ? 1.08 : 0.94)
                    .blur(radius: 12)

                Circle()
                    .fill(Color.green)
                    .frame(width: 34, height: 34)
                    .shadow(color: Color.green.opacity(0.7), radius: 26)
            }
            .scaleEffect(glow ? 1.02 : 0.98)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.2)
                    .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }

            withAnimation(
                .easeInOut(duration: 1.6)
                    .repeatForever(autoreverses: true)
                    .delay(0.4)
            ) {
                glow = true
            }
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
