//
//  SelectDataSetsViewModels.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 5/9/2025.
//
import SwiftUI

enum GenerationError: Error {
    case streamFailed
    case encodingFailed(index: Int)

    var localizedDescription: String {
        switch self {
        case .streamFailed:
            return "Failed to open file stream for writing."
        case .encodingFailed(let index):
            return "Failed to encode record at index \(index)."
        }
    }
}

struct DataSet: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let fileURL: URL
    var isFullyLoaded: Bool
}

class DataSetManager: ObservableObject {
    @Published var dataSets: [DataSet] = []
    @Published var selectedIDs: Set<UUID> = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // ✅ Inject rule-based validator
    private let validator = BaseJSONValidator(rules: [
        Rule2NumericFields(),
        Rule3NumericFields(),
        Rule4NumericFields(),
        Rule4NumericFieldsPlus1String()
    ])

    func addDataset(_ newDataSet: DataSet) {
        guard !dataSets.contains(where: { $0.name.lowercased() == newDataSet.name.lowercased() }) else {
            print("⚠️ Dataset \"\(newDataSet.name)\" already exists. Skipping.")
            return
        }
        dataSets.insert(newDataSet, at: 0)
    }

    func removeDataset(_ dataSet: DataSet) {
        dataSets.removeAll { $0.id == dataSet.id }
    }

    private func existingStoredNames() throws -> [String] {
        let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        let jsonFiles = files.filter { $0.pathExtension == "json" }

        var names: [String] = []

        for file in jsonFiles {
            let data = try Data(contentsOf: file)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["name"] as? String {
                names.append(name)
            }
        }

        return names
    }

    func generateSyntheticDataset(recordCount: Int) -> Result<DataSet, Error> {
        let conditions = ["ns", "M+", "M+F+", "F+", "L+F+", "L+", "L+M+"]
        let timestamp = Int(Date().timeIntervalSince1970)
        let datasetName = "SyntheticCellSignatures_\(timestamp)"
        let description = "Simulated cell signature data with 3 numeric dimensions and 1 categorical label, including negative values."
        let fileName = "\(datasetName).json"
        let finalURL = documentsURL.appendingPathComponent(fileName)

        var records: [[String: Any]] = []

        for i in 0..<recordCount {
            let condition = conditions[i % conditions.count]

            let lymphoid: Double
            let myeloid: Double
            let pValue: Double

            switch condition {
            case "L+", "L+F+", "L+M+":
                lymphoid = Double.random(in: -0.2...1.0)
                myeloid = Double.random(in: -0.2...0.4)
            case "M+", "M+F+":
                lymphoid = Double.random(in: -0.2...0.4)
                myeloid = Double.random(in: -0.2...1.0)
            case "F+":
                lymphoid = Double.random(in: -0.3...0.6)
                myeloid = Double.random(in: -0.3...0.6)
            default:
                lymphoid = Double.random(in: -0.5...0.7)
                myeloid = Double.random(in: -0.5...0.7)
            }

            pValue = Double.random(in: 0.0001...0.05)

            let record: [String: Any] = [
                "lymphoid": lymphoid,
                "myeloid": myeloid,
                "-log10P": -log10(pValue),
                "condition": condition
            ]

            records.append(record)
        }

        let jsonRoot: [String: Any] = [
            "name": datasetName,
            "description": description,
            "data": records
        ]

        do {
            let fullData = try JSONSerialization.data(withJSONObject: jsonRoot, options: [.prettyPrinted])
            try fullData.write(to: finalURL)

            let dataSet = DataSet(
                id: UUID(),
                name: datasetName,
                description: description,
                fileURL: finalURL,
                isFullyLoaded: false
            )

            return .success(dataSet)
        } catch {
            return .failure(error)
        }
    }

    func storeCSV(_ data: Data) -> Result<DataSet, NetworkError> {
        return .failure(.parsingFailed("CSV parsing not yet implemented."))
    }

    func storeREST(_ data: Data) -> Result<DataSet, NetworkError> {
        return .failure(.parsingFailed("RESTful response parsing not yet implemented."))
    }

    func storeJSON(_ data: Data) -> Result<DataSet, NetworkError> {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(.parsingFailed("File is not valid JSON."))
            }

            switch validator.validate(json) {
            case .failure(let validationError):
                return .failure(.parsingFailed("Validation failed: \(validationError.localizedDescription)"))
            case .success:
                break
            }

            guard let name = json["name"] as? String,
                  let description = json["description"] as? String else {
                return .failure(.parsingFailed("Missing 'name' or 'description' fields."))
            }

            let existingNames = try existingStoredNames()
            if existingNames.contains(where: { $0.lowercased() == name.lowercased() }) {
                return .failure(.duplicateName("Dataset \"\(name)\" already exists."))
            }

            let fileURL = documentsURL.appendingPathComponent("\(name).json")
            try data.write(to: fileURL)

            let dataSet = DataSet(
                id: UUID(),
                name: name,
                description: description,
                fileURL: fileURL,
                isFullyLoaded: false
            )

            return .success(dataSet)

        } catch {
            return .failure(.parsingFailed("Failed to parse JSON: \(error.localizedDescription)"))
        }
    }

    func loadFromDisk() {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }

            var loaded: [DataSet] = []

            for file in jsonFiles {
                let data = try Data(contentsOf: file)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let name = json["name"] as? String,
                      let description = json["description"] as? String else {
                    continue
                }

                let dataSet = DataSet(
                    id: UUID(),
                    name: name,
                    description: description,
                    fileURL: file,
                    isFullyLoaded: false
                )
                loaded.append(dataSet)
            }

            dataSets = loaded
        } catch {
            errorMessage = "Failed to load datasets: \(error.localizedDescription)"
        }
    }

    func delete(_ dataSet: DataSet) {
        do {
            try fileManager.removeItem(at: dataSet.fileURL)
            selectedIDs.remove(dataSet.id)
            loadFromDisk()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }

    func toggleSelection(for id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else if selectedIDs.count < 4 {
            selectedIDs.insert(id)
        } else {
            errorMessage = "You can select up to 4 datasets only."
        }
    }
}

struct DataSetStringDecimal_2 {
    var id: UUID = UUID()
    let name: String
    let description: String
    let data: [DataPointStringDecimal_2]
}

struct DataSetStringDecimal_3 {
    var id: UUID = UUID()
    let name: String
    let description: String
    let data: [DataPointStringDecimal_3]
}

struct DataPointStringDecimal_2 {
    let category: String
    let value1: Double
    let value2: Double
}

struct DataPointStringDecimal_3 {
    let category: String
    let value1: Decimal
    let value2: Decimal
    let value3: Decimal
}
struct DataPointStringDecimal_4 {
    let category: String
    let value1: Decimal
    let value2: Decimal
    let value3: Decimal
    let value4: Decimal
}

struct DataSetStringDecimal_4 {
    var id: UUID = UUID()
    let name: String
    let description: String
    let data: [DataPointStringDecimal_4]
}

struct DataPointStringDecimal_4Plus1 {
    let category: String
    let value1: Decimal
    let value2: Decimal
    let value3: Decimal
    let value4: Decimal
    let extra: String
}

struct DataSetStringDecimal_4Plus1 {
    let name: String
    let description: String
    let data: [DataPointStringDecimal_4Plus1]
}

enum ValidatedDataSet {
    case dataSetStringDecimal_2(DataSetStringDecimal_2)
    case dataSetStringDecimal_3(DataSetStringDecimal_3)
    case dataSetStringDecimal_4(DataSetStringDecimal_4)
    case dataSetStringDecimal_4Plus1(DataSetStringDecimal_4Plus1)
}

