//
//  SceneDelegate.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 09/06/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import SwiftUI
import WatchConnectivity
import UserNotifications

let notificationCenter = UNUserNotificationCenter.current()


class AppDelegate: UIResponder, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		// Notification Permission request
		notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]){ _,_ in
			print("Notification Authorization Granted.")
		}
		
		return true
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Cleaning tmp directory (not sure it's really necessary for every launch but ok)
		let fm = FileManager.default
		let tempDir = fm.temporaryDirectory
		let tempDirContents = try? fm.contentsOfDirectory(atPath: tempDir.path)
		if let tempDirContents = tempDirContents{
			for tempFile in tempDirContents{
				try? fm.removeItem(atPath: tempDir.appendingPathComponent(tempFile).path)
			}
		}
	}
	
	// MARK: UISceneSession Lifecycle
	
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		let sceneConf = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
		sceneConf.delegateClass = SceneDelegate.self
		return sceneConf
	}
}


class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate, WCSessionDelegate {

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
	
	
	func scene(_ scene: UIScene,
			   willConnectTo session: UISceneSession,
			   options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		
		/* Process the quick action if the user selected one to launch the app.
		 Grab a reference to the shortcutItem to use in the scene.*/
		
		// Apple Watch Session activation
		print("Session supported: \(WCSession.isSupported())")
		if WCSession.isSupported(){
			let watchSession = WCSession.default
			watchSession.delegate = self
			watchSession.activate()
		} else {
			print("Device not supported or Apple Watch is not paired.")
		}
		
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

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
		
		print("Scene Did Become Active")
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
		UIApplication.shared.applicationIconBadgeNumber = 0
	}

	
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification,
								withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		
		//https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter
		
		print("Notification while open: \(notification.request.content.userInfo)")
		let path = notification.request.content.userInfo["path"] as! String
		sheetBrowser((self.window?.windowScene)!, at: URL(fileURLWithPath: path))
	}
	
	
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								didReceive response: UNNotificationResponse,
								withCompletionHandler completionHandler: @escaping () -> Void) {
		
		
		//https://developer.apple.com/reference/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter
		
		
		print("Opened Notification from Background: \(response.notification.request.content.userInfo)")
		
		let path = response.notification.request.content.userInfo["path"] as! String
		sheetBrowser((self.window?.windowScene)!, at: URL(fileURLWithPath: path))
		
		completionHandler()
	}
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("Session Reachable:\(session.isReachable)\nActivation State:\(activationState.rawValue == 2 ? "Activated" : "Not Active")")
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		print("Session Became inactive")
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
		print("Session deactivated")
	}
	
	func session(_ session: WCSession,
				 didReceive file: WCSessionFile) {
		// Function that runs when the iPhone receives a file from the Watch
		let docsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
		
		print("Receiving file from watch.")
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
			print("WatchConnectivity file transfer failed :-(")
		}
	}
}

