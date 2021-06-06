//
//  ContentView.swift
//  FilippoBrowser
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import SwiftUI
import WatchKit
import Foundation
import WatchConnectivity
//import FBrowserWatch

let userDefaults = UserDefaults.standard
let session = WCSession.default

// MARK: File Viewer
// This shows the contents of most types of common files
struct FileViewer : View {
	var file : FSItem
	
	var body: some View {
		VStack {
			if (self.file.itemType == .Image){
				Image(uiImage: UIImage(contentsOfFile: self.file.path)!)
					.resizable()
					.aspectRatio(contentMode: .fit)
			} else {
				Text(self.file.path)
					.onAppear{
						session.transferFile(URL(string: "file://\(self.file.path)")!, metadata: nil)
				}
			}
		}
	}
}


// MARK: Directory Viewer
// This is the directory browser, it shows files and subdirectories of a folder
struct DirectoryBrowser : View {
    @State private var searchText : String = ""
    @State private var gotoView_presented : Bool = false
    var directory : FSItem

	var body: some View {
        return List{
            Section{
				if (directory.path == "/"){
					NavigationLink(destination: gotoView()){
						Text("Go To...")
					}
				} else {
					Button(action: {
						setFavorite(name: self.directory.lastComponent, path: self.directory.path)
						NSLog("Added favourite!")
					}){
						HStack{
							Image(systemName: "heart.fill").foregroundColor(.red)
							Text("  Add to Favorites")
						}
					}
				}
                TextField("Search...", text: $searchText)
            }
            
            ForEach(directory.subelements.filter{
                // MARK: Search Function
                // The entries will update automatically eveerytime searchText changes! 🤩
                if searchText == ""{
                    return true // Every item will be shown
                } else {
                    // Only the items containing the search term will be shown (fuzzy too 🤩)
					return $0.lastComponent.lowercased().contains(searchText.lowercased())
                }
                
            }) { subItem in
                HStack{
                    // Test for various file types and assign icons (SFSymbols, which are GREAT <3)
					Image(systemName: subItem.itemType.rawValue)
                    .foregroundColor((subItem.rootProtected) ? .orange : .green)
					
					Spacer().frame(width:10)
                    
					VStack(alignment: .leading) {
                        //Name of the file/directory
                        NavigationLink(destination: properView(for: subItem)){
                            Text(subItem.lastComponent)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundColor(.blue)
                        }
                        
                        //Detail subtext: Number of subelements in case of folders. Size of the file in case of files
                        if subItem.isFolder {
                            Text("\(subItem.subelements.count) \((subItem.subelements.count != 1) ? "elements" : "element" )")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(subItem.fileSize)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
		}
    }
}

// MARK: Go To View
struct gotoView : View {
    @State var path : String = "/"
    @State private var viewPushed : Bool = false
	let userDefaultsKeys = userDefaults.dictionaryRepresentation().keys.filter{
		return $0.starts(with: "FB_")
	}
	
    var body : some View {
		ScrollView{
			
			TextField("Path", text: $path)
			
			NavigationLink(destination: properView(for: FSItem(path: path))){
				Text("Go")
					.foregroundColor(.green)
					.bold()
			}
			
			Spacer()
			
			NavigationLink(destination: properView(for: FSItem(path: "/var/mobile/Media/"))){
				Text("Media 🖥")
					.foregroundColor(.blue)
					.bold()
				
			}
			
			Spacer()
			
			ForEach(userDefaultsKeys){ key in
				NavigationLink(destination:
					properView(for: FSItem(path: userDefaults.string(forKey: key) ?? "/"))
				){
					Text(String(key.split(separator: "_").last!))
						.foregroundColor(.red)
						.bold()
				}
			}
			
			
		}
	}
}



extension String : Identifiable{
	public var id : UUID {
		return UUID()
	}
}

// MARK: Helper Functions

// Gets the file extension for later use
public func getExtension(_ path: String) -> String {
	return String(path.split(separator: ".").last ?? "")
}

public func setFavorite(name : String, path : String) {
	userDefaults.set(path, forKey: "FB_\(name)")
	userDefaults.synchronize()
}

// Decide what view to present: FileViewer for files, DirectoryBrowser for directories
func properView(for item: FSItem) -> AnyView {
    if item.isFolder{
        return AnyView(DirectoryBrowser(directory: item))
    } else {
        return AnyView(FileViewer(file: item))
    }
}


// Tries to read txt files
func readFile(_ path: String) -> Data {
    var data : Data
    do{
        data = try Data(contentsOf: URL(string: "file://" + path)!)
    } catch {
        data = Data()
    }
    return data
}




#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        DirectoryBrowser(directory: FSItem(path: "/"))
    }
}
#endif

// MARK: FSItem
let runningInXcode = (ProcessInfo.processInfo.arguments.count > 1)

public enum ItemType : String {
	case Image = "photo.fill"
	case List = "list.bullet.indent"
	case Text = "doc.text.fill"
	case GenericDocument = "doc.fill"
	case Folder = "folder.fill"
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
	
	// this is a dumb assumption
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
