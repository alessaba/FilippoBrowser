//
//  AppDelegate.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 09/06/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import UIKit
import UserNotifications

let notificationCenter = UNUserNotificationCenter.current()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	let fileManager = FileManager.default

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		// Notification Permission request
		notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]){ _,_ in
			print("Notification Authorization Granted.")
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
