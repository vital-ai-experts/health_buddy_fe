//
//  SplashView.swift
//  ThriveBody
//
//  Created by Claude on 2025/10/22.
//

import SwiftUI
import ThemeKit

struct SplashView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

            BreathingDotView()
                .padding(.trailing, -12)
                .padding(.bottom, 100)
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
