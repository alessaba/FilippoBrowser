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

let fm = FileManager.default
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
