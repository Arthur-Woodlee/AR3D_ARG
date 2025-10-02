//
//  VisulaiseViewModels.swift
//  ARGAv3
//
//  Created by Arthur Woodlee on 7/9/2025.
//
import SwiftUI
import RealityKit
import UIKit
import ARKit
import Foundation


protocol GraphRenderer {
    func buildGraph(from configuration: GraphingConfiguration, in sceneView: ARSCNView) -> (SCNNode, [SCNNode: [String: Any]])
}

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


struct GraphRendererRegistry {
    static func renderer(for type: GraphType?) -> GraphRenderer? {
        guard let type = type else { return nil }
        switch type {
        case .scatterPlot:
            return ScatterPlotRenderer()
        // case .surfacePlot: return SurfacePlotRenderer()
        // case .histogramPlot: return HistogramRenderer()
        default:
            return nil
        }
    }
}

class ARViewController: UIViewController, ARSCNViewDelegate {
    var configuration: GraphingConfiguration!
    var sceneView: ARSCNView!
    var volcanoNode = SCNNode()
    var hasPlacedGraph = false

    private var initialScale: Float = 0.1
    private var currentScale: Float = 0.0
    private var currentRotationY: Float = 0.0
    private var nodeMap: [SCNNode: [String: Any]] = [:]

    convenience init(configuration: GraphingConfiguration) {
        self.init()
        self.configuration = configuration
        currentScale = initialScale
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        view.addSubview(sceneView)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        sceneView.session.run(config)
        print("✅ AR session started with horizontal plane detection")

        addGestureRecognizers()
        addLighting()
    }

    func renderGraphIfNeeded() {
        guard let renderer = GraphRendererRegistry.renderer(for: configuration.selectedGraph) else {
            print("⚠️ No graph renderer available for selected type")
            return
        }

        let (node, map) = renderer.buildGraph(from: configuration, in: sceneView)
        volcanoNode = node
        setNodeMap(map)
        volcanoNode.position = SCNVector3(0, 0.02, 0)
        volcanoNode.scale = SCNVector3(initialScale, initialScale, initialScale)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("📦 Anchor added to scene: \(anchor.name ?? "Unnamed")")

        if anchor.name == "volcanoAnchor" {
            renderGraphIfNeeded()
            node.addChildNode(volcanoNode)
        }

        if let planeAnchor = anchor as? ARPlaneAnchor {
            let extent = planeAnchor.extent
            let center = planeAnchor.center

            print("🧭 Horizontal plane detected: center = \(center), extent = \(extent)")

            let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
            plane.materials.first?.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.3)

            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            planeNode.position = SCNVector3(center.x, 0, center.z)

            volcanoNode.scale = SCNVector3(initialScale, initialScale, initialScale)
            node.addChildNode(planeNode)
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let deltaAngle = Float(translation.x) * (.pi / 180.0) / 2.0

        switch gesture.state {
        case .changed:
            volcanoNode.eulerAngles.y = currentRotationY + deltaAngle
            print("🔄 Rotating volcano node: angle = \(volcanoNode.eulerAngles.y)")
        case .ended, .cancelled:
            currentRotationY += deltaAngle
            print("✅ Final rotation stored: \(currentRotationY)")
        default:
            break
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let scaleFactor = Float(gesture.scale)

        switch gesture.state {
        case .changed:
            let newScale = currentScale * scaleFactor
            volcanoNode.scale = SCNVector3(newScale, newScale, newScale)
            print("🔍 Scaling volcano node: scale = \(newScale)")
        case .ended, .cancelled:
            currentScale *= scaleFactor
            print("✅ Final scale stored: \(currentScale)")
            gesture.scale = 1.0
        default:
            break
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: sceneView)

        if hasPlacedGraph {
            let hitResults = sceneView.hitTest(tapLocation, options: nil)
            if let tappedNode = hitResults.first?.node, let data = nodeMap[tappedNode] {
                showDataOverlay(for: data, at: tappedNode.position)
            }
            return
        }

        let query = sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        guard let raycastQuery = query,
              let result = sceneView.session.raycast(raycastQuery).first else {
            print("⚠️ No surface found at tap location")
            return
        }

        let anchor = ARAnchor(name: "volcanoAnchor", transform: result.worldTransform)
        sceneView.session.add(anchor: anchor)
        hasPlacedGraph = true
        print("📌 Volcano anchor placed on table surface")
    }

    func showDataOverlay(for data: [String: Any], at position: SCNVector3) {
        let summary = data.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let alert = UIAlertController(title: "Data Point", message: summary, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        print("📍 Data point tapped:\n\(summary)")
    }

    func addGestureRecognizers() {
        sceneView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        sceneView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
        print("🖐️ Gesture recognizers added")
    }

    func addLighting() {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1000
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 2, 2)
        sceneView.scene.rootNode.addChildNode(lightNode)
        print("💡 Lighting added")
    }

    func setNodeMap(_ map: [SCNNode: [String: Any]]) {
        self.nodeMap = map
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    let configuration: GraphingConfiguration

    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController(configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

struct SceneBuilder {
    static func buildScatterPlot(
        from rawPoints: [[String: Any]],
        axisKeys: [String],
        categoryKey: String?,
        theme: ColorTheme
    ) -> (SCNNode, [SCNNode: [String: Any]]) {
        let volcanoNode = SCNNode()
        var nodeMap: [SCNNode: [String: Any]] = [:]

        let xKey = axisKeys[0]
        let yKey = axisKeys[1]
        let zKey = axisKeys.count >= 3 ? axisKeys[2] : nil

        let xValues = rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: xKey) }
        let yValues = rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: yKey) }
        let zValues = zKey != nil ? rawPoints.compactMap { DecimalUtils.extractDecimal(from: $0, key: zKey!) } : []

        guard let minX = xValues.min(), let maxX = xValues.max(),
              let minY = yValues.min(), let maxY = yValues.max(),
              zKey == nil || (zValues.min() != nil && zValues.max() != nil) else {
            print("⚠️ Failed to compute min/max")
            return (volcanoNode, nodeMap)
        }

        let minZ = zKey != nil ? zValues.min()! : Decimal(0)
        let maxZ = zKey != nil ? zValues.max()! : Decimal(0)

        for dict in rawPoints {
            guard let xRaw = DecimalUtils.extractDecimal(from: dict, key: xKey),
                  let yRaw = DecimalUtils.extractDecimal(from: dict, key: yKey) else { continue }

            let zRaw = zKey != nil ? DecimalUtils.extractDecimal(from: dict, key: zKey!) ?? Decimal(0) : Decimal(0)

            let x = DecimalUtils.decimalNormalize(value: xRaw, min: minX, max: maxX)
            let y = DecimalUtils.decimalNormalize(value: yRaw, min: minY, max: maxY)
            let z = DecimalUtils.decimalNormalize(value: zRaw, min: minZ, max: maxZ)

            // ✅ Only use category if explicitly selected
            let category = categoryKey.flatMap { dict[$0] as? String } ?? "default"

            let geometry = theme.shape(for: category)
            geometry.firstMaterial?.diffuse.contents = theme.color(for: category)

            let node = SCNNode(geometry: geometry)
            node.position = SCNVector3(x, y, z)

            volcanoNode.addChildNode(node)
            nodeMap[node] = dict
        }

        return (volcanoNode, nodeMap)
    }
}


