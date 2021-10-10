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

import MobileCoreServices
import UniformTypeIdentifiers

let filemanager = FileManager.default
let homeDirectory = URL(fileURLWithPath: "/")
var identifierLookupTable : [NSFileProviderItemIdentifier : URL] = [NSFileProviderItemIdentifier.rootContainer : homeDirectory]


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

func uti(for url: URL) -> String {
	if isFolder(path: url.path) {
		return "public.folder"
	} else {
		return UTTypeCreatePreferredIdentifierForTag(
			UTTagClass.filenameExtension.rawValue as CFString,
			url.pathExtension as CFString,
			nil)!
			.takeRetainedValue() as String
	}
}

func isFolder(path : String) -> Bool {
	var isFoldr : ObjCBool = false
	let exists = filemanager.fileExists(atPath: path, isDirectory: &isFoldr)
	return (isFoldr.boolValue && exists)
}

func subelements(url : URL) -> [String] {
	
	var isFolder : ObjCBool = false
	guard (filemanager.fileExists(atPath: url.path, isDirectory: &isFolder) != false) else {
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
