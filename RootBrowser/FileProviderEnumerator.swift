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
	let bookmarkURL = filemanager.temporaryDirectory.appendingPathComponent(id.rawValue).appendingPathComponent( sourceURL.lastPathComponent)
	
	var isDir : ObjCBool = false
	filemanager.fileExists(atPath: sourceURL.path, isDirectory: &isDir)
	try? filemanager.removeItem(at: bookmarkURL)
	
	if !(filemanager.fileExists(atPath: bookmarkURL.path)){
		//print("Making directory: \(bookmarkURL)")
		try? filemanager.createDirectory(atPath: bookmarkURL.deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
		
		if (isDir.boolValue) { // Folders gets linked and its attributes are set
			try? filemanager.linkItem(at: sourceURL, to: bookmarkURL)
			try? filemanager.setAttributes([FileAttributeKey.posixPermissions : 0777], ofItemAtPath: bookmarkURL.path)
		} else { // Files are copied to the temp directory or symlinked
			// If the UTI is not supported, don't bother copying it, wasting resources
			if uti(for: sourceURL).hasPrefix("dyn"){
				try? filemanager.createSymbolicLink(at: bookmarkURL, withDestinationURL: sourceURL)
			} else {
				try? filemanager.copyItem(at: sourceURL, to: bookmarkURL)
			}
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
		
		guard let baseURL = identifierLookupTable[self.enumeratedItemIdentifier] else {
			print("NO BASE PATH!!")
			return
		}
		
		var isDir : ObjCBool = false
		filemanager.fileExists(atPath: baseURL.path, isDirectory: &isDir)
		
		if (isDir.boolValue){
			let listingPaths : [String] = subelements(url: baseURL)
			
			let listing : [FileProviderItem] = listingPaths.map{ item in
				let newP = baseURL.appendingPathComponent(item)
				createLocalReference(to: newP)
				
				return FileProviderItem(url: newP)
			}
			
			//print("Trying to enumerate\n\(baseURL.path)")
			observer.didEnumerate(listing)
		}
		
		// We're returning everything as a single page here (upToPAge: nil)
		// TOOD: Since the extension is given a very small amount of memory,
		// paginating the results may be necessary for directories with lots
		// of files.
		#warning("Research how to do pagination for folders with more than 50-500 subfolders")
		observer.finishEnumerating(upTo: nil)
    }
	
	#warning("Should research what these two functions must do")
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
		print("Enumerating Changes: \(observer.description)")
    }
}
