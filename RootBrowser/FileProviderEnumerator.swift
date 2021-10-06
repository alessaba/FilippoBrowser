//
//  FileProviderEnumerator.swift
//  RootBrowser
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import FileProvider
import FBrowserPackage

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    var enumeratedItemIdentifier: NSFileProviderItemIdentifier
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }
	
	func createLocalReference(to sourcePath : String){
		let id = md5Identifier(sourcePath)
		identifierLookupTable[id] = sourcePath
		
		var isDir : ObjCBool = false
		
		if fm.fileExists(atPath: sourcePath, isDirectory: &isDir){
			let bookmarkPath = fm.temporaryDirectory.appendingPathComponent(id.rawValue).appendingPathComponent(URL(fileURLWithPath: sourcePath).lastPathComponent).path
			
			try? fm.removeItem(atPath: bookmarkPath)
			
			do {
				if !(fm.fileExists(atPath: bookmarkPath)){
					NSLog("Making directory: \(bookmarkPath)")
					try? fm.createDirectory(atPath: URL(fileURLWithPath: bookmarkPath).deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
					
					if (isDir.boolValue) {
						NSLog("Linking path...")
						try fm.createSymbolicLink(atPath: sourcePath, withDestinationPath: bookmarkPath)
						//try fm.linkItem(atPath: sourcePath, toPath: bookmarkPath)
						NSLog("Setting 0777 attributes...")
						try fm.setAttributes([FileAttributeKey.posixPermissions : 0777], ofItemAtPath: bookmarkPath)
					} else {
						NSLog("Copying file to sandbox..")
						try fm.copyItem(atPath: sourcePath, toPath: bookmarkPath)
					}
				}
			} catch {
				NSLog("Failed while creating local reference.")
			}
			
		} else {
			NSLog("Path does not exist.")
		}
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
		/*let fm = FileManager.default
		let subItems = try? fm.contentsOfDirectory(atPath: homeDirectory)
		var listing : [FileProviderItem] = []
		
		 for item in subItems ?? [] {
		  let fileProviderItem = FileProviderItem(path: URL(fileURLWithPath: homeDirectory).appendingPathComponent(item).absoluteString)
		  listing.append(fileProviderItem)
		}
		 */
		
		let homeItem = FSItem(path: homeDirectory)
		let listing : [FileProviderItem] = homeItem.subelements.map{ item in
			NSLog("Creating local reference to \(item.lastComponent).")
			createLocalReference(to: item.path)
			return FileProviderItem(path: item.path)
		}

		NSLog("Trying to enumerate\n\(listing.description)")
		observer.didEnumerate(listing)
		
		// We're returning everything as a single page here (upToPAge: nil)
		// TOOD: Since the extension is given a very small amount of memory,
		// paginating the results may be necessary for directories with lots
		// of files.
		observer.finishEnumerating(upTo: nil)
    }
	
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
    }
}
