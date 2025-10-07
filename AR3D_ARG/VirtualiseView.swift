//
//  VirtualiseView.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 7/9/2025.
//
import SwiftUI
import RealityKit
import UIKit
import ARKit


struct VirtualiseView: View {
    let configuration: [GraphingConfiguration]

    var body: some View {
        ARViewContainer(configurations: configuration)
            .edgesIgnoringSafeArea(.all)
    }
}

