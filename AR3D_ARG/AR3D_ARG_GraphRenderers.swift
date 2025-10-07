//
//  AR3D_ARG_Graph_Renderers.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
import SwiftUI
import RealityKit
import UIKit
import ARKit
import Foundation


protocol GraphRenderer {
    func buildGraph(from configuration: GraphingConfiguration, in sceneView: ARSCNView) -> (SCNNode, [SCNNode: [String: Any]])
}


private func addAxesAndOptionalGrid(to node: SCNNode,
                                    axisKeys: [String],
                                    xValues: [Decimal],
                                    yValues: [Decimal],
                                    zValues: [Decimal],
                                    includeGrid: Bool) {
    let xKey = axisKeys[0]
    let yKey = axisKeys[1]
    let zKey = axisKeys.count >= 3 ? axisKeys[2] : nil

    let originalMinX = xValues.min() ?? 0
    let originalMaxX = xValues.max() ?? 1
    let originalMinY = yValues.min() ?? 0
    let originalMaxY = yValues.max() ?? 1
    let originalMinZ = zKey != nil ? (zValues.min() ?? 0) : 0
    let originalMaxZ = zKey != nil ? (zValues.max() ?? 1) : 1

    let minX: Decimal = 0, maxX: Decimal = 1
    let minY: Decimal = 0, maxY: Decimal = 1
    let minZ: Decimal = 0, maxZ: Decimal = 1

    let lengthX = Float(truncating: (maxX - minX) as NSDecimalNumber)
    let lengthY = Float(truncating: (maxY - minY) as NSDecimalNumber)
    let lengthZ = Float(truncating: (maxZ - minZ) as NSDecimalNumber)

    AxisRenderer.addAxes(
        to: node,
        minX: minX, maxX: maxX,
        minY: minY, maxY: maxY,
        minZ: minZ, maxZ: maxZ,
        lengthX: lengthX,
        lengthY: lengthY,
        lengthZ: axisKeys.count >= 3 ? lengthZ : 0.0,
        originalMinX: originalMinX, originalMaxX: originalMaxX,
        originalMinY: originalMinY, originalMaxY: originalMaxY,
        originalMinZ: originalMinZ, originalMaxZ: originalMaxZ,
        xLabelText: xKey,
        yLabelText: yKey,
        zLabelText: zKey
    )

    guard includeGrid else { return }

    GridPlanesRenderer.addGridPlanes(
        to: node,
        minX: minX, maxX: maxX,
        minY: minY, maxY: maxY,
        minZ: minZ, maxZ: maxZ,
        spacing: 0.1,
        color: UIColor.systemGray4
    )
}

struct ScatterPlotRenderer: GraphRenderer {
    func buildGraph(from configuration: GraphingConfiguration, in sceneView: ARSCNView) -> (SCNNode, [SCNNode: [String: Any]]) {
        return buildScatterPlot(from: configuration, includeGrid: true)
    }
}

struct ScatterPlotNoGridRenderer: GraphRenderer {
    func buildGraph(from configuration: GraphingConfiguration, in sceneView: ARSCNView) -> (SCNNode, [SCNNode: [String: Any]]) {
        return buildScatterPlot(from: configuration, includeGrid: false)
    }
}

private func buildScatterPlot(from configuration: GraphingConfiguration, includeGrid: Bool) -> (SCNNode, [SCNNode: [String: Any]]) {
    guard case .success(let rawPoints) = DataParser.loadValidatedPoints(from: configuration.dataSet.fileURL) else {
        print("⚠️ Dataset loading failed")
        return (SCNNode(), [:])
    }

    let axisKeys = configuration.selectedFeatures.filter { key in
        rawPoints.first?[key] is NSNumber ||
        rawPoints.first?[key] is Int ||
        rawPoints.first?[key] is Double ||
        rawPoints.first?[key] is Decimal
    }

    guard axisKeys.count >= 2 else {
        print("⚠️ Not enough axis features selected")
        return (SCNNode(), [:])
    }

    let categoryKey = configuration.selectedFeatures.contains("category") ? "category" : nil

    // ✅ Resolve the theme from themeID
    let theme = ThemeRegistry.all.first(where: { $0.id == configuration.themeID })?.theme ?? DefaultTheme()

    let (node, map) = SceneBuilder.buildScatterPlot(
        from: rawPoints,
        axisKeys: axisKeys,
        categoryKey: categoryKey,
        theme: theme
    )

    let xValues = rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: axisKeys[0]) }
    let yValues = rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: axisKeys[1]) }
    let zValues = axisKeys.count >= 3 ? rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: axisKeys[2]) } : []

    addAxesAndOptionalGrid(to: node,
                           axisKeys: axisKeys,
                           xValues: xValues,
                           yValues: yValues,
                           zValues: zValues,
                           includeGrid: includeGrid)

    return (node, map)
}


