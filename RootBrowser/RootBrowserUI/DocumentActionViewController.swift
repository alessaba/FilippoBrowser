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
	
	 let userDefaults = UserDefaults.standard
	
    override func prepare(forAction actionIdentifier: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
		#warning("Fetch path from lookupTable, then get the path and add the path to FilippoBrowser's Bookmarks")
		
		print("Completing task...")
		for id in itemIdentifiers{
			let url = identifierLookupTable[id]
			guard (url != nil) else {
				print("Couln't get path from lookup table")
				return
			}
			print("typeID: \(FileProviderItem(url: url!).typeIdentifier)")
			self.userDefaults.set(url!.path, forKey: "FB_\(url!.lastPathComponent)")
		}
		print("Done!")
		self.userDefaults.synchronize()
		extensionContext.completeRequest()
    }
    
    override func prepare(forError error: Error) {
		print("Error \(error.localizedDescription)")
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
    }
    
}

