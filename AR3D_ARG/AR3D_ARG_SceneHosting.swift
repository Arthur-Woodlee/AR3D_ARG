//
//  AR3D_ARG_Scene_Hosting.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
import SwiftUI
import RealityKit
import UIKit
import ARKit
import Foundation

class ARViewController: UIViewController, ARSCNViewDelegate {
    var configurations: [GraphingConfiguration] = []
    var sceneView: ARSCNView!
    private var graphNodes: [SCNNode] = []
    private var nodeMap: [SCNNode: [String: Any]] = [:]
    private var hasPlacedGraph = false

    private let gestureHandler = GestureHandler()
    private var controlPanel: UIStackView?

    convenience init(configurations: [GraphingConfiguration]) {
        self.init()
        self.configurations = configurations
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

        addLighting()
        addGestureRecognizers()
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let extent = planeAnchor.extent
            let center = planeAnchor.center

            let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
            plane.materials.first?.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.3)

            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            planeNode.position = SCNVector3(center.x, 0, center.z)
            node.addChildNode(planeNode)

            let (nodes, map) = GraphRendererManager.renderGraphs(configurations: configurations, in: sceneView, rootNode: node)
            graphNodes = nodes
            nodeMap = map
            hasPlacedGraph = true
        }
    }

    private func addGestureRecognizers() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        singleTap.numberOfTapsRequired = 1

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2

        singleTap.require(toFail: doubleTap)

        sceneView.addGestureRecognizer(singleTap)
        sceneView.addGestureRecognizer(doubleTap)
        sceneView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        sceneView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)

        if hasPlacedGraph {
            let hits = sceneView.hitTest(location, options: nil)
            if let node = hits.first?.node, let data = nodeMap[node] {
                showDataOverlay(for: data, at: node.position)
            }
            return
        }

        let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        guard let result = sceneView.session.raycast(query!).first else { return }

        let anchor = ARAnchor(name: "volcanoAnchor", transform: result.worldTransform)
        sceneView.session.add(anchor: anchor)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hits = sceneView.hitTest(location, options: nil)

        guard let tappedNode = hits.first?.node else { return }

        var current: SCNNode? = tappedNode
        while let node = current, !graphNodes.contains(node) {
            current = node.parent
        }

        if let root = current {
            gestureHandler.selectNode(root)
            showControlPanel()
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        gestureHandler.rotateNode(with: gesture.translation(in: gesture.view))
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        gestureHandler.scaleNode(with: Float(gesture.scale))
        gesture.scale = 1.0
    }

    private func showControlPanel() {
        controlPanel?.removeFromSuperview()
        let panel = ControlPanelView.create(target: self)
        view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)
        ])
        controlPanel = panel
    }

    @objc func moveXPlus() { gestureHandler.moveNode(by: SCNVector3(0.01, 0, 0)) }
    @objc func moveXMinus() { gestureHandler.moveNode(by: SCNVector3(-0.01, 0, 0)) }
    @objc func moveYPlus() { gestureHandler.moveNode(by: SCNVector3(0, 0.01, 0)) }
    @objc func moveYMinus() { gestureHandler.moveNode(by: SCNVector3(0, -0.01, 0)) }
    @objc func moveZPlus() { gestureHandler.moveNode(by: SCNVector3(0, 0, 0.01)) }
    @objc func moveZMinus() { gestureHandler.moveNode(by: SCNVector3(0, 0, -0.01)) }

    private func showDataOverlay(for data: [String: Any], at position: SCNVector3) {
        let summary = data.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let alert = UIAlertController(title: "Data Point", message: summary, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func addLighting() {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1000
        let node = SCNNode()
        node.light = light
        node.position = SCNVector3(0, 2, 2)
        sceneView.scene.rootNode.addChildNode(node)
    }
}
class ControlPanelView {
    static func create(target: Any) -> UIStackView {
        let panel = UIStackView()
        panel.axis = .vertical
        panel.spacing = 8
        panel.translatesAutoresizingMaskIntoConstraints = false

        ["X", "Y", "Z"].forEach { axis in
            let label = UILabel()
            label.text = axis
            label.widthAnchor.constraint(equalToConstant: 20).isActive = true

            let plus = UIButton(type: .system)
            plus.setTitle("+", for: .normal)
            plus.addTarget(target, action: Selector("move\(axis)Plus"), for: .touchUpInside)

            let minus = UIButton(type: .system)
            minus.setTitle("–", for: .normal)
            minus.addTarget(target, action: Selector("move\(axis)Minus"), for: .touchUpInside)

            let row = UIStackView(arrangedSubviews: [label, minus, plus])
            row.axis = .horizontal
            row.spacing = 8
            panel.addArrangedSubview(row)
        }

        return panel
    }
}

class GestureHandler {
    private var selectedNode: SCNNode?
    private var nodeTransforms: [SCNNode: (scale: Float, rotationY: Float)] = [:]

    // Rotation sensitivity factor — tweak this to adjust speed
    private let rotationSensitivity: Float = 0.002

    func selectNode(_ node: SCNNode) {
        selectedNode = node
        if nodeTransforms[node] == nil {
            nodeTransforms[node] = (scale: 0.1, rotationY: 0)
        }
    }

    func rotateNode(with translation: CGPoint) {
        guard let node = selectedNode, let transform = nodeTransforms[node] else { return }
        let deltaAngle = Float(translation.x) * rotationSensitivity
        node.eulerAngles.y = transform.rotationY + deltaAngle
        nodeTransforms[node]?.rotationY += deltaAngle
    }

    func scaleNode(with scaleFactor: Float) {
        guard let node = selectedNode, let transform = nodeTransforms[node] else { return }
        let newScale = transform.scale * scaleFactor
        node.scale = SCNVector3(newScale, newScale, newScale)
        nodeTransforms[node]?.scale = newScale
    }

    func moveNode(by delta: SCNVector3) {
        guard let node = selectedNode else { return }
        node.position = SCNVector3(
            node.position.x + delta.x,
            node.position.y + delta.y,
            node.position.z + delta.z
        )
    }

    var selected: SCNNode? { selectedNode }
}


class GraphRendererManager {
    static func renderGraphs(configurations: [GraphingConfiguration], in sceneView: ARSCNView, rootNode: SCNNode) -> ([SCNNode], [SCNNode: [String: Any]]) {
        var graphNodes: [SCNNode] = []
        var nodeMap: [SCNNode: [String: Any]] = [:]

        for (index, config) in configurations.enumerated() {
            guard let renderer = GraphRendererRegistry.renderer(for: config.selectedGraph) else { continue }
            let (graphNode, map) = renderer.buildGraph(from: config, in: sceneView)
            graphNode.scale = SCNVector3(0.1, 0.1, 0.1)
            graphNode.position = SCNVector3(Float(index) * 0.15, 0.02, 0)
            rootNode.addChildNode(graphNode)
            graphNodes.append(graphNode)
            nodeMap.merge(map) { current, _ in current }
        }

        return (graphNodes, nodeMap)
    }
}



/*class ARViewController: UIViewController, ARSCNViewDelegate {
    var configurations: [GraphingConfiguration] = []
    var sceneView: ARSCNView!
    var graphNodes: [SCNNode] = []
    private var nodeMap: [SCNNode: [String: Any]] = [:]

    private let initialScale: Float = 0.1
    private let graphSpacing: Float = 0.15

    private var selectedNode: SCNNode?
    private var nodeTransforms: [SCNNode: (scale: Float, rotationY: Float)] = [:]
    private var hasPlacedGraph = false

    private var controlPanel: UIStackView?

    convenience init(configurations: [GraphingConfiguration]) {
        self.init()
        self.configurations = configurations
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

        addLighting()
        addGestureRecognizers()
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("📦 Anchor added to scene: \(anchor.name ?? "Unnamed")")

        if let planeAnchor = anchor as? ARPlaneAnchor {
            let extent = planeAnchor.extent
            let center = planeAnchor.center

            print("🧭 Horizontal plane detected: center = \(center), extent = \(extent)")

            let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
            plane.materials.first?.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.3)

            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            planeNode.position = SCNVector3(center.x, 0, center.z)
            node.addChildNode(planeNode)

            renderGraphs(on: node)
            hasPlacedGraph = true
        }
    }

    func renderGraphs(on rootNode: SCNNode) {
        for (index, config) in configurations.enumerated() {
            guard let renderer = GraphRendererRegistry.renderer(for: config.selectedGraph) else {
                print("⚠️ No renderer for graph type: \(String(describing: config.selectedGraph))")
                continue
            }

            let (graphNode, map) = renderer.buildGraph(from: config, in: sceneView)
            graphNode.scale = SCNVector3(initialScale, initialScale, initialScale)
            graphNode.position = SCNVector3(Float(index) * graphSpacing, 0.02, 0)

            rootNode.addChildNode(graphNode)
            graphNodes.append(graphNode)
            nodeMap.merge(map) { current, _ in current }
        }

        print("📊 Rendered \(graphNodes.count) graphs horizontally")
    }

    func addGestureRecognizers() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        singleTap.numberOfTapsRequired = 1

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2

        singleTap.require(toFail: doubleTap)

        sceneView.addGestureRecognizer(singleTap)
        sceneView.addGestureRecognizer(doubleTap)
        sceneView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        sceneView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
        print("🖐️ Gesture recognizers added")
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: sceneView)

        if hasPlacedGraph {
            let hitResults = sceneView.hitTest(tapLocation, options: nil)
            if let tappedNode = hitResults.first?.node, let data = nodeMap[tappedNode] {
                showDataOverlay(for: data, at: tappedNode.position)
                print("📍 Data point tapped")
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
        print("📌 Volcano anchor placed on table surface")
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(tapLocation, options: nil)

        guard let tappedNode = hitResults.first?.node else {
            print("⚠️ No graph node found at double-tap location")
            return
        }

        var currentNode: SCNNode? = tappedNode
        while let node = currentNode, !graphNodes.contains(node) {
            currentNode = node.parent
        }

        if let rootNode = currentNode {
            selectedNode = rootNode
            if nodeTransforms[rootNode] == nil {
                nodeTransforms[rootNode] = (scale: initialScale, rotationY: 0)
            }
            print("🎯 Graph root node selected for manipulation")
            showControlPanel()
        } else {
            print("⚠️ Tapped node is not part of a known graph")
        }
    }

    func showControlPanel() {
        controlPanel?.removeFromSuperview()

        let panel = UIStackView()
        panel.axis = .vertical
        panel.spacing = 8
        panel.translatesAutoresizingMaskIntoConstraints = false

        ["X", "Y", "Z"].forEach { axis in
            let label = UILabel()
            label.text = axis
            label.widthAnchor.constraint(equalToConstant: 20).isActive = true

            let plus = UIButton(type: .system)
            plus.setTitle("+", for: .normal)
            plus.addTarget(self, action: Selector("move\(axis)Plus"), for: .touchUpInside)

            let minus = UIButton(type: .system)
            minus.setTitle("–", for: .normal)
            minus.addTarget(self, action: Selector("move\(axis)Minus"), for: .touchUpInside)

            let row = UIStackView(arrangedSubviews: [label, minus, plus])
            row.axis = .horizontal
            row.spacing = 8
            panel.addArrangedSubview(row)
        }

        view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32)
        ])

        controlPanel = panel
        print("🎛️ Control panel displayed")
    }

    @objc func moveXPlus() { adjustPosition(delta: SCNVector3(0.01, 0, 0)) }
    @objc func moveXMinus() { adjustPosition(delta: SCNVector3(-0.01, 0, 0)) }
    @objc func moveYPlus() { adjustPosition(delta: SCNVector3(0, 0.01, 0)) }
    @objc func moveYMinus() { adjustPosition(delta: SCNVector3(0, -0.01, 0)) }
    @objc func moveZPlus() { adjustPosition(delta: SCNVector3(0, 0, 0.01)) }
    @objc func moveZMinus() { adjustPosition(delta: SCNVector3(0, 0, -0.01)) }

    func adjustPosition(delta: SCNVector3) {
        guard let node = selectedNode else { return }
        node.position = SCNVector3(
            node.position.x + delta.x,
            node.position.y + delta.y,
            node.position.z + delta.z
        )
        print("📦 Moved node to: \(node.position)")
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let node = selectedNode, let transform = nodeTransforms[node] else { return }

        let translation = gesture.translation(in: gesture.view)
        let deltaAngle = Float(translation.x) * (.pi / 180.0) / 2.0

        switch gesture.state {
        case .changed:
            node.eulerAngles.y = transform.rotationY + deltaAngle
            print("🔄 Rotating selected node: angle = \(node.eulerAngles.y)")
        case .ended, .cancelled:
            nodeTransforms[node]?.rotationY += deltaAngle
            print("✅ Final rotation stored: \(nodeTransforms[node]!.rotationY)")
        default:
            break
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let node = selectedNode, let transform = nodeTransforms[node] else { return }

        let scaleFactor = Float(gesture.scale)

        switch gesture.state {
        case .changed:
            let newScale = transform.scale * scaleFactor
            node.scale = SCNVector3(newScale, newScale, newScale)
            print("🔍 Scaling selected node: scale = \(newScale)")
        case .ended, .cancelled:
            nodeTransforms[node]?.scale *= scaleFactor
            print("✅ Final scale stored: \(nodeTransforms[node]!.scale)")
            gesture.scale = 1.0
        default:
            break
        }
    }

    func showDataOverlay(for data: [String: Any], at position: SCNVector3) {
        let summary = data.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let alert = UIAlertController(title: "Data Point", message: summary, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        print("📍 Data point tapped:\n\(summary)")
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
        nodeMap.merge(map) { current, _ in current }
    }
}
 */

struct ARViewContainer: UIViewControllerRepresentable {
    let configurations: [GraphingConfiguration]

    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController(configurations: configurations)
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

