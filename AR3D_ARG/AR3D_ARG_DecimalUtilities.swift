//
//  AR3D_ARG_Decimal_Utilities.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
import SwiftUI
import RealityKit
import UIKit
import ARKit
import Foundation

struct DecimalUtils {
    static func extractDecimal(from dict: [String: Any], key: String) -> Decimal? {
        guard let raw = dict[key] else { return nil }
        if let d = raw as? Decimal { return d }
        if let n = raw as? NSNumber { return Decimal(n.doubleValue) }
        if let s = raw as? String, let d = Decimal(string: s) { return d }
        return nil
    }

    static func decimalNormalize(value: Decimal, min: Decimal, max: Decimal) -> Float {
        if max == min { return 0.5 }
        let normalized = (value - min) / (max - min)
        return NSDecimalNumber(decimal: normalized).floatValue
    }
    
    static func coerceDecimal(from value: Any) -> Decimal? {
        if let decimal = value as? Decimal { return decimal }
        if let double = value as? Double { return Decimal(double) }
        if let int = value as? Int { return Decimal(int) }
        if let number = value as? NSNumber { return Decimal(string: number.stringValue) }
        if let string = value as? String { return Decimal(string: string) }
        return nil
    }
}
