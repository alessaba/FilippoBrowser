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

public class FSItem : Identifiable, Equatable {
	
	public var id : UUID
	public var path : String = ""
	
	// MARK: Operatori
	
	// We can compare FSitems by veryfying their path is the same
	public static func == (a: FSItem, b: FSItem) -> Bool {
		return a.path == b.path
	}
	
	// We get a new FSItem if we sum it with a path. Useless but cool
	public static func + (a: FSItem, path: String) -> FSItem {
		return FSItem(url: a.url.appendingPathComponent(path))
	}
	
	// MARK: Initializers
	// We just need the path to initialize a FSItem. Everithing else can be computed.
	public init(path: String) {
		self.id = UUID(uuidString: hash(path)) ?? UUID()
		self.path = path
	}
	
	public init(url: URL){
		self.id = UUID(uuidString: hash(path)) ?? UUID()
		self.path = url.path
	}
	
	// MARK: Properties
	
	public var uuid : String{
		return hash(self.path)
	}
	
	public var url : URL {
		URL(fileURLWithPath: self.path)
	}
	
	// Return the last part of the path, which should be the item name
	public var lastComponent : String {
		self.url.lastPathComponent
		//String(self.path.split(separator: "/").last ?? "")
	}
	
	// Gets the file extension for later use
	private var fileExtension : String {
		self.url.pathExtension
		//String(self.lastComponent.split(separator: ".").last ?? "")
	}
	
	// Associate a list of extensions to their respective Item Types
	public var itemType : ItemType {
		let textExtensions = ["txt", "strings"]
		let listExtensions = ["plist", "json"]
		let imageExtensions = ["jpg", "jpeg", "png" , "tiff", "svg"]
		let threeDExtensions = ["stl", "scn", "scnz", "usd", "usdz"]
		
		var isFoldr : ObjCBool = false
		fileManager.fileExists(atPath: path, isDirectory: &isFoldr)
		
		if isFoldr.boolValue {
			return .Folder
		} else {
			if imageExtensions.contains(self.fileExtension) {
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
			let attr = try fileManager.attributesOfItem(atPath: self.url.path)
			return attr[FileAttributeKey.size] as! UInt64
		} catch {
			return 0
		}
	}
	
	// We return the size of a file in a human readable form
	public var fileSize : String {
		if (!isFolder){
			var bytescount = self.size
        		var ordineGrandezza = 0
        		let formati = ["B","KB","MB","GB","TB"]
        		while Double(bytescount) > 1024 {
            		bytescount /= 1024
            		ordineGrandezza += 1
        		}
        		return "\(bytescount) \(formati[ordineGrandezza])"
		} else {
			return ""
		}
        
    }
		
	
	public var isRoot : Bool {
		self.url == URL(fileURLWithPath: "file:///")
	}
	
	public var subelements : [FSItem] {
		// This property is only meaningful for folders. Files have no subelements
		if (self.isFolder) {
			if let subElements = try? fileManager.contentsOfDirectory(atPath: path) {
				var subDirs : [FSItem] = []
				for sd in subElements {
					subDirs.append(FSItem(url: self.urlByAppending(path: sd)))
				}
				return subDirs
			} else {
				switch path{
					case "/System":
						return [FSItem(path: "/System/Library")]
					case "/usr":
						return [FSItem(path: "/usr/lib"), FSItem(path: "/usr/libexec"), FSItem(path: "/usr/bin")]
					case "/var":
						return [FSItem(path: "/var/mobile")]
					case "/Library":
						return [FSItem(path: "/Library/Preferences")]
					default:
						if (runningInXcode) {
							print("\(path) probably has root permissions")
						}
						return []
				}
			}
		}
		return []
	}
	
	public var parentItem : FSItem {
		return FSItem(url: self.url.deletingLastPathComponent())
	}
	
	// This computed variable is used both for verifying if a item is bookmarked, and for adding/removing the item in Bookmarks
	public var isBookmarked : Bool {
		get{
			// Verify if we have a bookmark with that name.
			return (UserDefaults.standard.value(forKey: "FB4_\(self.uuid)") != nil)
		}
		set{
			let name = self.lastComponent
			if (newValue == true){
				// Add a Favourite to Bookmarks
				print("Adding favourite \"\(name)\"")
				setFavorite(self)
			} else {
				// Remove a Favourite from Bookmarks
				print("Removing favourite \"\(name)\"")
				UserDefaults.standard.removeObject(forKey: "FB4_\(self.uuid)")
			}
		}
	}
	
	// MARK: Path Functions
	public func urlByAppending(path : String ) -> URL {
		return self.url.appendingPathComponent(path)
	}
	
	public func pathByAppending(path : String ) -> String {
		return self.urlByAppending(path: path).path
	}
}
