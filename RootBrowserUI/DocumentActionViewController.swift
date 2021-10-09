//
//  DocumentActionViewController.swift
//  RootBrowserUI
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import UIKit
import FileProviderUI

class DocumentActionViewController: FPUIActionExtensionViewController {
    override func prepare(forAction actionIdentifier: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
		#warning("Fetch path from lookupTable, then get the path and add the path to FilippoBrowser's Bookmarks")
		
		print("Completing task...")
		//extensionContext.completeRequest()
    }
    
    override func prepare(forError error: Error) {
		print("Error \(error.localizedDescription)")
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
    }
    
}

