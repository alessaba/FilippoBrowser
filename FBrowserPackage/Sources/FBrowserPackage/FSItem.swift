//
//  FSItem.swift
//  FBrowser
//
//  Created by Filippo Claudi on 06/10/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import Foundation

let runningInXcode = (ProcessInfo.processInfo.arguments.count > 1)

public enum ItemType : String {
	case Image = "photo.fill"
	case List = "list.bullet.indent"
	case Text = "doc.text.fill"
	case GenericDocument = "doc.fill"
	case Folder = "folder.fill"
	case threeD = "cube.transparent"
}

public class FSItem : Identifiable, Equatable{

	
	public static func == (lhs: FSItem, rhs: FSItem) -> Bool {
		return lhs.path == rhs.path
	}

	public init(path: String) {
		self.path = path
	}
	
	public var id =  UUID()
	public var path : String = ""
	let fileManager = FileManager.default
	
	public var lastComponent : String {
		String(self.path.split(separator: "/").last ?? "")
	}
	
	
	public var itemType : ItemType {
		let textExtensions = ["txt", "strings"]
		let listExtensions = ["plist", "json"]
		let imageExtensions = ["jpg", "jpeg", "png" , "tiff"]
		let threeDExtensions = ["stl", "scn", "scnz"]
		
		var isFoldr : ObjCBool = false
		fileManager.fileExists(atPath: path, isDirectory: &isFoldr)
		
		if isFoldr.boolValue {
			return .Folder
		} else if imageExtensions.contains(getExtension(self.lastComponent)) {
			return .Image
		} else if listExtensions.contains(getExtension(self.lastComponent)){
			return .List
		} else if textExtensions.contains(getExtension(self.lastComponent)) {
			return .Text
		} else if threeDExtensions.contains(getExtension(self.lastComponent)) {
			return .threeD
		} else {
			return .GenericDocument
		}
	}
	
	public var isFolder : Bool {
		return (itemType == .Folder)
	}
	
	public var fileSize : String {
		if !isFolder{
			var fileSize : UInt64
			var fileSizeString : String = ""
			do {
				var gp = self.path
				gp.removeLast() // BAD WORKAROUND. MUST REMOVE ASAP
				let attr = try fileManager.attributesOfItem(atPath: gp)
				fileSize = attr[FileAttributeKey.size] as! UInt64
			} catch {
				fileSize = 0
			}
			
			if fileSize < 1024 {
				fileSizeString = "\(fileSize) bytes"
			} else if fileSize >= 1024 && fileSize < 1048576 {
				fileSizeString = "\(fileSize / 1024) KB"
			} else if fileSize >= 1048576 && fileSize < 1073741824 {
				fileSizeString = "\(fileSize / 1048576) MB"
			} else if fileSize >= 1073741824 && fileSize < 1099511627776 {
				fileSizeString = "\(fileSize / 1073741824) GB"
			} else {
				fileSizeString = "\(fileSize / 1099511627776) TB" // We'll probably reach this condition in 2030 but thatever lol
			}
			
			return fileSizeString
		} else {
			return ""
		}
	}
	
	#warning("this is a dumb assumption")
	public var rootProtected : Bool {
		if isFolder && subelements.count == 0 {
			return true
		} else {
			return false
		}
	}
	
	public var subelements : [FSItem] {
		do{
			// Gonna do some exceptions for System and usr, else we'll judt get the files
			if path == "/System/"{
				return [FSItem(path: "/System/Library/")]
			} else if path == "/usr/" {
				return [FSItem(path: "/usr/lib/")]
			} else {
				var subDirs : [FSItem] = []
				for sd in try fileManager.contentsOfDirectory(atPath: path) {
					subDirs.append(FSItem(path: "\(self.path)\(sd)/"))
				}
				return subDirs
			}
		} catch {
			if (runningInXcode) {
				NSLog("\(path) probably has root permissions")
			}
			return []
		}
	}
}

public func parentDirectory(_ path: String) -> String {
	return URL(string: "file://\(path)")!.deletingLastPathComponent().path + "/"
}


// Gets the file extension for later use
public func getExtension(_ path: String) -> String {
	return String(path.split(separator: ".").last ?? "")
}

/*
// Tries to read files
public func readFile(_ path: String) -> Data {
	var data : Data
	do{
		data = try Data(contentsOf: URL(string: "file://" + path)!)
	} catch {
		data = Data()
	}
	return data
}
*/
