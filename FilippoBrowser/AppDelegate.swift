//
//  AppDelegate.swift
//  FilippoBrowser
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import UIKit
import WatchConnectivity
import UserNotifications

public let un = UNUserNotificationCenter.current()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		NSLog("WatchConnectivity session completed with status: \(activationState.rawValue)")
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		// Session Inactive
		NSLog("Session Became inactive")
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
		// Session deactivated
		NSLog("Session deactivated")
	}
	
	func session(_ session: WCSession, didReceive file: WCSessionFile) {
		let fm = FileManager.default
		let docsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
		
		do{
			try fm.copyItem(at: file.fileURL, to: URL(string: "file://\(docsDirectory)")!)
			
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

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		
		un.requestAuthorization(options: [.alert, .sound, .badge]){ _,_ in
			NSLog("Notification Authorization Granted.")
		}
		
		NSLog("Session supported: \(WCSession.isSupported())")
		if WCSession.isSupported(){
			let watchSession = WCSession.default
			watchSession.delegate = self
			watchSession.activate()
		} else {
			NSLog("Device not supported or Apple Watch is not paired.")
		}
		
		return true
	}
	
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		let path = UserDefaults.standard.string(forKey: shortcutItem.type)
		
		if (path != nil) {
			#warning("should launch the app with the path from the shortcut")
			NSLog("Trying to open \(path!) folder")
			
			//let contentView = Browser(path: path!)
			
		}
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
