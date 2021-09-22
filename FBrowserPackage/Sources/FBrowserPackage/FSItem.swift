//
//  FSItem.swift
//  FBrowser
//
//  Created by Alessandro Saba on 06/10/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import Foundation

let runningInXcode = (ProcessInfo.processInfo.arguments.count > 1)

public enum ItemType : String {
	// We can associate a file type to a SFSymbols icon. Could be themed
	case Image = "photo.fill"
	case List = "list.bullet.indent"
	case Text = "doc.text.fill"
	case GenericDocument = "doc.fill"
	case Folder = "folder.fill"
	case threeD = "cube.transparent"
}

public class FSItem : Identifiable, Equatable{

	// We can compare FSitems by veryfying their path is the same
	public static func == (lhs: FSItem, rhs: FSItem) -> Bool {
		return lhs.path == rhs.path
	}
	
	// We just need the path to initialize a FSItem. Everithing else can be computed.
	public init(path: String) {
		self.path = path
	}
	
	public var id =  UUID()
	public var path : String = ""
	
	// Return the last part of the path, which should be the item name
	public var lastComponent : String {
		String(self.path.split(separator: "/").last ?? "")
	}
	
	// Gets the file extension for later use
	private var fileExtension : String {
		String(self.lastComponent.split(separator: ".").last ?? "")
	}
	
	public var url : URL {
		URL(fileURLWithPath: self.path)
	}
	
	// Associate a list of extensions to their respective Item Types
	public var itemType : ItemType {
		let textExtensions = ["txt", "strings"]
		let listExtensions = ["plist", "json"]
		let imageExtensions = ["jpg", "jpeg", "png" , "tiff"]
		let threeDExtensions = ["stl", "scn", "scnz"]
		
		var isFoldr : ObjCBool = false
		fileManager.fileExists(atPath: path, isDirectory: &isFoldr)
		
		if isFoldr.boolValue {
			return .Folder
		} else if imageExtensions.contains(self.fileExtension) {
			return .Image
		} else if listExtensions.contains(self.fileExtension){
			return .List
		} else if textExtensions.contains(self.fileExtension) {
			return .Text
		} else if threeDExtensions.contains(self.fileExtension) {
			return .threeD
		} else {
			return .GenericDocument
		}
	}
	
	// Just a prettier way to verify if a item is of type Folder
	public var isFolder : Bool {
		return (itemType == .Folder)
	}
	
	public var isEmpty : Bool {
		return ((self.size == 0 && !self.isFolder) || (self.subelements == [] && self.isFolder))
	}
	
	private var size : UInt64 {
		// Get the number of bytes of a file
		do {
			var gp = self.path
			gp.removeLast() // BAD WORKAROUND. MUST REMOVE ASAP
			let attr = try fileManager.attributesOfItem(atPath: gp)
			return attr[FileAttributeKey.size] as! UInt64
		} catch {
			return 0
		}
	}
	
	// We return the size of a file in a human readable form
	public var fileSize : String {
		if (!isFolder) {
			var fileSizeString : String = ""
			let fileSize = self.size
			// Convert the number of bytes in a human readable form
			if (fileSize < 1024) {
				fileSizeString = "\(fileSize) bytes"
			} else if (fileSize >= 1024) && (fileSize < 1048576) {
				fileSizeString = "\(fileSize / 1024) KB"
			} else if (fileSize >= 1048576) && (fileSize < 1073741824) {
				fileSizeString = "\(fileSize / 1048576) MB"
			} else if (fileSize >= 1073741824) && (fileSize < 1099511627776) {
				fileSizeString = "\(fileSize / 1073741824) GB"
			} else {
				fileSizeString = "\(fileSize / 1099511627776) TB" // We'll probably reach this condition in 2030 but thatever lol
			}
			
			return fileSizeString
		} else {
			return ""
		}
	}
	
	// Verify if we can read the folder/file. If not, it's root protected
	public var rootProtected : Bool {
		#warning("this is a inaccurate assumption")
		
		// If it's a empty folder, it PROBABLY (not accurate) is protected by sandbox
		if isFolder && subelements.count == 0 {
			return true
		} else {
			return false
		}
	}
	
	public var subelements : [FSItem] {
		// This property is only meaningful for folders. Files have no subelements
		if self.isFolder{
			do{
				// Gonna do some exceptions for System and usr, else we'll just get the files
				if path == "/System/"{
					return [FSItem(path: "/System/Library/")]
				} else if path == "/usr/" {
					return [FSItem(path: "/usr/lib/")]
				} else {
					// Make a list containing FSItems with the contents of the FSItem (which is a directory)
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
		} else {
			return []
		}
	}
	
	// This computed variable is used both for verifying if a item is bookmarked, and for adding/removing the item in Bookmarks
	public var isBookmarked : Bool {
		get{
			#warning("We could have multiple bookmarks with the same name")
			// Verify if we have a bookmark with that name.
			return (UserDefaults.standard.value(forKey: "FB_\(self.lastComponent)") != nil)
		}
		set{
			let name = self.lastComponent
			if (newValue == true){
				// Add a Favourite to Bookmarks
				print("Adding favourite \"\(name)\"")
				setFavorite(name: name, path: self.path)
			} else {
				// Remove a Favourite from Bookmarks
				print("Removing favourite \"\(name)\"")
				UserDefaults.standard.removeObject(forKey: "FB_\(name)")
			}
		}
	}
}

// Get the parent directory for a path. Not terribly useful
public func parentDirectory(_ path: String) -> String {
	return URL(fileURLWithPath: path).deletingLastPathComponent().path + "/"
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
