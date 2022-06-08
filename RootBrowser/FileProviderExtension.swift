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
        // Resolve the given identifier to a record in the model
		if let url = identifierLookupTable[identifier]{
			return FileProviderItem(url: url)
		} else {
			return FileProviderItem(url: homeDirectory)
		}
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        // Resolve the given identifier to a file on disk
		guard let sourceURL = identifierLookupTable[identifier] else {
			print("source URL for \"\(identifier)\" not in lookup table")
			return nil
		}
		var isDir : ObjCBool = false
		
		if filemanager.fileExists(atPath: sourceURL.path, isDirectory: &isDir){
			return filemanager.temporaryDirectory
				.appendingPathComponent(identifier.rawValue)
				.appendingPathComponent(URL(fileURLWithPath: sourceURL.path).lastPathComponent)
		} else {
			print("Source path does not exist.")
			return nil
		}
    }
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        /* Resolve the given URL to a persistent identifier using a database.
		 Exploit the fact that the path structure has been defined as
		 <base storage directory>/ *<item identifier>* /<item file name> above
		*/
        let pathComponents = url.pathComponents
        assert(pathComponents.count > 2)
        
        return NSFileProviderItemIdentifier(pathComponents[pathComponents.count - 2])
    }
    
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        do {
            let fileProviderItem = try item(for: identifier)
            let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
			print("Placeholder URL: \(placeholderURL.path)")
            try NSFileProviderManager.writePlaceholder(at: placeholderURL,withMetadata: fileProviderItem)
            completionHandler(nil)
        } catch let error {
			print("Couldn't write placeholder for \(url.path)")
            completionHandler(error)
        }
		
		completionHandler(nil)
    }

    override func startProvidingItem(at url: URL, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
		
		var error : NSError? = nil
		
		if !(filemanager.fileExists(atPath: url.path)) {
			error = NSError(domain: NSPOSIXErrorDomain, code: -1, userInfo: nil)
		}
		
		completionHandler(error)
    }
	
	#warning("Research what fetchThumbnails is")
	override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void, completionHandler: @escaping (Error?) -> Void) -> Progress {
		return Progress()
	}
    
    override func itemChanged(at url: URL) {
        // Called at some point after the file has changed; the provider may then trigger an upload
        
        /* TODO:
         - mark file at <url> as needing an update in the model
         - if there are existing NSURLSessionTasks uploading this file, cancel them
         - create a fresh background NSURLSessionTask and schedule it to upload the current modifications
         - register the NSURLSessionTask with NSFileProviderManager to provide progress updates
         */
		print("Item changed at URL: \(url)")
    }
    
    override func stopProvidingItem(at url: URL) {
		print("Stop providing item at URL: \(url)")
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
		//print("Getting enumerator...")
        return FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
    }
    
}
