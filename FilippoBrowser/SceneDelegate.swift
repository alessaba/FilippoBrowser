//
//  SceneDelegate.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 09/06/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import UIKit
import SwiftUI

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
	
	func launchBrowser(_ scene: UIScene, at url: URL){
		var launchPath : String = url.path + "/"
		
		// Se l'URL punta a un file, rimanda alla cartella che lo contiene
		if !(isFolder(url)){
			launchPath = url.deletingLastPathComponent().path + "/"
		}
		
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

