//
//  BridgedViews.swift
//  FilippoBrowser
//
//  Created by Filippo Claudi on 10/06/21.
//  Copyright © 2021 Filippo Claudi. All rights reserved.
//

import Foundation
import SwiftUI
import FBrowserPackage

import UIKit
import QuickLook
import SceneKit


struct ActivityView: UIViewControllerRepresentable {
	// Port of the UIActivityViewController to SwiftUI. basically we proxy the arguments then conform to the protocol.
	let activityItems: [Any]
	let applicationActivities: [UIActivity]?
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
		return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
	}
	
	func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) { NSLog("ActivityVC called") }
}

struct SceneView: UIViewControllerRepresentable {
	let filePath: String
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<SceneView>) -> UIViewController {
		let scene = SCNScene(named: String(filePath.dropLast()))
		let sceneView = SCNView()
		sceneView.allowsCameraControl = true
		//sceneView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
		sceneView.scene = scene!
		sceneView.isJitteringEnabled = true //Smooth the movement
		sceneView.antialiasingMode = .multisampling2X // Lotta power needed but lil bit smoothr
		sceneView.preferredFramesPerSecond = 60
		sceneView.showsStatistics = true
		
		//scene?.rootNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 10, z: 0, duration: 5)))
		
		let camera = SCNCamera()
		let camera_node = SCNNode()
		camera_node.camera = camera
		camera_node.position = SCNVector3(-3,3,3)
		
		sceneView.scene?.rootNode.addChildNode(camera_node)
		
		let sceneVC = UIViewController()
		sceneVC.view = sceneView
		return sceneVC
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<SceneView>) { NSLog("SceneVC called.") }
}

struct QuickLookView: UIViewControllerRepresentable {
	let filePath: String
	
	class QuickLookDataSource : NSObject, QLPreviewControllerDataSource{
		let parent: QuickLookView
		
		init(parent: QuickLookView) { self.parent = parent }
		
		func numberOfPreviewItems(in controller: QLPreviewController) -> Int { return 1 }
		
		func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
			let tempPath = (tmp_directory.appendingPathComponent(String(parent.filePath.split(separator: "/").last ?? "")))
			
			do{
				try FileManager.default.copyItem(at: URL(string: "file://\(parent.filePath)")!, to: tempPath)
			} catch {
				print("Failed to copy to tmp")
			}
			
			return tempPath as NSURL
		}
	}
	
	func makeCoordinator() -> QuickLookDataSource {
		return QuickLookDataSource(parent: self)
	}
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<QuickLookView>) -> UIViewController {
		let qv = QLPreviewController()
		qv.dataSource = context.coordinator
		
		let navigationController = UINavigationController(rootViewController: qv)
		return navigationController
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<QuickLookView>) { NSLog("QuickLook called.") }
}
