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
import FBrowserPackage

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
	@State private var bookmarked : Bool = false
	#warning("Could add logic to determine if the folder was previously bookmarked")
	
    var directory : FSItem

	var body: some View {
		List{
            Section{
				if (directory.path == "/"){
					NavigationLink(destination: gotoView()){
						Text("Go To...")
					}
				} else {
					Button(action: {
						setFavorite(name: self.directory.lastComponent, path: self.directory.path)
						bookmarked.toggle()
						NSLog("Added favourite!")
					}){
						HStack{
							Image(systemName: "heart.fill").foregroundColor(.red)
							Text(bookmarked ? " Added!" : "  Add to Favorites")
						}
					}
				}
            }
            
			let subelements = directory.subelements.filter{
				// MARK: Search Function
				// The entries will update automatically eveerytime searchText changes! 🤩
				if searchText == ""{
					return true // Every item will be shown
				} else {
					// Only the items containing the search term will be shown (fuzzy too 🤩)
					return $0.lastComponent.lowercased().contains(searchText.lowercased())
				}
				
			}
			
            ForEach(subelements) { subItem in
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
		}.searchable(text: $searchText)
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
			
			BookmarkItem(name: "Go", path: path, isButton: true)
			
			Spacer(minLength: 20)
			
			BookmarkItem(name: "Media 🖥", path: "/var/mobile/Media/")
			
			ForEach(userDefaultsKeys){ key in
				BookmarkItem(key: key)
			}
			Spacer(minLength: 30)
			
			Text("Free Space")
			Spacer()
			HStack{
				Gauge(value: availableCapacity(),
					  in: 0...16,
					  label: {Text("GB")},
					  currentValueLabel: {Text(String(format: "%.2f", availableCapacity())).foregroundColor(.teal)}
				)
					.gaugeStyle(CircularGaugeStyle(tint: .teal))
			}
			
		}
	}
}

struct BookmarkItem: View {
	
	enum BookmarkItemType{
		case system, userAdded, button
	}
	
	var key : String
	var name : String
	var path : String
	var type : BookmarkItemType
	
	var color : Color{
		switch self.type{
		case .system:
			return .blue
		case .userAdded:
			return .red
		case .button:
			return .teal
		}
	}
	
	init(name: String, path: String, isButton: Bool = false){
		self.key = ""
		self.name = name
		self.path = path
		self.type = isButton ? .button : .system
	}
	
	init(key: String){
		self.key = key
		self.name = String(key.split(separator: "_").last!)
		self.path = String(userDefaults.string(forKey: key) ?? "/")
		self.type = .userAdded
	}
	
	var body: some View {
		NavigationLink(destination: properView(for: FSItem(path: self.path))){
			Text(name)
			#if os(iOS)
				.contextMenu{
					Button(action: {
						userDefaults.removeObject(forKey: self.key)
							UIApplication.shared.shortcutItems?.removeAll(where: { shortcut in
								return shortcut.type == self.key
							})
					}){
						Image(systemName: "bin.xmark.fill")
						Text("Delete")
					}
					.foregroundColor(.red)
				}
			#endif
				.padding((self.type == .button) ? 0 : 10)
				.foregroundColor(self.color)
				.font(.system(size: 15).bold())
		}
		.buttonStyle(BorderedButtonStyle(tint: self.color))
		.padding(.horizontal, (self.type == .button) ? 0 : 10)
		Spacer()
	}
}

let resvalues = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])

func totalCapacity() -> Double {
	if let resvalues = resvalues{
		return Double(0 - (resvalues.volumeTotalCapacity ?? 0)) / 1000000000
	} else {
		return 0
	}
}

func availableCapacity() -> Double {
	if let resvalues = resvalues{
		return (Double(resvalues.volumeAvailableCapacity ?? 0) / 1000000000) * 16
	} else {
		return 0
	}
}

// Decide what view to present: FileViewer for files, DirectoryBrowser for directories
func properView(for item: FSItem) -> AnyView {
	if item.isFolder{
		return AnyView(DirectoryBrowser(directory: item))
	} else {
		return AnyView(FileViewer(file: item))
	}
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        DirectoryBrowser(directory: FSItem(path: "/"))
    }
}
#endif
