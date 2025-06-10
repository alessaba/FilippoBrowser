//
//  FileProviderItem.swift
//  RootBrowser
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import FileProvider

class FileProviderItem: NSObject, NSFileProviderItem {
	
	var fileURL : URL 
	
	var isDownloaded: Bool = true
	var isUploaded: Bool = true
	var isMostRecentVersionDownloaded: Bool = true
	
	// Proprietà fondamentali
	var filename: String {
		self.fileURL.lastPathComponent
	}
	
	var documentSize: NSNumber? {
		do{
			let attr = try filemanager.attributesOfItem(atPath: self.fileURL.path)
			return attr[FileAttributeKey.size] as? NSNumber
		} catch {
			return 0
		}
	}
	
	// Impostiamo la visualizzazione in sola lettura, dato che ci serve solo visualizzare
	var capabilities: NSFileProviderItemCapabilities {
		isFolder(path: self.fileURL.path) ? .allowsContentEnumerating : .allowsReading
	}
	
	var typeIdentifier: String {
		uti(for: self.fileURL)
	}
	
	
	var itemIdentifier: NSFileProviderItemIdentifier {
		let url = self.fileURL
		return (url == homeDirectory) ? .rootContainer : hashIdentifier(url)
	}
	
    var parentItemIdentifier: NSFileProviderItemIdentifier {
		let url = self.fileURL.deletingLastPathComponent()
		return (url == homeDirectory) ? .rootContainer : hashIdentifier(url)
	}
	
	var childItemCount: NSNumber? {
		subelements(url: self.fileURL).count as NSNumber
	}
	
	var versionIdentifier: Data? {
		let i = Date.timeIntervalSinceReferenceDate
		return String(format: "%f", i).data(using: .utf8)
	}
	
	internal init(path: String) {
		self.fileURL = URL(fileURLWithPath: path)
		super.init()
	}
	
	convenience init(url : URL){
		self.init(path: url.path)
	}
}
