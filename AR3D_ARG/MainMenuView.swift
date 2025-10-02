//
//  MainMenuView.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 22/9/2025.
//
import SwiftUI

struct MainMenuView: View {
    let navigateToLocalFiles: () -> Void
    let navigateToAPI: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Button("Local Files") {
                navigateToLocalFiles()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button("API Connection") {
                navigateToAPI()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        //.navigationTitle("Main Menu")
    }
}
