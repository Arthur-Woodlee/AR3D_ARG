//
//  SplashScreenView.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 22/9/2025.
//
import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    let navigateToLocalFiles: () -> Void
    let navigateToAPI: () -> Void

    var body: some View {
        Group {
            if isActive {
                MainMenuView(
                    navigateToLocalFiles: navigateToLocalFiles,
                    navigateToAPI: navigateToAPI
                )
            } else {
                VStack {
                    Spacer()
                    Image("SplashLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(100) // 👈 Rounded corners
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}