/*
struct ScatterPlotRenderer: GraphRenderer {
    func buildGraph(from configuration: GraphingConfiguration, in sceneView: ARSCNView) -> (SCNNode, [SCNNode: [String: Any]]) {
        let result = DataParser.loadValidatedPoints(from: configuration.dataSet.fileURL)
        guard case .success(let rawPoints) = result else {
            print("⚠️ Dataset loading failed")
            return (SCNNode(), [:])
        }

        let selected = configuration.selectedFeatures

        let axisKeys = selected.filter { key in
            rawPoints.first?[key] is NSNumber || rawPoints.first?[key] is Int ||
            rawPoints.first?[key] is Double || rawPoints.first?[key] is Decimal
        }

        // ✅ Only use "category" if explicitly selected
        let categoryKey: String? = selected.contains("category") ? "category" : nil

        guard axisKeys.count >= 2 else {
            print("⚠️ Not enough axis features selected")
            return (SCNNode(), [:])
        }

        let theme = configuration.theme

        let (node, map) = SceneBuilder.buildScatterPlot(
            from: rawPoints,
            axisKeys: axisKeys,
            categoryKey: categoryKey,
            theme: theme
        )

        let xKey = axisKeys[0]
        let yKey = axisKeys[1]
        let zKey = axisKeys.count >= 3 ? axisKeys[2] : nil

        let xValues = rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: xKey) }
        let yValues = rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: yKey) }
        let zValues = zKey != nil ? rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: zKey!) } : []

        guard let originalMinX = xValues.min(), let originalMaxX = xValues.max(),
              let originalMinY = yValues.min(), let originalMaxY = yValues.max(),
              zKey == nil || (zValues.min() != nil && zValues.max() != nil) else {
            print("⚠️ Failed to compute original min/max for axis labels")
            return (SCNNode(), [:])
        }

        let originalMinZ = zKey != nil ? zValues.min()! : Decimal(0)
        let originalMaxZ = zKey != nil ? zValues.max()! : Decimal(0)

        let minX: Decimal = 0
        let maxX: Decimal = 1
        let minY: Decimal = 0
        let maxY: Decimal = 1
        let minZ: Decimal = 0
        let maxZ: Decimal = 1

        let lengthX = Float(truncating: (maxX - minX) as NSDecimalNumber)
        let lengthY = Float(truncating: (maxY - minY) as NSDecimalNumber)
        let lengthZ = Float(truncating: (maxZ - minZ) as NSDecimalNumber)

        AxisRenderer.addAxes(
            to: node,
            minX: minX, maxX: maxX,
            minY: minY, maxY: maxY,
            minZ: minZ, maxZ: maxZ,
            lengthX: lengthX,
            lengthY: lengthY,
            lengthZ: axisKeys.count >= 3 ? lengthZ : 0.0,
            originalMinX: originalMinX, originalMaxX: originalMaxX,
            originalMinY: originalMinY, originalMaxY: originalMaxY,
            originalMinZ: originalMinZ, originalMaxZ: originalMaxZ,
            xLabelText: xKey,
            yLabelText: yKey,
            zLabelText: zKey
        )

        GridPlanesRenderer.addGridPlanes(
            to: node,
            minX: minX, maxX: maxX,
            minY: minY, maxY: maxY,
            minZ: minZ, maxZ: maxZ,
            spacing: 0.1,
            color: UIColor.systemGray4
        )

        return (node, map)
    }
}
*/

struct GraphRendererRegistry {
    static func renderer(for type: GraphType?) -> GraphRenderer? {
        guard let type = type else { return nil }
        switch type {
        case .scatterPlot:
            return ScatterPlotRenderer()
        case .scatterPlotNoGrid:
            return ScatterPlotNoGridRenderer()
        // case .surfacePlot: return SurfacePlotRenderer()
        // case .histogramPlot: return HistogramRenderer()
        default:
            return nil
        }
    }
}

