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

let fileManager = FileManager.default
let homeDirectory = "/"
var identifierLookupTable : [NSFileProviderItemIdentifier : String] = [NSFileProviderItemIdentifier.rootContainer : homeDirectory]

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


func md5Identifier(_ str: String) -> NSFileProviderItemIdentifier {
	let hash = MD5(string: str).map { String(format: "%02hhx", $0) }.joined()
	return NSFileProviderItemIdentifier(hash)
}

func isFolder(path : String) -> Bool {
	var isFoldr : ObjCBool = false
	let exists = fileManager.fileExists(atPath: path, isDirectory: &isFoldr)
	return (isFoldr.boolValue && exists)
}

func createLocalReference(to sourcePath : String){
	let id = md5Identifier(sourcePath)
	identifierLookupTable[id] = sourcePath
	
	let bookmarkPath = fileManager.temporaryDirectory.appendingPathComponent(id.rawValue).appendingPathComponent(URL(fileURLWithPath: sourcePath).lastPathComponent).path
	
	var isDir : ObjCBool = false
	fileManager.fileExists(atPath: sourcePath, isDirectory: &isDir)
	try? fileManager.removeItem(atPath: bookmarkPath)
	
	do {
		if !(fileManager.fileExists(atPath: bookmarkPath)){
			NSLog("Making directory: \(bookmarkPath)")
			try? fileManager.createDirectory(atPath: URL(fileURLWithPath: bookmarkPath).deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
			
			if (isDir.boolValue) {
				NSLog("Linking path...")
				//try fm.createSymbolicLink(atPath: sourcePath, withDestinationPath: bookmarkPath)
				try fileManager.linkItem(atPath: sourcePath, toPath: bookmarkPath)
				NSLog("Setting 0777 attributes...")
				try fileManager.setAttributes([FileAttributeKey.posixPermissions : 0777], ofItemAtPath: bookmarkPath)
			} else {
				NSLog("Copying file to sandbox..")
				try fileManager.copyItem(atPath: sourcePath, toPath: bookmarkPath)
			}
		}
	} catch {
		NSLog("Failed while creating local reference.")
	}
}

func subelements(path : String) -> [FileProviderItem] {
	// This property is only meaningful for folders. Files have no subelements
	var isFolder : ObjCBool = false
	
	guard (fileManager.fileExists(atPath: path, isDirectory: &isFolder) != false) else {
		return []
	}
	
	if (isFolder.boolValue) {
		if let subElements = try? fileManager.contentsOfDirectory(atPath: path) {
			var subDirs : [FileProviderItem] = []
			for sd in subElements {
				let newP = URL(fileURLWithPath: path).appendingPathComponent(sd)
				subDirs.append(FileProviderItem(path: newP.path))
				
				NSLog("Creating local reference to \(newP.path).")
				createLocalReference(to: newP.path)
			}
			return subDirs
		} else {
			switch path{
			case "/System":
				return [FileProviderItem(path: "/System/Library")]
			case "/usr":
				return [FileProviderItem(path: "/usr/lib"), FileProviderItem(path: "/usr/libexec"), FileProviderItem(path: "/usr/bin")]
			case "/var":
				return [FileProviderItem(path: "/var/mobile")]
			case "/Library":
				return [FileProviderItem(path: "/Library/Preferences")]
			default:
				NSLog("Folder \(path) is empty?")
				return []
			}
		}
	}
	return []
	}
