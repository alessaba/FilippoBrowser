//
//  ContentView.swift
//  FilippoBrowser
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import SwiftUI
import WatchKit
import WatchConnectivity
import Foundation
//import FBrowserWatch

let userDefaults = UserDefaults.init(suiteName: "group.FilippoBrowser") ?? UserDefaults.standard
let appGroup_directory = (FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.FilippoBrowser") ?? URL(string: "file://")!).path + "/"

let textExtensions = ["txt"]
let listExtensions = ["plist", "json"]
let imageExtensions = ["jpg", "jpeg", "png" , "tiff"]


class SessionDelegate : NSObject, WCSessionDelegate{
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		NSLog("Session:\nReachable:\(session.isReachable)\nActivation State:\(activationState.rawValue)")
	}
}


// MARK: File Viewer
// This shows the contents of most types of common files
struct FileViewer : View {
	var file : FSItem
	var body: some View {
		VStack {
			if (getExtension(self.file.path) == "png/"){
				Image(uiImage: UIImage(contentsOfFile: self.file.path)!)
					.resizable()
					.aspectRatio(contentMode: .fit)
			} else {
				Text(self.file.path)
					.onAppear{
						/*if WCSession.isSupported() {
							let session = WCSession.default
							let del = SessionDelegate()
							session.delegate = del
							session.activate()
							session.transferFile(URL(string: "file://\(self.file.path)")!, metadata: nil)
						}*/
						do{
							try FileManager.default.copyItem(atPath: self.file.path, toPath: appGroup_directory)
							NSLog("File Copied!")
						} catch {
							NSLog("File copy failed :-/")
						}
						
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
        List{
            Section{
                NavigationLink(destination: gotoView()){
                        Text("Go To...")
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
                    Group{
                        if subItem.isFolder {
                            Image(systemName: "folder.fill")
                        } else if imageExtensions.contains(getExtension(subItem.lastComponent)) {
                            Image(systemName: "photo.fill")
                        } else if listExtensions.contains(getExtension(subItem.lastComponent)){
                            Image(systemName: "list.bullet.indent")
                        } else if textExtensions.contains(getExtension(subItem.lastComponent)) {
                            Image(systemName: "doc.text.fill")
                        } else {
                            Image(systemName: "doc.fill")
                        }
                    }
                    .foregroundColor((subItem.rootProtected) ? .orange : .green)

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
        .contextMenu {
           /* Button("Go To..."){
                self.gotoView_presented = true
            }.sheet(isPresented: $gotoView_presented, content: {gotoView()})
			*/
			Button(action: {
				setFavorite(name: self.directory.lastComponent, path: self.directory.path)
				NSLog("Added favourite!")
			}){
				VStack{
					Image(systemName: "heart.fill")
					Text("Add to Favorites ")
				}
			}
		}
    }
}

// MARK: Go To View
struct gotoView : View {
    @State var path : String = "/"
    @State private var viewPushed : Bool = false
	let userDefaultsKeys = userDefaults.dictionaryRepresentation().keys
	
    var body : some View {
		ScrollView{
			
			TextField("Path", text: $path)
			
			NavigationLink(destination: properView(for: FSItem(path: path))){
				Text("Go")
					.foregroundColor(.green)
					.bold()
			}
			
			ForEach(userDefaultsKeys.filter{
				return $0.starts(with: "FB_")
			}){ key in
				NavigationLink(destination:
					properView(for: FSItem(path: userDefaults.string(forKey: key) ?? "/"))
				){
					Text(String(key.split(separator: "_").last!))
						.bold()
				}
			}
			
			NavigationLink(destination: properView(for: FSItem(path: appGroup_directory))){
				Text("App Group ⌚️")
					.foregroundColor(.blue)
					.bold()
			}
			Spacer()
			NavigationLink(destination: properView(for: FSItem(path: "/var/mobile/Media/"))){
				Text("Media 🖥")
					.foregroundColor(.blue)
					.bold()
	
			}
		}
	}
}



extension String : Identifiable{
	public var id : UUID {
		return UUID()
	}
}

struct favoritesView : View {
	let userDefaultsKeys = UserDefaults.standard.dictionaryRepresentation().keys

	var body : some View{
		List(userDefaultsKeys.filter{
			return $0.starts(with: "FB_")
		}){ key in
			NavigationLink(destination:
				properView(for: FSItem(path: userDefaults.string(forKey: key) ?? "/"))
			){
				Text(String(key.split(separator: "_").last!))
			}
		}
	}
}


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
	
	public var isFolder : Bool {
		var isFoldr : ObjCBool = false
		fileManager.fileExists(atPath: path, isDirectory: &isFoldr)
		return isFoldr.boolValue
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
			NSLog("\(path) probably has root permissions")
			return []
		}
	}
}



