//
//  FileProviderEnumerator.swift
//  RootBrowser
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import FileProvider

func createLocalReference(to sourceURL : URL){
	let id = md5Identifier(sourceURL)
	identifierLookupTable[id] = sourceURL
	
	//NSFileProviderManager.default.documentStorageURL
	let bookmarkURL = NSFileProviderManager.default.documentStorageURL.appendingPathComponent(id.rawValue).appendingPathComponent( sourceURL.lastPathComponent)
	
	var isDir : ObjCBool = false
	filemanager.fileExists(atPath: sourceURL.path, isDirectory: &isDir)
	try? filemanager.removeItem(at: bookmarkURL)
	
	if !(filemanager.fileExists(atPath: bookmarkURL.path)){
		NSLog("Making directory: \(bookmarkURL)")
		try? filemanager.createDirectory(atPath: bookmarkURL.deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
		
		if (isDir.boolValue) {
			NSLog("Linked path: \(String(describing: try? filemanager.linkItem(at: sourceURL, to: bookmarkURL)))")
			NSLog("Setting attributes: \(String(describing: try? filemanager.setAttributes([FileAttributeKey.posixPermissions : 0777], ofItemAtPath: bookmarkURL.path)))")
		} else {
			NSLog("File copy to sandbox: \(String(describing: try? filemanager.copyItem(at: sourceURL, to: bookmarkURL)))")
		}
	}
}

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    var enumeratedItemIdentifier: NSFileProviderItemIdentifier
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }
	

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request
         
         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database
         
         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
		*/
		
		guard let basePath = identifierLookupTable[self.enumeratedItemIdentifier] else {
			NSLog("NO BASE PATH!!")
			return
		}
		
		var isDir : ObjCBool = false
		filemanager.fileExists(atPath: basePath.path, isDirectory: &isDir)
		
		if (isDir.boolValue){
			let listingPaths : [String] = subelements(url: basePath)
			
			let listing : [FileProviderItem] = listingPaths.map{ item in
				let newP = basePath.appendingPathComponent(item)
				NSLog("Creating local reference to \(newP.path).")
				createLocalReference(to: newP)
				return FileProviderItem(url: newP)
			}
			
			NSLog("Trying to enumerate\n\(listing.description)")
			observer.didEnumerate(listing)
		}
		
		// We're returning everything as a single page here (upToPAge: nil)
		// TOOD: Since the extension is given a very small amount of memory,
		// paginating the results may be necessary for directories with lots
		// of files.
		observer.finishEnumerating(upTo: nil)
    }
	/*
	func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
		completionHandler(nil)
	}
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
    }*/
}
