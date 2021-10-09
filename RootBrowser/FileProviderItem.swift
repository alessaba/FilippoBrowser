//
//  FileProviderItem.swift
//  RootBrowser
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import FileProvider
import MobileCoreServices
import UniformTypeIdentifiers

class FileProviderItem: NSObject, NSFileProviderItem {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model
	var fileURL : URL 
	
	var isDownloaded: Bool = true
	var isUploaded: Bool = true
	var isMostRecentVersionDownloaded: Bool = true
	
	// Proprietà fondamentali
	var filename: String {
		self.fileURL.lastPathComponent
	}
	
	// Impostiamo la visualizzazione in sola lettura, dato che ci serve solo visualizzare
	var capabilities: NSFileProviderItemCapabilities {
		isFolder(path: self.fileURL.path) ? .allowsContentEnumerating : .allowsReading
	}
	
	var typeIdentifier: String {
		if isFolder(path: self.fileURL.path) {
			return "public.folder"
		} else {
			return UTTypeCreatePreferredIdentifierForTag(UTTagClass.filenameExtension.rawValue as CFString, self.fileURL.pathExtension as CFString, nil)!.takeRetainedValue() as String
		}
	}
	
	var documentSize: NSNumber? {
		do{
			let attr = try filemanager.attributesOfItem(atPath: self.fileURL.path)
			return attr[FileAttributeKey.size] as? NSNumber
		} catch {
			return 0
		}
	}
	
	var itemIdentifier: NSFileProviderItemIdentifier {
		let p = self.fileURL
		if p == homeDirectory {
			return .rootContainer
		} else {
			return md5Identifier(p)
		}
	}
	
    var parentItemIdentifier: NSFileProviderItemIdentifier {
		let p = self.fileURL.deletingLastPathComponent()
		if (p == homeDirectory){
			return .rootContainer
		} else {
			return md5Identifier(p)
		}
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
		NSLog("Path: \(path) -> Item type: \(self.typeIdentifier)\n")
	}
}
