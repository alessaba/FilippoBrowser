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

class HostingController: WKHostingController<DirectoryBrowser>{
    override var body: DirectoryBrowser {
		// Show the Root of the Watch's File System as the starting view
        return DirectoryBrowser(directory: FSItem(path: "/"))
	}
}
