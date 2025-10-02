//
//  FetchDataSetView.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 22/9/2025.
//
import SwiftUI 

struct FetchDataSetView: View {
    @StateObject private var dataSetManager = DataSetManager()
    @State private var inputText: String = "https://raw.githubusercontent.com/Arthur-Woodlee/AR3D_ARG/refs/heads/main/DataSets/MinimumGrowingConditionsForVegetableGrowth.json"
    @State private var confirmationMessage: String? = nil

    var onSelect: ([DataSet]) -> Void

    private var inputHandler: DataInputHandler {
        DataInputHandler(dataSetManager: dataSetManager)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Fetch Dataset")
                .font(.title2)
                .padding(.top)

            TextField("Enter dataset URL or 'Gen <count>'", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Fetch Dataset") {
                confirmationMessage = nil
                inputHandler.handle(inputText) { message in
                    confirmationMessage = message
                }
            }
            .buttonStyle(.borderedProminent)

            if let message = confirmationMessage {
                Text(message)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
            }

            if let error = dataSetManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("API Connection")
    }
}
