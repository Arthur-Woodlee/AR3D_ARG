//
//  AR3D_ARG_Rendering_Utils.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
import SwiftUI
import RealityKit
import UIKit
import ARKit
import Foundation

struct AxisRenderer {
    static func addAxes(
        to node: SCNNode,
        minX: Decimal, maxX: Decimal,
        minY: Decimal, maxY: Decimal,
        minZ: Decimal, maxZ: Decimal,
        lengthX: Float,
        lengthY: Float,
        lengthZ: Float,
        originalMinX: Decimal, originalMaxX: Decimal,
        originalMinY: Decimal, originalMaxY: Decimal,
        originalMinZ: Decimal, originalMaxZ: Decimal,
        xLabelText: String,
        yLabelText: String,
        zLabelText: String? = nil
    ) {
        let labelScale = SCNVector3(0.025, 0.025, 0.025) // 🔧 Adjust this to resize all axis labels

        // X Axis
        let xAxis = SCNCylinder(radius: 0.005, height: CGFloat(lengthX))
        xAxis.firstMaterial?.diffuse.contents = UIColor.red
        let xNode = SCNNode(geometry: xAxis)
        xNode.position = SCNVector3(lengthX / 2, 0, 0)
        xNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        node.addChildNode(xNode)

        let xLabel = AxisHelpers.createAxisLabel(xLabelText, color: .red)
        xLabel.position = SCNVector3(lengthX + 0.05, 0.02, 0)
        xLabel.scale = labelScale
        node.addChildNode(xLabel)

        AxisHelpers.addTickLabels(to: node, axis: "x", count: 11, length: lengthX, min: originalMinX, max: originalMaxX, color: .red)

        // Y Axis
        let yAxis = SCNCylinder(radius: 0.005, height: CGFloat(lengthY))
        yAxis.firstMaterial?.diffuse.contents = UIColor.green
        let yNode = SCNNode(geometry: yAxis)
        yNode.position = SCNVector3(0, lengthY / 2, 0)
        node.addChildNode(yNode)

        let yLabel = AxisHelpers.createAxisLabel(yLabelText, color: .green)
        yLabel.position = SCNVector3(0.02, lengthY + 0.05, 0)
        yLabel.scale = labelScale
        node.addChildNode(yLabel)

        AxisHelpers.addTickLabels(to: node, axis: "y", count: 11, length: lengthY, min: originalMinY, max: originalMaxY, color: .green)

        // Z Axis
        if lengthZ > 0, let zLabelText = zLabelText {
            let zAxis = SCNCylinder(radius: 0.005, height: CGFloat(lengthZ))
            zAxis.firstMaterial?.diffuse.contents = UIColor.blue
            let zNode = SCNNode(geometry: zAxis)
            zNode.position = SCNVector3(0, 0, lengthZ / 2)
            zNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            node.addChildNode(zNode)

            let zLabel = AxisHelpers.createAxisLabel(zLabelText, color: .blue)
            zLabel.position = SCNVector3(0, 0.02, lengthZ + 0.05)
            zLabel.scale = labelScale
            node.addChildNode(zLabel)

            AxisHelpers.addTickLabels(to: node, axis: "z", count: 11, length: lengthZ, min: originalMinZ, max: originalMaxZ, color: .blue)
        }

        print("📐 Axis lines and labels added")
    }
}

struct GridPlanesRenderer {
    static func addGridPlanes(to node: SCNNode,
                              minX: Decimal, maxX: Decimal,
                              minY: Decimal, maxY: Decimal,
                              minZ: Decimal, maxZ: Decimal,
                              spacing: Float = 0.1,
                              color: UIColor = .lightGray) {
        
        let xRange = Float(truncating: (maxX - minX) as NSDecimalNumber)
        let yRange = Float(truncating: (maxY - minY) as NSDecimalNumber)
        let zRange = Float(truncating: (maxZ - minZ) as NSDecimalNumber)

        // XY Plane Grid
        let xyPlane = SCNNode()
        for x in stride(from: 0, through: xRange, by: spacing) {
            let line = SCNBox(width: 0.001, height: CGFloat(yRange), length: 0.001, chamferRadius: 0)
            line.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(x, yRange / 2, 0)
            xyPlane.addChildNode(node)
        }
        for y in stride(from: 0, through: yRange, by: spacing) {
            let line = SCNBox(width: CGFloat(xRange), height: 0.001, length: 0.001, chamferRadius: 0)
            line.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(xRange / 2, y, 0)
            xyPlane.addChildNode(node)
        }
        node.addChildNode(xyPlane)

        // YZ Plane Grid (fixed orientation)
        let yzPlane = SCNNode()
        for y in stride(from: 0, through: yRange, by: spacing) {
            let line = SCNBox(width: 0.001, height: 0.001, length: CGFloat(zRange), chamferRadius: 0)
            line.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(0, y, zRange / 2)
            yzPlane.addChildNode(node)
        }
        for z in stride(from: 0, through: zRange, by: spacing) {
            let line = SCNBox(width: 0.001, height: CGFloat(yRange), length: 0.001, chamferRadius: 0)
            line.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(0, yRange / 2, z)
            yzPlane.addChildNode(node)
        }
        node.addChildNode(yzPlane)

        // XZ Plane Grid
        let xzPlane = SCNNode()
        for x in stride(from: 0, through: xRange, by: spacing) {
            let line = SCNBox(width: 0.001, height: 0.001, length: CGFloat(zRange), chamferRadius: 0)
            line.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(x, 0, zRange / 2)
            xzPlane.addChildNode(node)
        }
        for z in stride(from: 0, through: zRange, by: spacing) {
            let line = SCNBox(width: CGFloat(xRange), height: 0.001, length: 0.001, chamferRadius: 0)
            line.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(xRange / 2, 0, z)
            xzPlane.addChildNode(node)
        }
        node.addChildNode(xzPlane)
    }
}

