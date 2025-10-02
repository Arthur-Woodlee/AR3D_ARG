//
//  ConfigureGraphingViewModels.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 7/9/2025.
//
import SwiftUI
import Foundation


enum GraphType: String, CaseIterable, Identifiable {
    case scatterPlot = "Scatter Plot"
    /*case surfacePlot = "Surface Plot"
    case histogramPlot = "Histogram Plot"
    case parallelCoordinatesPlot = "Parallel Coordinates Plot"
    case clusterPlot = "Cluster Plot"*/

    var id: String { rawValue }
}

/*
struct GraphingConfiguration: Identifiable, Hashable {
    let id = UUID()
    let dataSet: DataSet
    let selectedGraph: GraphType?
    var selectedFeatures: [String] = ["A", "B", "C", "D"] // default
}
*/


struct GraphingConfiguration: Identifiable {
    let id = UUID()
    let dataSet: DataSet
    let selectedGraph: GraphType?
    var selectedFeatures: [String] = ["A", "B", "C", "D"]
    var theme: any ColorTheme = DefaultTheme()
}

extension GraphingConfiguration: Equatable {
    static func == (lhs: GraphingConfiguration, rhs: GraphingConfiguration) -> Bool {
        lhs.id == rhs.id
    }
}

extension GraphingConfiguration: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct GraphingDataUtils {
    static func formatExample(from dataSet: DataSet) -> String? {
        guard let data = try? Data(contentsOf: dataSet.fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let points = json["data"] as? [[String: Any]],
              let first = points.first else {
            return nil
        }

        let numericKeys = first.filter { DecimalUtils.coerceDecimal(from: $0.value) != nil }.map { $0.key }
        let stringKeys = first.filter { $0.value is String }.map { $0.key }

        return "(\(stringKeys.joined(separator: ", ")), \(numericKeys.joined(separator: ", ")))"
    }

    static func extractNumericFeatureKeys(from dataSet: DataSet) -> [String]? {
        guard let data = try? Data(contentsOf: dataSet.fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let points = json["data"] as? [[String: Any]],
              let first = points.first else {
            return nil
        }

        return first.compactMap { key, value in
            switch value {
            case is Int, is Double, is Decimal, is NSNumber:
                return key
            default:
                return nil
            }
        }
    }

    static func extractCategoricalKeys(from dataSet: DataSet) -> [String]? {
        guard let data = try? Data(contentsOf: dataSet.fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let points = json["data"] as? [[String: Any]],
              let first = points.first else {
            return nil
        }

        return first.compactMap { key, value in
            if value is String {
                return key
            }
            return nil
        }
    }
}
