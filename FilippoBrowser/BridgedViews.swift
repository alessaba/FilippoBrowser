//
//  BridgedViews.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 10/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

// Bridging Views from UIKit to SwiftUI

import Foundation
import SwiftUI
import FBrowserPackage

import UIKit
import QuickLook
import SceneKit


// MARK: Share Sheet
struct ShareView: UIViewControllerRepresentable {
	// We proxy the arguments of the UIKit version
	let activityItems: [Any]
	let applicationActivities: [UIActivity]? = nil
	
	// Then conform to the SwiftUI bridging protocol with the 2 functions below.
	// We return the ViewController we want to bridge to SwiftUI
	func makeUIViewController(context: UIViewControllerRepresentableContext<ShareView>) -> UIActivityViewController {
		return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
	}
	
	// In case we want to update something when the Bridged View is used
	func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareView>) { print("ActivityVC used") }
}


// MARK: 3D Objects View
struct SceneView: UIViewControllerRepresentable {
	let filePath: String // We do everything starting from a simple file path
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<SceneView>) -> UIViewController {
		let scene = SCNScene(named: String(filePath.dropLast()))
		
		// We need a SceneView (for the 3D object itself), a camera (to look at the object), and a node (to position the camera)
		let sceneView = SCNView()
		let camera = SCNCamera()
		let camera_node = SCNNode()
		
		// 3D Object SceneView configuration
		sceneView.allowsCameraControl = true
		sceneView.scene = scene!
		sceneView.isJitteringEnabled = true // Smooth the movement
		sceneView.antialiasingMode = .multisampling2X // Lots of power needed but a little bit smoother
		sceneView.preferredFramesPerSecond = 60
		sceneView.showsStatistics = true
		
		// Camera configuration
		camera_node.camera = camera
		camera_node.position = SCNVector3(-3,3,3)
		
		// Add the Camera to the SceneView
		sceneView.scene?.rootNode.addChildNode(camera_node)
		
		// Auto Rotation for the 3D Object. We can't really interact with our fingerso though
		//scene?.rootNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 10, z: 0, duration: 5)))
		
		// We embed the Scene View into a ViewController, because we can't return a View, but a ViewController
		let sceneVC = UIViewController()
		sceneVC.view = sceneView
		
		return sceneVC
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<SceneView>) { print("SceneVC used.") }
}


// MARK: QuickLook View
struct QuickLook: UIViewControllerRepresentable {
	let filePath: String // We do everything starting from a simple file path
	
	
	// We define a class that conforms to a DataSource for QuickLook
	class QuickLookDataSource : NSObject, QLPreviewControllerDataSource{
		// We need this parameter to link the DataSource to the PreviewController properly.
		// (https://quickbirdstudios.com/blog/coordinator-pattern-in-swiftui/)
		let parent: QuickLook
		init(parent: QuickLook) { self.parent = parent }
		
		// We are only going to preview 1 file at a time, but if we want we can just count the items in a array of filePaths
		func numberOfPreviewItems(in controller: QLPreviewController) -> Int { return 1 }
		
		func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
			let tempURL = tmp_directory.urlByAppending(path: FSItem(path: parent.filePath).lastComponent)
			
			do{
				try FileManager.default.copyItem(at: URL(fileURLWithPath: parent.filePath), to: tempURL)
			} catch {
				print("Failed to copy to tmp")
			}
			
			return tempURL as NSURL
		}
	}
	
	// Read the article above to understand better how coordinators work
	func makeCoordinator() -> QuickLookDataSource {
		return QuickLookDataSource(parent: self)
	}
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<QuickLook>) -> UIViewController {
		let qv = QLPreviewController()
		qv.dataSource = context.coordinator // The coordinator is in fact the dataSource we need
		
		// We embed inside a Navigation Controller to have features such as share button and Title
		let navigationController = UINavigationController(rootViewController: qv)
		return navigationController
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<QuickLook>) { print("QuickLook used.") }
}

// MARK: UIDocumentBrowserViewController
struct FilesDocumentBrowser : UIViewControllerRepresentable {
	// Then conform to the SwiftUI bridging protocol with the 2 functions below.
	// We return the ViewController we want to bridge to SwiftUI
	func makeUIViewController(context: UIViewControllerRepresentableContext<FilesDocumentBrowser>) -> UIDocumentBrowserViewController {
		return UIDocumentBrowserViewController()
	}
	
	// In case we want to update something when the Bridged View is used
	func updateUIViewController(_ uiViewController: UIDocumentBrowserViewController, context: UIViewControllerRepresentableContext<FilesDocumentBrowser>) { print("UIDocumentBrowserViewController used") }
}
