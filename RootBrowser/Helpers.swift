//
//  Helpers.swift
//  RootBrowser
//
//  Created by Filippo Claudi on 6/10/21.
//  Copyright © 2021 Filippo Claudi. All rights reserved.
//

import Foundation
import FileProvider
import CryptoKit


import MobileCoreServices
import UniformTypeIdentifiers

let filemanager = FileManager.default
let homeDirectory = URL(fileURLWithPath: "/")
var identifierLookupTable : [NSFileProviderItemIdentifier : URL] = [NSFileProviderItemIdentifier.rootContainer : homeDirectory]

func hashIdentifier(_ url: URL) -> NSFileProviderItemIdentifier {
 let hash = String(CryptoKit.SHA256.hash(data: url.absoluteString.data(using: .utf8) ?? Data()).description.dropFirst(15))
 return NSFileProviderItemIdentifier(hash)
 }

func uti(for url: URL) -> String {
	if isFolder(path: url.path) {
		return "public.folder"
	} else {
		return UTType(tag: url.pathExtension, tagClass: .filenameExtension, conformingTo: nil)?.identifier ?? "public.file"
	}
}

func isFolder(path : String) -> Bool {
	var isFoldr : ObjCBool = false
	let exists = filemanager.fileExists(atPath: path, isDirectory: &isFoldr)
	return (isFoldr.boolValue && exists)
}

func subelements(url : URL) -> [String] {
	
	var isFolder : ObjCBool = false
	guard (filemanager.fileExists(atPath: url.standardized.path, isDirectory: &isFolder) != false) else {
		return []
	}
	
	// This property is only meaningful for folders. Files have no subelements
	if (isFolder.boolValue) {
		switch url.path{
			case "/System":
				 return ["Library"]
			case "/usr":
				return ["lib", "libexec", "bin"]
			case "/var":
				return ["mobile"]
			case "/Library":
				return ["Preferences"]
			default:
				let subElements = try? filemanager.contentsOfDirectory(atPath: url.path)
				return subElements ?? []
		}
	}
	
	return []
}
