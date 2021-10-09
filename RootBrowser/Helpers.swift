//
//  Helpers.swift
//  RootBrowser
//
//  Created by Filippo Claudi on 6/10/21.
//  Copyright © 2021 Filippo Claudi. All rights reserved.
//

import Foundation
import FileProvider
import CommonCrypto

let filemanager = FileManager.default
let homeDirectory = URL(fileURLWithPath: "/")
var identifierLookupTable : [NSFileProviderItemIdentifier : URL] = [NSFileProviderItemIdentifier.rootContainer : homeDirectory]

extension FileProviderItem {
	convenience init(url : URL){
		self.init(path: url.path)
	}
}

private func MD5(string: String) -> Data {
	let length = Int(CC_MD5_DIGEST_LENGTH)
	let messageData = string.data(using:.utf8)!
	var digestData = Data(count: length)
	
	_ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
		messageData.withUnsafeBytes { messageBytes -> UInt8 in
			if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
				let messageLength = CC_LONG(messageData.count)
				CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
			}
			return 0
		}
	}
	return digestData
}


func md5Identifier(_ url: URL) -> NSFileProviderItemIdentifier {
	let hash = MD5(string: url.path).map { String(format: "%02hhx", $0) }.joined()
	return NSFileProviderItemIdentifier(hash)
}

func isFolder(path : String) -> Bool {
	var isFoldr : ObjCBool = false
	let exists = filemanager.fileExists(atPath: path, isDirectory: &isFoldr)
	return (isFoldr.boolValue && exists)
}

func subelements(url : URL) -> [String] {
	// This property is only meaningful for folders. Files have no subelements
	var isFolder : ObjCBool = false
	
	guard (filemanager.fileExists(atPath: url.path, isDirectory: &isFolder) != false) else {
		return []
	}
	
	if (isFolder.boolValue) {
		var subElements : [String]? = try? filemanager.contentsOfDirectory(atPath: url.path)
	
		switch url.path{
			case "/System":
				 subElements = ["Library"]
			case "/usr":
				subElements = ["lib", "libexec", "bin"]
			case "/var":
				subElements =  ["mobile"]
			case "/Library":
				subElements =  ["Preferences"]
			default:
				NSLog("Folder \(url.path) is probably empty")
		}
		return subElements ?? []
	}
	return []
	}
