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

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {

	var window: UIWindow?
	
	func isFolder(_ url : URL) -> Bool {
		var isFoldr : ObjCBool = false
		FileManager.default.fileExists(atPath: url.path, isDirectory: &isFoldr)
		return isFoldr.boolValue
	}
	
	func launchShortcut(_ shortcut : UIApplicationShortcutItem, with scene : UIScene){
		let path = UserDefaults.standard.string(forKey: shortcut.type) ?? "/" // We use the type to reference a path in the User Defaults
		let pathURL = URL(fileURLWithPath: path)
		sheetBrowser(scene, at: pathURL)
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
	
	func sheetBrowser(_ scene: UIScene, at url: URL){
		let launchPath : String = url.path + "/"
		
		// Se l'URL punta a un file, rimanda alla cartella che lo contiene
		/*if !(isFolder(url)){
			launchPath = url.deletingLastPathComponent().path + "/"
		}*/
		
		DispatchQueue.main.async {
			if let windowScene = scene as? UIWindowScene {
				let contentView = Browser(path: launchPath, presentSheet: true)
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
		
		watchSessionActivate()
		notificationCenter.delegate = self
		
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
			sheetBrowser(scene, at: url)
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
		UIApplication.shared.applicationIconBadgeNumber = 0
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
	
	
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification,
								withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		
		/**
		 If your app is in the foreground when a notification arrives, the notification center calls this method to deliver the notification directly to your app. If you implement this method, you can take whatever actions are necessary to process the notification and update your app. When you finish, execute the completionHandler block and specify how you want the system to alert the user, if at all.
		 
		 If your delegate does not implement this method, the system silences alerts as if you had passed the UNNotificationPresentationOptionNone option to the completionHandler block. If you do not provide a delegate at all for the UNUserNotificationCenter object, the system uses the notification’s original options to alert the user.
		 
		 see https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter
		 
		 **/
		
		print("Notification while open: \(notification.request.content.userInfo)")
		let path = notification.request.content.userInfo["path"] as! String
		sheetBrowser((self.window?.windowScene)!, at: URL(fileURLWithPath: path))
	}
	
	
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								didReceive response: UNNotificationResponse,
								withCompletionHandler completionHandler: @escaping () -> Void) {
		
		/**
		 Use this method to perform the tasks associated with your app’s custom actions. When the user responds to a notification, the system calls this method with the results. You use this method to perform the task associated with that action, if at all. At the end of your implementation, you must call the completionHandler block to let the system know that you are done processing the notification.
		 
		 You specify your app’s notification types and custom actions using UNNotificationCategory and UNNotificationAction objects. You create these objects at initialization time and register them with the user notification center. Even if you register custom actions, the action in the response parameter might indicate that the user dismissed the notification without performing any of your actions.
		 
		 If you do not implement this method, your app never responds to custom actions.
		 
		 see https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter
		 
		 **/
		
		print("Opened Notification from Background: \(response.notification.request.content.userInfo)")
		
		let path = response.notification.request.content.userInfo["path"] as! String
		sheetBrowser((self.window?.windowScene)!, at: URL(fileURLWithPath: path))
		
		completionHandler()
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
			let iphonePath : String = docsDirectory + file.fileURL.lastPathComponent
			try FileManager.default.copyItem(at: file.fileURL, to: URL(fileURLWithPath: iphonePath))
			
			let filename = String(file.fileURL.absoluteString.split(separator: "/").last ?? "a file")
			
			let notificationContent = UNMutableNotificationContent()
			notificationContent.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
			notificationContent.title = "Watch File"
			notificationContent.body = "Your Apple Watch just shared \(filename) with you 😃"
			notificationContent.userInfo = ["path" : iphonePath]
			
			let trigger : UNNotificationTrigger? = nil // Notification delivered instantly
			let request = UNNotificationRequest(identifier: "watchFilePending", content: notificationContent, trigger: trigger)
			
			notificationCenter.add(request, withCompletionHandler: nil)
		} catch {
			NSLog("WatchConnectivity file transfer failed :-(")
		}
	}
}

