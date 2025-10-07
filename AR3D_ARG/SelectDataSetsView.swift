//
//  SelectDataSetsView.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 5/9/2025.
//
import SwiftUI

struct SelectDataSetsView: View {
    @StateObject private var dataSetManager = DataSetManager()
    var navigate: ([DataSet]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let error = dataSetManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            if dataSetManager.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }

            Text("Select one or more datasets to configure.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            List(dataSetManager.dataSets) { dataSet in
                HStack {
                    Image(systemName: dataSetManager.selectedIDs.contains(dataSet.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text(dataSet.name)
                            .font(.headline)
                        Text(dataSet.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if dataSetManager.selectedIDs.contains(dataSet.id) {
                        dataSetManager.selectedIDs.remove(dataSet.id)
                    } else {
                        dataSetManager.selectedIDs.insert(dataSet.id)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        dataSetManager.delete(dataSet)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button("Configure Graphing") {
                let selected = dataSetManager.dataSets.filter { dataSetManager.selectedIDs.contains($0.id) }
                if selected.isEmpty {
                    dataSetManager.errorMessage = "Please select at least one dataset."
                } else {
                    navigate(selected)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            dataSetManager.loadFromDisk()
        }
        //.navigationTitle("Select Data Sets")
    }
}
/*
struct SelectDataSetsView: View {
    @StateObject private var dataSetManager = DataSetManager()
    var navigate: ([DataSet]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let error = dataSetManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            if dataSetManager.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }

            Text("Select one dataset to configure.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            List(dataSetManager.dataSets) { dataSet in
                HStack {
                    Image(systemName: dataSetManager.selectedIDs.contains(dataSet.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text(dataSet.name)
                            .font(.headline)
                        Text(dataSet.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    dataSetManager.selectedIDs = [dataSet.id]
                }
                .swipeActions {
                    Button(role: .destructive) {
                        dataSetManager.delete(dataSet)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button("Configure Graphing") {
                if let selectedID = dataSetManager.selectedIDs.first,
                   let selected = dataSetManager.dataSets.first(where: { $0.id == selectedID }) {
                    navigate([selected])
                } else {
                    dataSetManager.errorMessage = "Please select a dataset."
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            dataSetManager.loadFromDisk()
        }
        //.navigationTitle("Select Data Sets")
    }
}
*/
