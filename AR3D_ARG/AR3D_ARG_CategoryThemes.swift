//
//  AR3D_ARG_CategoryThemes.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
import SwiftUI
import RealityKit
import UIKit
import ARKit
import Foundation

protocol ColorTheme: Identifiable, Hashable {
    var name: String { get }
    func color(for category: String) -> UIColor
    func shape(for category: String) -> SCNGeometry
}

struct ShapeOnlyTheme: ColorTheme {
    let id = UUID()
    let name = "Shape Only"

    private var shapeCache: [String: SCNGeometry] = [:]

    func color(for category: String) -> UIColor {
        UIColor.systemGray
    }

    func shape(for category: String) -> SCNGeometry {
        // If category is "default", return a neutral shape
        if category == "default" {
            return SCNSphere(radius: 0.02)
        }

        // Assign a consistent shape per category using hash
        let index = abs(category.hashValue) % 8
        switch index {
        case 0: return SCNSphere(radius: 0.02)
        case 1: return SCNPyramid(width: 0.02, height: 0.02, length: 0.02)
        case 2: return SCNCylinder(radius: 0.015, height: 0.03)
        case 3: return SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0)
        case 4: return SCNTorus(ringRadius: 0.02, pipeRadius: 0.005)
        case 5: return SCNCone(topRadius: 0.0, bottomRadius: 0.02, height: 0.03)
        case 6: return SCNCapsule(capRadius: 0.01, height: 0.03)
        default: return SCNPlane(width: 0.02, height: 0.02)
        }
    }
}


struct DefaultTheme: ColorTheme {
    let id = UUID()
    let name = "Default"

    func color(for category: String) -> UIColor {
        let hash = abs(category.hashValue)
        let hue = CGFloat(hash % 256) / 255.0
        return UIColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1.0)
    }

    func shape(for category: String) -> SCNGeometry {
        SCNSphere(radius: 0.02)
    }
}

struct MaterialTheme: ColorTheme {
    let id = UUID()
    let name = "Material"

    func color(for category: String) -> UIColor {
        switch category.lowercased() {
        case "low": return .systemGreen
        case "medium": return .systemOrange
        case "high": return .systemRed
        default: return .systemGray
        }
    }

    func shape(for category: String) -> SCNGeometry {
        switch category.lowercased() {
        case "low": return SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0)
        case "medium": return SCNCylinder(radius: 0.015, height: 0.03)
        case "high": return SCNPyramid(width: 0.02, height: 0.02, length: 0.02)
        default: return SCNSphere(radius: 0.02)
        }
    }
}


struct NeonTheme: ColorTheme {
    let id = UUID()
    let name = "Neon"

    func color(for category: String) -> UIColor {
        let hash = abs(category.hashValue)
        let hue = CGFloat(hash % 256) / 255.0
        return UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    func shape(for category: String) -> SCNGeometry {
        if category == "default" {
            return SCNSphere(radius: 0.02)
        }

        let hash = abs(category.hashValue)
        switch hash % 3 {
        case 0: return SCNTorus(ringRadius: 0.02, pipeRadius: 0.005)
        case 1: return SCNCone(topRadius: 0.005, bottomRadius: 0.02, height: 0.03)
        default: return SCNSphere(radius: 0.02)
        }
    }
}

struct ThemeRegistry {
    static let all: [ThemeViewModel] = [
        ThemeViewModel(theme: DefaultTheme()),
        ThemeViewModel(theme: MaterialTheme()),
        ThemeViewModel(theme: NeonTheme()),
        ThemeViewModel(theme: ShapeOnlyTheme())  // ✅ Added here
    ]
}
