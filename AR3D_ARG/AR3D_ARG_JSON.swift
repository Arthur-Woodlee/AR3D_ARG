//
//  AR3D_ARG_JSON.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
import SwiftUI

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
            guard let category = obj["category"] as? String else {
                return .failure(.invalidStructure("Object at index \(index) missing 'category' field."))
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
            guard let category = obj["category"] as? String else {
                print("❌ Missing 'category' string in object: \(obj)")
                return false
            }

            let numericCount = obj.filter {
                $0.key != "category" && $0.value is NSNumber
            }.count

            let stringExtras = obj.filter {
                $0.key != "category" && $0.value is String
            }

            let keyCount = obj.count
            let passes = numericCount == 4 && stringExtras.count == 1 && keyCount == 6

            if !passes {
                print("❌ Validation failed for object: \(obj)")
                print("🔢 Numeric count: \(numericCount)")
                print("🔤 Extra string count: \(stringExtras.count)")
                print("🔑 Total keys: \(keyCount)")
            }

            return passes
        }
    }

    func parse(_ objects: [[String: Any]], name: String, description: String) -> Result<ValidatedDataSet, JSONValidationError> {
        let parsed: [DataPointStringDecimal_4Plus1] = objects.compactMap { obj in
            guard let category = obj["category"] as? String else {
                print("❌ Parse failed: missing 'category' in object: \(obj)")
                return nil
            }

            let numericValues = obj.filter {
                $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) != nil
            }.compactMap { DecimalUtils.coerceDecimal(from: $0.value) }

            if numericValues.count != 4 {
                print("❌ Parse failed: expected 4 numeric values, got \(numericValues.count) in object: \(obj)")
                return nil
            }

            let extraString = obj.filter {
                $0.key != "category" && DecimalUtils.coerceDecimal(from: $0.value) == nil && $0.value is String
            }.first?.value as? String

            guard let extra = extraString else {
                print("❌ Parse failed: missing extra string field in object: \(obj)")
                return nil
            }

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
