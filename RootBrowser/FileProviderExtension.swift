//
//  FileProviderExtension.swift
//  RootBrowser
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import FileProvider

let docPath = NSFileProviderManager.default.documentStorageURL

class FileProviderExtension: NSFileProviderExtension {
	
    override init() {
        super.init()
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        // resolve the given identifier to a record in the model
		if let url = identifierLookupTable[identifier]{
			return FileProviderItem(url: url)
		} else {
			return FileProviderItem(url: homeDirectory)
		}
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        // resolve the given identifier to a file on disk
		guard let sourceURL = identifierLookupTable[identifier] else {
			NSLog("source URL not in lookup table")
			return nil
		}
		var isDir : ObjCBool = false
		
		if filemanager.fileExists(atPath: sourceURL.path, isDirectory: &isDir){
			let bookmarkURL = NSFileProviderManager.default.documentStorageURL.appendingPathComponent(identifier.rawValue).appendingPathComponent(URL(fileURLWithPath: sourceURL.path).lastPathComponent)
			return bookmarkURL
		} else {
			NSLog("source path does not exist.")
			return nil
		}
    }
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        // resolve the given URL to a persistent identifier using a database
        let pathComponents = url.pathComponents
        
        // exploit the fact that the path structure has been defined as
        // <base storage directory>/<item identifier>/<item file name> above
        assert(pathComponents.count > 2)
        
        return NSFileProviderItemIdentifier(pathComponents[pathComponents.count - 2])
    }
    
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        /*guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        do {
            let fileProviderItem = try item(for: identifier)
            let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
            try NSFileProviderManager.writePlaceholder(at: placeholderURL,withMetadata: fileProviderItem)
            completionHandler(nil)
        } catch let error {
            completionHandler(error)
        }*/
		
		completionHandler(nil)
    }

    override func startProvidingItem(at url: URL, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
        
        /* TODO:
         This is one of the main entry points of the file provider. We need to check whether the file already exists on disk,
         whether we know of a more recent version of the file, and implement a policy for these cases. Pseudocode:
         
         if !fileOnDisk {
             downloadRemoteFile()
             callCompletion(downloadErrorOrNil)
         } else if fileIsCurrent {
             callCompletion(nil)
         } else {
             if localFileHasChanges {
                 // in this case, a version of the file is on disk, but we know of a more recent version
                 // we need to implement a strategy to resolve this conflict
                 moveLocalFileAside()
                 scheduleUploadOfLocalFile()
                 downloadRemoteFile()
                 callCompletion(downloadErrorOrNil)
             } else {
                 downloadRemoteFile()
                 callCompletion(downloadErrorOrNil)
             }
         }
         */
		
		var error : NSError? = nil
		
		if !(filemanager.fileExists(atPath: url.path)) {
			error = NSError(domain: NSPOSIXErrorDomain, code: -1, userInfo: nil)
		}
		
		completionHandler(error)
    }
    
    override func itemChanged(at url: URL) {
        // Called at some point after the file has changed; the provider may then trigger an upload
        
        /* TODO:
         - mark file at <url> as needing an update in the model
         - if there are existing NSURLSessionTasks uploading this file, cancel them
         - create a fresh background NSURLSessionTask and schedule it to upload the current modifications
         - register the NSURLSessionTask with NSFileProviderManager to provide progress updates
         */
		NSLog("Item changed at URL: \(url)")
    }
    
    override func stopProvidingItem(at url: URL) {
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.
        
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        
        // TODO: look up whether the file has local changes
        /*let fileHasLocalChanges = false
        
        if !fileHasLocalChanges {
            // remove the existing file to free up space
            do {
                _ = try FileManager.default.removeItem(at: url)
            } catch {
                // Handle error
            }
            
            // write out a placeholder to facilitate future property lookups
            self.providePlaceholder(at: url, completionHandler: { error in
                // TODO: handle any error, do any necessary cleanup
            })
        }*/
		
		NSLog("Stop providing item at URL: \(url)")
    }
    
    // MARK: - Actions
    
    /* TODO: implement the actions for items here
     each of the actions follows the same pattern:
     - make a note of the change in the local model
     - schedule a server request as a background task to inform the server of the change
     - call the completion block with the modified item in its post-modification state
     */
    
    // MARK: - Enumeration
    
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
		NSLog("Getting enumerator...")
        return FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
    }
    
}
