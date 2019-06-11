//
//  ContentView.swift
//  ShortcutParamTest
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import SwiftUI
import Foundation

let fm = FileManager.default //Instance of the default file manager. we'll need it later

// MARK: Starting View
// Starting point
struct ContentView : View {
	
	var path : String
	var body: some View {
		NavigationView {
			DirectoryBrowser(path: path)
				.navigationBarTitle(Text("File Browser"))
		}
	}
	
}

// MARK: File Viewer
// This shows the contents of most types of common files
struct FileViewer : View {
	
	var path : String
	var body: some View {
		Text(path)
	}
	
}

// MARK: Directory Viewer
// This is the directory browser, it shows files and subdirectories of a folder
struct DirectoryBrowser : View {
	
	var path : String
	var subDirs : [String] {
		do{
			// Gonna do some exceptions for System and usr, else we'll judt get the files
			if path == "/System/"{
				return ["Library"]
			} else if path == "/usr/" {
				return ["lib"]
			} else {
				return (try fm.contentsOfDirectory(atPath: path))
			}
		} catch {
			NSLog("Either a folder with root permissions or some file")
			return []
		}
	}
	
	var body: some View {
		List(0 ..< subDirs.count) { subDir in
			NavigationButton(destination: DirectoryBrowser(path: "\(self.path)\(self.subDirs[subDir])/")) { // Gotta verify if it is a folder or a file :-)
				HStack {
					// Test for various file types and assign icons (SFSymbols, which are GREAT <3)
					if isFolder("\(self.path)\(self.subDirs[subDir])/") {
						Image(systemName: "folder")
					} else if getExtension(self.subDirs[subDir]) == "png" || getExtension(self.subDirs[subDir]) == "jpg" {
						Image(systemName: "photo")
					} else if getExtension(self.subDirs[subDir]) == "plist" || getExtension(self.subDirs[subDir]) == "json"{
						Image(systemName: "list.bullet.indent")
					} else if getExtension(self.subDirs[subDir]) == "txt" {
						Image(systemName: "doc.text.fill")
					} else {
						Image(systemName: "doc")
					}
					
					//Name of the file/directory
					Text(self.subDirs[subDir])
						.fontWeight(.semibold)
						.color(.blue)
						.padding(.leading)
					
					//Detail subtext: Number of subelements in case of folders. Size of the file in case of files
					if isFolder("\(self.path)\(self.subDirs[subDir])"){
						
						Text("\(subelementsCount("\(self.path)\(self.subDirs[subDir])")) elements")
							.color(.secondary)
							.padding(.leading)
						
					} else {
						
						Text(filesize("\(self.path)\(self.subDirs[subDir])"))
							.color(.secondary)
							.padding(.leading)
						
					}
					

			   }
			}
		}.listStyle(.grouped).navigationBarTitle(Text(path))
		
	}
}




// MARK: Helper Functions
// Return if a subelement is a folder or file
func isFolder(_ path: String) -> Bool {
	var isFoldr : ObjCBool = false
	fm.fileExists(atPath: path, isDirectory: &isFoldr)
	return isFoldr.boolValue
}


// Gets the file extension for later use
func getExtension(_ path: String) -> String{
	let strComponents = path.split(separator: ".")
	var ext : String
	if strComponents.count > 1 {
		ext = String(strComponents[1])
	} else {
		ext = ""
	}
	return ext
}


// Counts how many subelements there are
func subelementsCount(_ path: String) -> Int {
	do{
		let n = (try fm.contentsOfDirectory(atPath: path)).count
		return n
	} catch {
		if path == "/System" || path == "/usr"{
			return 1
		} else {
			return 0
		}
	}
}


//Get the prettifyed file size string for quick use
func filesize(_ path: String) -> String {
	var fileSize : UInt64
	var fileSizeString : String = ""
	do {
		let attr = try FileManager.default.attributesOfItem(atPath: path)
		fileSize = attr[FileAttributeKey.size] as! UInt64
	} catch {
		fileSize = 0
	}
	
	if fileSize < 1024 {
		fileSizeString = "\(fileSize) bytes"
	} else if fileSize > 1024 && fileSize < 1048576 {
		fileSizeString = "\(fileSize / 1024) KB"
	} else if fileSize > 1048576 && fileSize < 1073741824 {
		fileSizeString = "\(fileSize / 1048576) MB"
	} else {
		fileSizeString = "\(fileSize / 1073741824) GB"
	}
	
	return fileSizeString
}



#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(path: "/")
    }
}
#endif