struct AxisHelpers {
    
    static func createAxisLabel(_ text: String, color: UIColor) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.2)
        textGeometry.font = UIFont.systemFont(ofSize: 1.0)
        textGeometry.firstMaterial?.diffuse.contents = color
        textGeometry.flatness = 0.1

        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.1, 0.1, 0.1)
        textNode.constraints = [SCNBillboardConstraint()]
        return textNode
    }
    
    static func createTickLabel(_ value: String, color: UIColor) -> SCNNode {
        // Format to 1 digit after the decimal
        let number = Double(value) ?? 0.0
        let formatted = String(format: "%.1f", number)

        let textGeometry = SCNText(string: formatted, extrusionDepth: 0.1)
        textGeometry.font = UIFont.systemFont(ofSize: 2.0)
        textGeometry.firstMaterial?.diffuse.contents = color
        textGeometry.flatness = 0.2

        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.008, 0.008, 0.008)
        textNode.constraints = [SCNBillboardConstraint()]
        return textNode
    }
    
    static func addTicks(to node: SCNNode, axis: String, count: Int, length: Float, color: UIColor) {
        let spacing = length / Float(count - 1)
        for i in 0..<count {
            let tick = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            tick.firstMaterial?.diffuse.contents = color
            let tickNode = SCNNode(geometry: tick)

            switch axis {
            case "x":
                tickNode.position = SCNVector3(Float(i) * spacing, 0.025, 0)
            case "y":
                tickNode.position = SCNVector3(0, Float(i) * spacing, 0.025)
            case "z":
                tickNode.position = SCNVector3(0.025, 0, Float(i) * spacing)
            default:
                continue
            }

            node.addChildNode(tickNode)
        }
    }

    static func addTickLabels(to node: SCNNode,
                              axis: String,
                              count: Int,
                              length: Float,
                              min: Decimal,
                              max: Decimal,
                              color: UIColor) {
        let spacing = length / Float(count - 1)
        let labelScale = SCNVector3(0.02, 0.02, 0.02) // 🔧 Adjust this to resize all tick labels

        for i in 0..<count {
            let t = Float(i) / Float(count - 1)
            let tDecimal = Decimal(Double(t))
            let value = min + (max - min) * tDecimal
            let labelText = NSDecimalNumber(decimal: value).stringValue
            let labelNode = createTickLabel(labelText, color: color)
            labelNode.scale = labelScale

            switch axis {
            case "x":
                labelNode.position = SCNVector3(Float(i) * spacing, 0.06, 0)
            case "y":
                labelNode.position = SCNVector3(0, Float(i) * spacing, 0.06)
            case "z":
                labelNode.position = SCNVector3(0.06, 0, Float(i) * spacing)
            default:
                continue
            }

            node.addChildNode(labelNode)
        }
    }
}

struct NodeStyler {
    static func applyStyle(
        to node: SCNNode,
        category: String,
        theme: any ColorTheme = DefaultTheme()
    ) {
        guard let geometry = node.geometry else { return }
        geometry.firstMaterial?.diffuse.contents = theme.color(for: category)
    }
}

struct DataParser {
    static func loadValidatedPoints(from url: URL) -> Result<[[String: Any]], Error> {
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rawPoints = json["data"] as? [[String: Any]] else {
                return .failure(NSError(domain: "DataParser", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid JSON structure"
                ]))
            }

            return .success(rawPoints)

        } catch {
            return .failure(error)
        }
    }
}

extension SCNGeometry {
    static func polyline(from points: [SCNVector3]) -> SCNGeometry {
        let source = SCNGeometrySource(vertices: points)
        var indices: [UInt32] = []
        for i in 0..<points.count - 1 {
            indices.append(UInt32(i))
            indices.append(UInt32(i + 1))
        }
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.firstMaterial?.isDoubleSided = true
        return geometry
    }
}


