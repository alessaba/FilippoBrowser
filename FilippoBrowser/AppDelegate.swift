//
//  AppDelegate.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 09/06/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import UIKit
import WatchConnectivity
import UserNotifications

let un = UNUserNotificationCenter.current()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
	
	let fileManager = FileManager.default

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		// Print info related to the watch session
		NSLog("Session Reachable:\(session.isReachable)\nActivation State:\(activationState.rawValue == 2 ? "Activated" : "Not Active")")
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		// Watch Session Inactive
		NSLog("Session Became inactive")
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
		// Watch Session deactivated
		NSLog("Session deactivated")
	}
	
	func session(_ session: WCSession, didReceive file: WCSessionFile) {
		// Function that runs when the iPhone receives a file from the Watch
		let docsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
		
		// Tries to copy the item to the documents folder, and notify the user
		do{
			try fileManager.copyItem(at: file.fileURL, to: URL(fileURLWithPath: docsDirectory))
			
			let filename = String(file.fileURL.absoluteString.split(separator: "/").last ?? "a file")
			
			let notificationContent = UNMutableNotificationContent()
			notificationContent.badge = 1
			notificationContent.title = "Watch File"
			notificationContent.body = "Your Apple Watch just shared \(filename) with you 😃"
			
			let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
			let request = UNNotificationRequest(identifier: "watchFilePending", content: notificationContent, trigger: trigger)
			
			un.add(request, withCompletionHandler: nil)
		} catch {
			NSLog("WatchConnectivity file transfer failed :-(")
		}
	}
	
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		#warning("This function never gets called...")
		
		lancia(shortcutItem: shortcutItem)
	}
	
	func lancia(shortcutItem: UIApplicationShortcutItem){
		
		NSLog("Lancia Shortcut Chiamato!")
		
		let path = UserDefaults.standard.string(forKey: shortcutItem.type)
		if (path != nil) {
			NSLog("Trying to open \(path!) folder")
			UserDefaults.standard.setValue(path ?? "/", forKey: "pathToLaunch")
		}
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		// Notification Permission request
		un.requestAuthorization(options: [.alert, .sound, .badge]){ _,_ in
			NSLog("Notification Authorization Granted.")
		}
		
		// Apple Watch Session activation
		NSLog("Session supported: \(WCSession.isSupported())")
		if WCSession.isSupported(){
			let watchSession = WCSession.default
			watchSession.delegate = self
			watchSession.activate()
		} else {
			NSLog("Device not supported or Apple Watch is not paired.")
		}
		
		// Launch from 3D Touch shortcuts
		if let shortcutsItems = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
			lancia(shortcutItem: shortcutsItems)
		}
		
		// Cleaning tmp directory (not sure it's really necessary for every launch but ok)
		let tempDir = fileManager.temporaryDirectory
		let tempDirContents = try? fileManager.contentsOfDirectory(atPath: tempDir.path)
		if let tempDirContents = tempDirContents{
			for tempFile in tempDirContents{
				try? fileManager.removeItem(atPath: tempDir.appendingPathComponent(tempFile).path)
			}
		}
		
		
		return true
	}
	
	

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}
