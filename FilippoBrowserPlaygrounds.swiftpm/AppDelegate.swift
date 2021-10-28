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

class AppDelegate: UIResponder, UIApplicationDelegate {
	
	let fileManager = FileManager.default

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// Notification Permission request
		notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]){ _,_ in
			print("Notification Authorization Granted.")
		}

		return true
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Cleaning tmp directory (not sure it's really necessary for every launch but ok)
		let tempDir = fileManager.temporaryDirectory
		let tempDirContents = try? fileManager.contentsOfDirectory(atPath: tempDir.path)
		if let tempDirContents = tempDirContents{
			for tempFile in tempDirContents{
				try? fileManager.removeItem(atPath: tempDir.appendingPathComponent(tempFile).path)
			}
		}
	}
}
