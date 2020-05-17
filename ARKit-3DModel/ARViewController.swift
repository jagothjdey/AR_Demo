import Foundation
import ARKit

struct Node {
    var position : SCNVector3
}

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    var nodeArray : [Node] = [Node]()
    var frameUpdated : Bool = false
    
    var time = 0.0
    var timer = Timer()
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func resetTimer() {
        timer.invalidate()
        time = 0
        startTimer()
    }
    
    @objc func updateTime() {
        if time < 0.1 {
            time += 0.05
        } else {
            resetTimer()
        }
    }
    
    lazy var sceneView: ARSCNView = {
        let view = ARSCNView(frame: CGRect.zero)
        view.delegate = self
        view.session.delegate = self
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = SCNAntialiasingMode.multisampling4X
        view.preferredFramesPerSecond = 30
        view.rendersContinuously = false
        return view
    }()
    
    lazy var captureButtton : UIButton = {
        let button = UIButton(frame: CGRect(x: view.bounds.width/2 - 30, y: view.bounds.height-140, width: 60, height: 60))
        button.backgroundColor = UIColor.blue
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(sceneView)
        view.addSubview(captureButtton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = view.bounds
        captureButtton.frame = CGRect(x: view.bounds.width/2 - 30, y: view.bounds.height-100, width: 60, height: 60)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: .resetTracking)
        startTimer()
    }
    
    @objc func captureButtonPressed(sender: UIButton) {
        frameUpdated = true
        let screenCenterLocation = self.sceneView.center
        let hitTestResults = sceneView.hitTest(screenCenterLocation, types: .featurePoint)
        
        if let result = hitTestResults.first {
            let position = SCNVector3.positionFrom(matrix: result.worldTransform)
            nodeArray.append(Node(position: position))
        }
    }
    
    func showCenterLocation()->SCNNode{
        let screenCenterLocation = self.sceneView.center
        
        let hitTestResults = sceneView.hitTest(screenCenterLocation, types: .featurePoint)
        
        if let result = hitTestResults.first {
            let position = SCNVector3.positionFrom(matrix: result.worldTransform)
            let markerNode = makeMarkerNode(position, 4)
            return markerNode
        }
        
        return SCNNode()
    }
    
    func makeMarkerNode(_ position : SCNVector3,_ color : Int)->SCNNode{
        guard let markerScene = SCNScene(named: "pointer_location_map.obj") else { return SCNNode() }
        let markerNode = SCNNode()
        let markerSceneChildNodes = markerScene.rootNode.childNodes
        for childNode in markerSceneChildNodes {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor.green
            childNode.geometry?.materials = [material]
            markerNode.addChildNode(childNode)
        }
        markerNode.scale = SCNVector3(0.0001, 0.0001, 0.0001)
        markerNode.position = position
        return markerNode
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frameUpdated{
            nodeArray.forEach { (node) in
                sceneView.scene.rootNode.addChildNode(makeMarkerNode(node.position, 4))
            }
            frameUpdated = false
        }
        
        if time != 0.1 {
            return
        } else {
            let lastNode = sceneView.scene.rootNode.childNodes.last
            lastNode?.removeFromParentNode()
            let newNode = showCenterLocation()
            sceneView.scene.rootNode.addChildNode(newNode)
        }
    }
}

extension SCNVector3 {
    static func distance(from a: SCNVector3, to b: SCNVector3)-> CGFloat {
        return CGFloat (sqrt(
            (a.x - b.x) * (a.x - b.x)
                +   (a.y - b.y) * (a.y - b.y)
                +   (a.z - b.z) * (a.z - b.z)))
    }
    
    static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
        let column = matrix.columns.3
        return SCNVector3(column.x, column.y, column.z)
    }
}

extension ARSCNView {
    func realWorldPosition(for point: CGPoint) -> SCNVector3? {
        let result = self.hitTest(point, types: [.featurePoint])
        guard let hitResult = result.last else { return nil }
        let hitTransform = SCNMatrix4(hitResult.worldTransform)
        let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        return hitVector
    }
}
