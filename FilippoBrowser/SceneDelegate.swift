//
//  SceneDelegate.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 09/06/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import UIKit
import SwiftUI
import WatchConnectivity

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	
	func isFolder(_ url : URL) -> Bool {
		var isFoldr : ObjCBool = false
		FileManager.default.fileExists(atPath: url.path, isDirectory: &isFoldr)
		return isFoldr.boolValue
	}
	
	func launchShortcut(_ shortcut : UIApplicationShortcutItem, with scene : UIScene){
		let path = UserDefaults.standard.string(forKey: shortcut.type) ?? "/" // We use the type to reference a path in the User Defaults
		let pathURL = URL(fileURLWithPath: path)
		launchBrowser(scene, at: pathURL)
	}
	
	func watchSessionActivate(){
		// Apple Watch Session activation
		NSLog("Session supported: \(WCSession.isSupported())")
		if WCSession.isSupported(){
			let watchSession = WCSession.default
			let delegate = WatchDelegate()
			watchSession.delegate = delegate
			watchSession.activate()
		} else {
			NSLog("Device not supported or Apple Watch is not paired.")
		}
	}
	
	func launchBrowser(_ scene: UIScene, at url: URL){
		var launchPath : String = url.path + "/"
		
		// Se l'URL punta a un file, rimanda alla cartella che lo contiene
		if !(isFolder(url)){
			launchPath = url.deletingLastPathComponent().path + "/"
		}
		
		watchSessionActivate()
		
		DispatchQueue.main.async {
			if let windowScene = scene as? UIWindowScene {
				let contentView = Browser(path: launchPath)
				let window = UIWindow(windowScene: windowScene)
				window.rootViewController = UIHostingController(rootView: contentView)
				self.window = window
				window.makeKeyAndVisible()
			}
		}
	}
	
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		
		/* Process the quick action if the user selected one to launch the app.
		 Grab a reference to the shortcutItem to use in the scene.*/
		
		if let shortcutItem = connectionOptions.shortcutItem {
			launchShortcut(shortcutItem, with: scene)
		} else {
			// Set the content to a Directory View (grid or list style) for the chosen path.
			// The path is "/" by default, or the one chosen by 3D Touch shortcut
			let contentView = Browser(path: "/")
			
			// Use a UIHostingController as window root view controller.
			if let windowScene = scene as? UIWindowScene {
				let window = UIWindow(windowScene: windowScene)
				window.rootViewController = UIHostingController(rootView: contentView)
				self.window = window
				window.makeKeyAndVisible()
			}
		}
    }
	
	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
		launchShortcut(shortcutItem, with: windowScene)
		return true
	}
	
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		if let url = URLContexts.first?.url {
			launchBrowser(scene, at: url)
		}
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
		
		NSLog("Scene Did Become Active")
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
}

class WatchDelegate : NSObject, WCSessionDelegate {
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		// Print info related to the watch session
		NSLog("Session Reachable:\(session.isReachable)\nActivation State:\(activationState.rawValue == 2 ? "Activated" : "Not Active")")
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		NSLog("Session Became inactive")
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
		NSLog("Session deactivated")
	}
	
	func session(_ session: WCSession, didReceive file: WCSessionFile) {
		// Function that runs when the iPhone receives a file from the Watch
		let docsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
		
		// Tries to copy the item to the documents folder, and notify the user
		do{
			try FileManager.default.copyItem(at: file.fileURL, to: URL(fileURLWithPath: docsDirectory))
			
			let filename = String(file.fileURL.absoluteString.split(separator: "/").last ?? "a file")
			
			let notificationContent = UNMutableNotificationContent()
			notificationContent.badge = 1
			notificationContent.title = "Watch File"
			notificationContent.body = "Your Apple Watch just shared \(filename) with you 😃"
			
			let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
			let request = UNNotificationRequest(identifier: "watchFilePending", content: notificationContent, trigger: trigger)
			
			notificationCenter.add(request, withCompletionHandler: nil)
		} catch {
			NSLog("WatchConnectivity file transfer failed :-(")
		}
	}
}

