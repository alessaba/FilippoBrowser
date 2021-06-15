//
//  HostingController.swift
//  FilippoBrowser WatchKit Extension
//
//  Created by Alessandro Saba on 20/09/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI
import WatchConnectivity
import FBrowserPackage

class HostingController: WKHostingController<DirectoryBrowser>, WCSessionDelegate {
    override var body: DirectoryBrowser {
		
		if WCSession.isSupported(){
			let session = WCSession.default
			session.delegate = self
			session.activate()
			NSLog("Session Activated")
		} else {
			NSLog("Session not supported")
		}
		
        return DirectoryBrowser(directory: FSItem(path: "/"))
    }
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		NSLog("Session Reachable:\(session.isReachable)")
		NSLog("Activation State:\(activationState.rawValue == 2 ? "Activated" : "Not Active")")
	}
}
