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
struct Browser : View {
	
	var path : String
	var body: some View {
		NavigationView {
			DirectoryBrowser(path: path)
                .navigationBarTitle(Text("File Browser"), displayMode: .inline)
            .navigationBarItems(
                
                leading:
                Image(systemName: "arrow.2.squarepath")
                    .onTapGesture {
                        NSLog("Go To")
                    },
                
                trailing:
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        NSLog("Search")
                }
            )
		}
	}
}


struct ContentView : View {
	
	var path : String
	var body: some View {
		VStack{
			Browser(path: path)
            Divider()
            //Toolbar(path: path)
		}
	}
}


// MARK: File Viewer
// This shows the contents of most types of common files
struct FileViewer : View {
	
	var path : String
	var body: some View {
	  Text(readFile(path))
        .onTapGesture {
            UIPasteboard.general.string = "file://" + self.path
            let avc = UIActivityViewController(activityItems: [self.path], applicationActivities: nil)
            let rvc = UIHostingController(rootView: self)
            rvc.present(avc, animated: true, completion: nil)
        }
	}
	
}

struct FSItem : Identifiable {
	
	var id =  UUID()
	var path : String
	
	var lastComponent : String {
		String(self.path.split(separator: "/").last ?? "")
	}
	
	var isFolder : Bool {
		var isFoldr : ObjCBool = false
		fm.fileExists(atPath: path, isDirectory: &isFoldr)
		return isFoldr.boolValue
	}
	
	var fileSize : String {
		if !isFolder{
			var fileSize : UInt64
			var fileSizeString : String = ""
			do {
				var gp = self.path
				gp.removeLast() // BAD WORKAROUND. MUST REMOVE ASAP
				let attr = try FileManager.default.attributesOfItem(atPath: gp)
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
	
	var subelementCount : Int {
		return subelements.count
	}
	
	var subelements : [FSItem] {
		do{
			// Gonna do some exceptions for System and usr, else we'll judt get the files
			if path == "/System/"{
				return [FSItem(path: "/System/Library/")]
			} else if path == "/usr/" {
				return [FSItem(path: "/usr/lib/")]
			} else {
				var subDirs : [FSItem] = []
				let sdd = try fm.contentsOfDirectory(atPath: path)
				sdd.map{ sd in
					subDirs.append(FSItem(path: "\(self.path)\(sd)/"))
				}
				return subDirs
			}
		} catch {
			NSLog("\(path) probably has root permissions")
			return []
		}
	}
}

// MARK: Directory Viewer
// This is the directory browser, it shows files and subdirectories of a folder
struct DirectoryBrowser : View {
	var path : String
	var subItems : [FSItem] {
		FSItem(path: self.path).subelements
	}
	var body: some View {
	  List(subItems) { subItem in
        HStack {
            // Test for various file types and assign icons (SFSymbols, which are GREAT <3)
            if subItem.isFolder {
                Image(systemName: "folder")
            } else if imageExtensions.contains(getExtension(subItem.lastComponent)) {
                Image(systemName: "photo")
            } else if listExtensions.contains(getExtension(subItem.lastComponent)){
                Image(systemName: "list.bullet.indent")
            } else if textExtensions.contains(getExtension(subItem.lastComponent)) {
                Image(systemName: "doc.text.fill")
            } else {
                Image(systemName: "doc")
            }
            
            //Name of the file/directory
            NavigationLink(destination: properView(for: subItem)){
                Text(subItem.lastComponent)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.leading)
                    .contextMenu{
                        HStack{
                            //Image(systemName: "doc")
                            Button("Copy Path"){
                                NSLog("Copy Path button pressed")
                                UIPasteboard.general.string = "file://" + self.path + subItem.lastComponent
                            }
                            
                        }
                    }
            }
                
            
            //Detail subtext: Number of subelements in case of folders. Size of the file in case of files
            if subItem.isFolder {
              
                Text("\(subItem.subelementCount) \((subItem.subelementCount != 1) ? "elements" : "element" )")
                  .foregroundColor(.secondary)
                  .padding(.leading)
              
                } else {
              
                    Text(subItem.fileSize)
                        .foregroundColor(.secondary)
                      .padding(.leading)
              
                    }
                }
      }
         .listStyle(GroupedListStyle())
      .navigationBarTitle(Text(path), displayMode: .inline)
	}
}

struct gotoView : View {
	@State var path : String = "/"
	
	var body : some View {
		VStack{
            TextField("Path", text: $path)
			NavigationLink(destination: Browser(path: path), label: {Text("Go").bold()})
		}
	}
}



// MARK: – Helper Functions
// Gets the file extension for later use
func getExtension(_ path: String) -> String {
	return String(path.split(separator: ".").last ?? "")
}


// Decide what view to present: FileViewer for files, DirectoryBrowser for directories
func properView(for directory: FSItem) -> AnyView {
	if directory.isFolder{
		return AnyView(DirectoryBrowser(path: directory.path))
	} else {
		return AnyView(FileViewer(path: directory.path))
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
        Browser(path: "/")
    }
}
#endif



