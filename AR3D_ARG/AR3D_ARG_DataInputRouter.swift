//
//  FetchDataSetsModels.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 1/10/2025.
//
import SwiftUI

class DataInputHandler {
    let dataSetManager: DataSetManager

    init(dataSetManager: DataSetManager) {
        self.dataSetManager = dataSetManager
    }

    func handle(_ input: String, completion: @escaping (String?) -> Void) {
        dataSetManager.errorMessage = nil
        dataSetManager.isLoading = true

        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.lowercased().hasPrefix("gen ") {
            handleSynthetic(trimmed, completion: completion)
        } else {
            handleRemote(trimmed, completion: completion)
        }
    }

    func handleRemote(_ trimmed: String, completion: @escaping (String?) -> Void) {
        NetworkManager.shared.fetchJSON(from: trimmed) { result in
            switch result {
            case .success(let jsonData):
                self.store(jsonData, using: self.dataSetManager.storeJSON, format: "JSON", completion: completion)
            case .failure(let error):
                self.dataSetManager.isLoading = false
                self.dataSetManager.errorMessage = "Download failed: \(error.message)"
                completion(nil)
            }
        }
    }

    func store(
        _ data: Data,
        using storeMethod: (Data) -> Result<DataSet, NetworkError>,
        format: String,
        completion: @escaping (String?) -> Void
    ) {
        self.dataSetManager.isLoading = false
        switch storeMethod(data) {
        case .success(let dataSet):
            self.dataSetManager.addDataset(dataSet)
            completion("✅\n\(format) dataset '\(dataSet.name)' downloaded and saved.")
        case .failure(let error):
            self.dataSetManager.errorMessage = error.message
            completion(nil)
        }
    }

    private func handleSynthetic(_ trimmed: String, completion: @escaping (String?) -> Void) {
        let components = trimmed.split(separator: " ")
        guard components.count == 2, let count = Int(components[1]) else {
            dataSetManager.isLoading = false
            dataSetManager.errorMessage = "Invalid format. Use 'Gen <number>' to generate synthetic data."
            completion(nil)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.dataSetManager.generateSyntheticDataset(recordCount: count)
            DispatchQueue.main.async {
                self.dataSetManager.isLoading = false
                switch result {
                case .success(let dataSet):
                    self.dataSetManager.addDataset(dataSet)
                    completion("✅\nSynthetic dataset '\(dataSet.name)' saved successfully.")
                case .failure(let error):
                    self.dataSetManager.errorMessage = "Synthetic generation failed: \(error.localizedDescription)"
                    completion(nil)
                }
            }
        }
    }
}


class ExtendedDataInputHandler: DataInputHandler {
    override func handleRemote(_ trimmed: String, completion: @escaping (String?) -> Void) {
        print("🔧 Extended remote handling logic")

        // First try JSON via base class
        super.handleRemote(trimmed) { message in
            if message != nil {
                completion(message)
            } else {
                // JSON failed → try CSV
                NetworkManager.shared.fetchCSV(from: trimmed) { csvResult in
                    switch csvResult {
                    case .success(let csvData):
                        self.store(csvData, using: self.dataSetManager.storeCSV, format: "CSV", completion: completion)

                    case .failure:
                        // CSV failed → try RESTful
                        NetworkManager.shared.fetchREST(from: trimmed) { restResult in
                            switch restResult {
                            case .success(let restData):
                                self.store(restData, using: self.dataSetManager.storeREST, format: "RESTful", completion: completion)
                            case .failure(let error):
                                self.dataSetManager.isLoading = false
                                self.dataSetManager.errorMessage = "Download failed: \(error.message)"
                                completion(nil)
                            }
                        }
                    }
                }
            }
        }
    }
}


