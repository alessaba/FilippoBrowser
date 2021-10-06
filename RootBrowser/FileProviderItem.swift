//
//  FileProviderItem.swift
//  RootBrowser
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import FileProvider
import FBrowserPackage
import MobileCoreServices
import UniformTypeIdentifiers

class FileProviderItem: NSObject, NSFileProviderItem {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model
	var internalFilePath : URL = URL(fileURLWithPath: homeDirectory)
	
	var isDownloaded: Bool = true
	var isUploaded: Bool = true
	var isMostRecentVersionDownloaded: Bool = true
	
	// Proprietà fondamentali
	var filename: String {
		self.internalFilePath.lastPathComponent
	}
	
	// Impostiamo la visualizzazione in sola lettura, dato che ci serve solo visualizzare
	var capabilities: NSFileProviderItemCapabilities {
		FSItem(path: internalFilePath.path).isFolder ? .allowsContentEnumerating : .allowsReading
	}
	
	var typeIdentifier: String {
		if FSItem(path: internalFilePath.path).isFolder {
			return "public.folder"
		} else {
			return UTTypeCreatePreferredIdentifierForTag(UTTagClass.filenameExtension.rawValue as CFString, self.internalFilePath.pathExtension as CFString, "public.file" as CFString)!.takeUnretainedValue() as String
		}
	}
	
	var documentSize: NSNumber? {
		FSItem(path: self.internalFilePath.path).size as NSNumber
	}
	
	var itemIdentifier: NSFileProviderItemIdentifier {
		let p = self.internalFilePath.path
		if p == homeDirectory {
			return .rootContainer
		} else {
			return md5Identifier(p)
		}
	}
	
    var parentItemIdentifier: NSFileProviderItemIdentifier {
		let p = self.internalFilePath.deletingLastPathComponent().path
		if (p == homeDirectory){
			return .rootContainer
		} else {
			return md5Identifier(p)
		}
	}
	
	var childItemCount: NSNumber? {
		FSItem(path: internalFilePath.path).subelements.count as NSNumber
	}
	
	var versionIdentifier: Data? {
		let i = Date.timeIntervalSinceReferenceDate
		return String(format: "%f", i).data(using: .utf8)
	}
	
	internal init(path: String) {
		self.internalFilePath = URL(fileURLWithPath: path)
		super.init()
		NSLog("Path: \(path) -> Item type: \(self.typeIdentifier)\n")
	}
}
