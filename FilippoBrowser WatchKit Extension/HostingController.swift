//
//  HostingController.swift
//  FilippoBrowser WatchKit Extension
//
//  Created by Filippo Claudi on 20/09/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI
import FBrowser_Watch

class HostingController: WKHostingController<DirectoryBrowser> {
    override var body: DirectoryBrowser {
        return DirectoryBrowser(directory: FSItem(path: "/"))
    }
}
