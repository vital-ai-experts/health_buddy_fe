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

            BreathingDotView(configuration: .splash)
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
