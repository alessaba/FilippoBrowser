//
//  ContentView.swift
//  ShortcutParamTest
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import SwiftUI
import UIKit
import Foundation

let fm = FileManager.default //Instance of the default file manager. we'll need it later
let textExtensions = ["txt"]
let listExtensions = ["plist", "json"]
let imageExtensions = ["jpg", "jpeg", "png" , "tiff"]

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
	  Text(readFile(path))
		.tapAction {
			UIPasteboard.general.string = "file://" + self.path
			let avc = UIActivityViewController(activityItems: [self.path], applicationActivities: nil)
			let rvc = UIHostingController(rootView: self)
			rvc.present(avc, animated: true, completion: nil)
		}
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
			NSLog("Folder with root permissions")
			return []
		}
	}
	
	var body: some View {
		List(0 ..< subDirs.count) { subDir in
			NavigationButton(destination: properView(for: "\(self.path)\(self.subDirs[subDir])/")) { // Gotta verify if it is a folder or a file :-)
				HStack {
					// Test for various file types and assign icons (SFSymbols, which are GREAT <3)
					if isFolder("\(self.path)\(self.subDirs[subDir])/") {
						Image(systemName: "folder")
					} else if imageExtensions.contains(getExtension(self.subDirs[subDir])) {
						Image(systemName: "photo")
					} else if listExtensions.contains(getExtension(self.subDirs[subDir])){
						Image(systemName: "list.bullet.indent")
					} else if textExtensions.contains(getExtension(self.subDirs[subDir])) {
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
						
						Text("\(subelementsCount("\(self.path)\(self.subDirs[subDir])")) \((subelementsCount("\(self.path)\(self.subDirs[subDir])") != 1) ? "elements" : "element" )")
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
func getExtension(_ path: String) -> String {
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


// Decide what view to present: FileViewer for files, DirectoryBrowser for directories
func properView(for path: String) -> AnyView {
	if isFolder(path){
		return AnyView(DirectoryBrowser(path: path))
	} else {
		return AnyView(FileViewer(path: path))
	}
}

// Tries to read txt files
func readFile(_ path: String) -> String {
	//let data = Data(contentsOf: URL(string: path))
	var data = ""
	do{
		data = try String(contentsOfFile: path)
	} catch {
		data = path
	}
	return data
}




#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(path: "/")
    }
}
#endif


