//
//  ContentView.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 09/06/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import SwiftUI
import WatchKit
import Foundation
import WatchConnectivity
import FBrowserPackage

// MARK: File Viewer
// This shows the contents of most types of common files
struct FileViewer : View {
	var file : FSItem
	
	var body: some View {
		VStack {
			#warning("Would be nice to be able to share the real file")
			ShareLink("Share Path", item: self.file.path)
			//ShareLink(items: Data(contentsOf: self.file.url))
			// We can only view images for now
			if (self.file.itemType == .Image){
				Image(uiImage: UIImage(contentsOfFile: self.file.path)!)
					.resizable()
					.aspectRatio(contentMode: .fit)
			} else {
				// If the file is not a image, try to transfer it to the iPhone
				Text(self.file.path)
				.onAppear{
					let newUrl = tmp_directory.urlByAppending(path: self.file.lastComponent)
					try? fileManager.copyItem(at: self.file.url, to: newUrl)
					session.transferFile(newUrl, metadata: nil)
					print("File \(self.file.lastComponent) transferred to iPhone (maybe)")
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
	@State private var bookmarkButtonPressed : Bool = false
	@State private var resetAlertPresented : Bool = false

    var directory : FSItem

	var body: some View {
		List{
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
                    .foregroundColor((subItem.isEmpty) ? .gray : .green)
					
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
                        
                        //Detail Subtext
                        if subItem.isFolder {
							// Number of subelements in case of folders.
                            Text("\(subItem.subelements.count) \((subItem.subelements.count != 1) ? "elements" : "element" )")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
							// Size of the file in case of files
                            Text(subItem.fileSize)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
			}
		}
		.searchable(text: $searchText) // Search Bar
		.toolbar{
			Section{
				if (directory.path == "/"){
					NavigationLink(destination: gotoView()){
						Text("Go To...")
					}
				} else {
					Button(action: {
						directory.isBookmarked.toggle()
						bookmarkButtonPressed.toggle()
					}){
						HStack{
							// Add/Remove from Favourites button
							Image(systemName: (directory.isBookmarked || bookmarkButtonPressed) ? "heart.slash" : "heart.fill").foregroundColor(.red)
							Text((directory.isBookmarked || bookmarkButtonPressed) ? " Remove from Favourites" : "  Add to Favorites")
								.onLongPressGesture {
									self.resetAlertPresented = true
								}
						}.alert("Reset Bookmarks", isPresented: $resetAlertPresented){
							Button("Reset", role: .destructive){bookmarksUpgrade_4()}
							Button("Cancel", role: .cancel){}
						}
					}
				}
			}
		}
    }
}

// MARK: Go To View
// This view contains a launchpad to quickly jump to other directories
struct gotoView : View {
    @State var path : String = "/"
	@State var userDefaultsKeys : [String] = []
	
    var body : some View {
		ScrollView{
			
			// Enter a custom path
			TextField("Path", text: $path)
			BookmarkItem(name: "Go", path: path, isButton: true)
			
			Spacer(minLength: 20)
			
			// Pre-defined bookmarks
			BookmarkItem(name: "Media 🖥", path: "/var/mobile/Media/")
			BookmarkItem(name: "App Container 💾", path: tmp_directory.parentItem.path)
			
			// User Added Bookmarks
			ForEach(userDefaultsKeys){ key in
				BookmarkItem(key: key, defaultsArray: $userDefaultsKeys)
			}
			
			Spacer(minLength: 30)
			
			// Disk Space Section
			Text("Used Space")
			
			Spacer()
			
			HStack{
				Gauge(value: usedCapacity(),
					  in: 0...totalCapacity(),
					  label: {Text("GB")},
					  currentValueLabel: {Text(GBFormatter(usedCapacity())).foregroundColor(.indigo).dynamicTypeSize(.small)}
				)
					.gaugeStyle(CircularGaugeStyle(tint: .indigo))
			}.onTapGesture {
				print("Total Space: \(GBFormatter(totalCapacity()))")
			}
			
		}.onAppear{
			userDefaultsKeys = userDefaults.dictionaryRepresentation().keys.filter{
				return $0.starts(with: "FB4_")
			}
		}
	}
}


// MARK: BookmarkItem

struct BookmarkItem: View {
	
	enum BookmarkItemType{
		case system, userAdded, button
	}
	
	var key : String
	var path : String
	var name : String
	var type : BookmarkItemType
	
	@Binding var defaultsList : [String]
	
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
	
	// Used for System defined buttons or bookmarks
	init(name: String, path: String, isButton: Bool = false){
		self.key = ""
		self.path = path
		self.name = name
		self.type = isButton ? .button : .system
		self._defaultsList = .constant([])
	}
	
	// Used for user added bookmarks
	init(key: String, defaultsArray : Binding<Array<String>>){
		self.key = key
		self.path = String(userDefaults.string(forKey: key) ?? "/")
		self.name = String(self.path.split(separator: "/").last ?? "???")
		self.type = .userAdded
		self._defaultsList = defaultsArray
	}
	
	var body: some View {
		// Style the button based on the type
		NavigationLink(destination: properView(for: FSItem(path: self.path))){
			Text(name)
				.padding((self.type == .button) ? 0 : 10)
				.foregroundColor(self.color)
				.font(.system(size: 15).bold())
		}
		.buttonStyle(BorderedButtonStyle(tint: self.color))
		.padding(.horizontal, (self.type == .button) ? 0 : 10)
		#if os(iOS)
		.contextMenu{
			// Only show the context menu if the user created the bookmark.
			if type == .userAdded {
				Button(role: .destructive,
					   action: {
					// Remove the bookmark
					userDefaults.removeObject(forKey: key)
					
					// Make the Bookmarks list reload
					defaultsList.removeAll{
						$0 == key
					}
					
					// Remove item from 3D Touch menu
					UIApplication.shared.shortcutItems?.removeAll{ shortcut in
						return shortcut.type == key
					}
					
					print("Removed \"\(key)\"")
				},
					   label: {
					Image(systemName: "bin.xmark.fill")
					Text("Delete")
				}
				)
			}
		}
		.safeHover()
		#endif
		Spacer()
	}
}

struct EmptyItem : View {
	var body: some View {
		VStack{
			Image(systemName: "questionmark.folder.fill").imageScale(.large).font(.system(size: 50))
			Text("Item Empty or Inaccessible").font(.headline)
		}.foregroundColor(.secondary)
	}
}


// MARK: Disk Space
// This section tries to get the used and free space on disk. Need to optimize this

func totalCapacity() -> Double {
	do{
		let systemAttributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
		let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.doubleValue
		return round(space ?? 1)
	} catch {
		return 1
	}
}

func freeCapacity() -> Double {
	do{
		let systemAttributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
		let space = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.doubleValue
		return round(space ?? 1)
	} catch {
		return 1
	}
}

func usedCapacity() -> Double {
	totalCapacity() - freeCapacity()
}

func GBFormatter(_ bytes: Double) -> String {
	let formatter = ByteCountFormatter()
	formatter.allowedUnits = ByteCountFormatter.Units.useGB
	formatter.countStyle = ByteCountFormatter.CountStyle.decimal
	formatter.includesUnit = false
	return formatter.string(fromByteCount: Int64(bytes)) as String
}

// Decide what view to present: FileViewer for files, DirectoryBrowser for directories
func properView(for item: FSItem) -> AnyView {
	if item.isEmpty{
		return AnyView(EmptyItem())
	} else {
		if item.isFolder{
			return AnyView(DirectoryBrowser(directory: item))
		} else {
			return AnyView(FileViewer(file: item))
		}
	}
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        DirectoryBrowser(directory: FSItem(path: "/"))
    }
}
#endif
