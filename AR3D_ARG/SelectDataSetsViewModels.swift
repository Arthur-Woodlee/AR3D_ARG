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

enum NetworkError: Error {
    case invalidURL
    case downloadFailed(String)
    case noData
    case invalidJSON
    case duplicateName(String)
    case parsingFailed(String)
    case notImplemented(String)

    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL format."
        case .downloadFailed(let msg):
            return "Download error: \(msg)"
        case .noData:
            return "No data received."
        case .invalidJSON:
            return "File is not valid or missing required fields."
        case .duplicateName(let name):
            return "Dataset \"\(name)\" already exists."
        case .parsingFailed(let msg):
            return "Failed to parse JSON: \(msg)"
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func fetchJSON(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed(error.localizedDescription)))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }

            DispatchQueue.main.async {
                completion(.success(data))
            }
        }.resume()
    }

    func fetchCSV(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        completion(.failure(.notImplemented("CSV fetching not yet implemented.")))
    }

    func fetchREST(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        completion(.failure(.notImplemented("RESTful fetching not yet implemented.")))
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

enum JSONValidationError: Error {
    case invalidStructure(String)

    var description: String {
        switch self {
        case .invalidStructure(let message):
            return message
        }
    }
}

protocol ValidationRule {
    var description: String { get }
    func matches(_ objects: [[String: Any]]) -> Bool
    func parse(_ objects: [[String: Any]], name: String, description: String) -> Result<ValidatedDataSet, JSONValidationError>
}

class BaseJSONValidator {
    let rules: [ValidationRule]

    init(rules: [ValidationRule]) {
        self.rules = rules
    }

    func validate(_ json: [String: Any]) -> Result<ValidatedDataSet, JSONValidationError> {
        print("✅ Begin Validate JSON")

        guard let name = json["name"] as? String,
              let description = json["description"] as? String,
              let rawDataArray = json["data"] as? [Any] else {
            return .failure(.invalidStructure("Missing required fields: name, description, or data"))
        }

        let dataArray = rawDataArray.compactMap { $0 as? [String: Any] }
        guard dataArray.count == rawDataArray.count else {
            return .failure(.invalidStructure("Some data entries are not valid objects."))
        }

        for (index, obj) in dataArray.enumerated() {
            guard let category = obj["category"] as? String, !category.isEmpty else {
                return .failure(.invalidStructure("Object at index \(index) missing valid 'category' field."))
            }
        }

        for rule in rules {
            print("🔍 Checking rule: \(rule.description)")
            if rule.matches(dataArray) {
                return rule.parse(dataArray, name: name, description: description)
            }
        }

        return .failure(.invalidStructure("No matching rule found."))
    }
}


struct Rule2NumericFields: ValidationRule {
    var description: String { "category + 2 numeric fields → 3 keys" }

    func matches(_ objects: [[String: Any]]) -> Bool {
        objects.allSatisfy {
            $0.filter { $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) != nil }.count == 2 && $0.count == 3
        }
    }

    func parse(_ objects: [[String: Any]], name: String, description: String) -> Result<ValidatedDataSet, JSONValidationError> {
        let parsed: [DataPointStringDecimal_2] = objects.compactMap { obj in
            guard let category = obj["category"] as? String else { return nil }
            let decimals = obj.filter { $0.key != "category" }
                              .compactMap { DecimalUtils.coerceDecimal(from: $0.value) }
            guard decimals.count == 2 else { return nil }
            return DataPointStringDecimal_2(
                category: category,
                value1: NSDecimalNumber(decimal: decimals[0]).doubleValue,
                value2: NSDecimalNumber(decimal: decimals[1]).doubleValue
            )
        }

        let dataSet = DataSetStringDecimal_2(name: name, description: description, data: parsed)
        return .success(.dataSetStringDecimal_2(dataSet))
    }
}

struct Rule3NumericFields: ValidationRule {
    var description: String { "category + 3 numeric fields → 4 keys" }

    func matches(_ objects: [[String: Any]]) -> Bool {
        objects.allSatisfy { obj in
            let numericCount = obj.filter { $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) != nil }.count
            return numericCount == 3 && obj.count == 4
        }
    }

    func parse(_ objects: [[String: Any]], name: String, description: String) -> Result<ValidatedDataSet, JSONValidationError> {
        let parsed: [DataPointStringDecimal_3] = objects.compactMap { obj in
            guard let category = obj["category"] as? String else { return nil }

            let decimals = obj.filter { $0.key != "category" }
                              .compactMap { DecimalUtils.coerceDecimal(from: $0.value) }

            guard decimals.count == 3 else { return nil }

            return DataPointStringDecimal_3(
                category: category,
                value1: decimals[0],
                value2: decimals[1],
                value3: decimals[2]
            )
        }

        let dataSet = DataSetStringDecimal_3(name: name, description: description, data: parsed)
        return .success(.dataSetStringDecimal_3(dataSet))
    }
}

struct Rule4NumericFields: ValidationRule {
    var description: String { "category + 4 numeric fields → 5 keys" }

    func matches(_ objects: [[String: Any]]) -> Bool {
        objects.allSatisfy { obj in
            let numericCount = obj.filter { $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) != nil }.count
            return numericCount == 4 && obj.count == 5
        }
    }

    func parse(_ objects: [[String: Any]], name: String, description: String) -> Result<ValidatedDataSet, JSONValidationError> {
        let parsed: [DataPointStringDecimal_4] = objects.compactMap { obj in
            guard let category = obj["category"] as? String else { return nil }

            let decimals = obj.filter { $0.key != "category" }
                              .compactMap { DecimalUtils.coerceDecimal(from: $0.value) }

            guard decimals.count == 4 else { return nil }

            return DataPointStringDecimal_4(
                category: category,
                value1: decimals[0],
                value2: decimals[1],
                value3: decimals[2],
                value4: decimals[3]
            )
        }

        let dataSet = DataSetStringDecimal_4(name: name, description: description, data: parsed)
        return .success(.dataSetStringDecimal_4(dataSet))
    }
}

struct Rule4NumericFieldsPlus1String: ValidationRule {
    var description: String { "category + 4 numeric fields + 1 extra string → 6 keys" }

    func matches(_ objects: [[String: Any]]) -> Bool {
        objects.allSatisfy { obj in
            guard let category = obj["category"] as? String else { return false }

            let numericCount = obj.filter {
                $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) != nil
            }.count

            let stringExtras = obj.filter {
                $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) == nil && $0.value is String
            }

            return numericCount == 4 && stringExtras.count == 1 && obj.count == 6
        }
    }

    func parse(_ objects: [[String: Any]], name: String, description: String) -> Result<ValidatedDataSet, JSONValidationError> {
        let parsed: [DataPointStringDecimal_4Plus1] = objects.compactMap { obj in
            guard let category = obj["category"] as? String else { return nil }

            let numericValues = obj.filter {
                $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) != nil
            }.compactMap { DecimalUtils.coerceDecimal(from: $0.value) }

            guard numericValues.count == 4 else { return nil }

            let extraString = obj.filter {
                $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) == nil && $0.value is String
            }.first?.value as? String

            guard let extra = extraString else { return nil }

            return DataPointStringDecimal_4Plus1(
                category: category,
                value1: numericValues[0],
                value2: numericValues[1],
                value3: numericValues[2],
                value4: numericValues[3],
                extra: extra
            )
        }

        let dataSet = DataSetStringDecimal_4Plus1(name: name, description: description, data: parsed)
        return .success(.dataSetStringDecimal_4Plus1(dataSet))
    }
}
