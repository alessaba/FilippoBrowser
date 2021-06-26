//
//  ContentView.swift
//  FilippoBrowser
//
//  Created by Alessandro Saba on 09/06/2019.
//  Copyright © 2019 Alessandro Saba. All rights reserved.
//

import SwiftUI
import UIKit
import Foundation
import FBrowserPackage

import FLEX

// MARK: Starting View
// Starting point
struct Browser : View {
	
	@State var path : String
	@State var gridStyleEnabled : Bool = userDefaults.bool(forKey: "gridStyleEnabled")
    @State private var watchFilesPresented : Bool = false // We need it for presenting the popover 🙄
	
	// We can make different layouts for different Accessibility Text Sizes
	@Environment(\.dynamicTypeSize) var dtSize
	
	var body: some View {
		NavigationView {
			properView(for: FSItem(path: path))
			.navigationBarTitle(Text("File Browser"), displayMode: .inline)
            .navigationBarItems(
                leading:
                    Image(systemName: "f.circle.fill")
						.padding(.vertical, 10)
						.safeHover()
                        .onTapGesture {
								#if os(iOS)
								// FLEX is only available in iOS
								FLEXManager.shared.showExplorer()
								//UIApplication.shared.shortcutItems?.removeAll()
								#endif
								NSLog("FLEX activated!")
                    }
                ,
                trailing:
					HStack{
						// If the text size is small enough for the grid view, let the user enable it
						if (dtSize < .accessibility2) {
							// The icon changes to reflect the outcome of the button
							Image(systemName: gridStyleEnabled ? "list.dash" :  "square.grid.2x2.fill").onTapGesture {
								userDefaults.flex_toggleBool(forKey: "gridStyleEnabled")
								gridStyleEnabled.toggle()
							}
						}
						
						// Button Linked to the GoTo launchpad view
						NavigationLink(destination: gotoView()){
							Image(systemName: "arrow.right.circle.fill")
								.padding(.vertical, 10)
								.safeHover()
								.foregroundColor(.primary)
						}.padding(.leading, 40)
					}
            )
		}.onAppear{
			//NotificationCenter.default.addObserver(self, selector: #selector("watchFileReceived"), name: Notification.Name("watchFileReceived"), object: nil)
		}.sheet(isPresented: $watchFilesPresented){
			// If the iPhone receives a file from the Watch, open the folder that contains that file
			properView(for: FSItem(path: documents_directory))
		}
	}
}


// MARK: File Viewer
// This shows the contents of most types of common files
struct FileViewer : View {
	var file : FSItem
	@State private var sheetPresented : Bool = false
	
	var body: some View {
		Group {
			if (self.file.itemType == .Image){
				// Show a Image View if the file is a Image. More efficient than QuickLook
				Image(uiImage: UIImage(contentsOfFile: self.file.path)!)
				.resizable()
				.aspectRatio(contentMode: .fit)
			} else if (self.file.itemType == .threeD){
				// Show a 3D Viewer if the file is 3D Representable
				SceneView(filePath: self.file.path)
			} else {
				// For every other file type, show QuickLook
				QuickLook(filePath: self.file.path).lazy()
			}
		}
	}
}


// MARK: Directory List Viewer
// This is the directory browser, it shows files and subdirectories of a folder in list style
struct DirectoryListBrowser : View {
    @State private var searchText : String = ""
	@State private var sharePresented : Bool = false
	var directory : FSItem
	
	// We can make different layouts for different Accessibility Text Sizes
	@Environment(\.dynamicTypeSize) var dtSize
	
	var body: some View {
		// MARK: Search Function
		// The entries will update automatically eveerytime searchText changes! 🤩
		
		let subelements = directory.subelements.filter{
			if searchText == ""{
				// Every item will be shown
				return true
			} else {
				// Only the items containing the search term will be shown (fuzzy too 🤩)
				return $0.lastComponent.lowercased().contains(searchText.lowercased())
			}
		}
		
        List(subelements) { subItem in
			HStack{
                    // Test for various file types and assign icons (SFSymbols, which are GREAT <3)
					Image(systemName: subItem.itemType.rawValue)
						.foregroundColor((subItem.rootProtected) ? .orange : .green)
                     
                    //Name of the file/directory
                    NavigationLink(destination: properView(for: subItem)){
                        Text(subItem.lastComponent)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.blue)
                            .padding(.leading)
                            .contextMenu{
								// Unified ContextMenu view between grid and list view
								ItemContextMenu(subItem, sharePresented: $sharePresented)
                            }
					}.sheet(isPresented: $sharePresented, onDismiss: nil) {
						// Present the share sheet
						ShareView(activityItems: [subItem.url])
					}
					
					// Don't show a subtext if the text accessibility setting is set too large, it's not THAT important for a user with low eyesight anyway
					if dtSize < .xxxLarge {
						//Detail SubText: Number of subelements in case of folders. Size of the file in case of files
						if subItem.isFolder {
							Text("\(subItem.subelements.count) \((subItem.subelements.count != 1) ? "elements" : "element" )")
								.foregroundColor(.secondary)
								.padding(.leading)
						} else {
							Text(subItem.fileSize)
								.foregroundColor(.secondary)
								.padding(.leading)
						}
					}
				
				}.swipeActions(edge: .leading, allowsFullSwipe: true){
					Button{
						subItem.isBookmarked.toggle()
					} label: {
						Image(systemName: subItem.isBookmarked ? "heart.slash" : "heart")
					}
				}
			}
		.searchable(text: $searchText) // Search Bar
		.navigationBarTitle(Text(directory.path), displayMode: .inline)
	}
}

// MARK: Directory Grid Viewer
// This is the directory browser, it shows files and subdirectories of a folder in grid style
struct DirectoryGridBrowser : View {
	@State private var searchText : String = ""
	@State private var sharePresented : Bool = false
	var directory : FSItem
	
	// React based on Light/Dark Mode and Text Size
	@Environment(\.dynamicTypeSize) var dtSize
	@Environment(\.colorScheme) var colorScheme
	
	// Compute the cell color depending on Light or Dark mode
	var cellColor : Color {
		get{
			if colorScheme == .dark{
				return Color(white: 0.15)
			} else if colorScheme == .light{
				return .white
			}
			return .black
		}
	}
	
	var body: some View {
		ScrollView {
			VStack{
				LazyVGrid(columns: Array(repeating: .init(.adaptive(minimum: 150, maximum: 150)), count: 3) as [GridItem]){
					
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
						VStack{
							// Test for various file types and assign icons (SFSymbols, which are GREAT <3)
							Image(systemName: subItem.itemType.rawValue)
								.foregroundColor((subItem.rootProtected) ? .orange : .green)
								.padding(.vertical, 5)
								.padding(.horizontal, 30)

							//Name of the file/directory
							NavigationLink(destination: properView(for: subItem)){
								Text(subItem.lastComponent)
									.fontWeight(.semibold)
									.lineLimit((dtSize < .xxLarge) ? 2 : 3)
									.foregroundColor(.blue)
							}
							
							// Don't show a subtext if the text accessibility setting is set too large, it's not THAT important for a user with low eyesight anyway
							if dtSize < .xxLarge{
								//Detail SubText: Number of subelements in case of folders. Size of the file in case of files
								if subItem.isFolder {
									Text("\(subItem.subelements.count) \((subItem.subelements.count != 1) ? "elements" : "element" )")
										.foregroundColor(.secondary)
								} else {
									Text(subItem.fileSize)
										.foregroundColor(.secondary)
								}
							}
						}
						.padding(.all, 10)
						.background(cellColor)
						.cornerRadius(10.0)
						.contextMenu{
							// Unified ContextMenu view between grid and list view
							ItemContextMenu(subItem, sharePresented: $sharePresented)
						}
						.sheet(isPresented: $sharePresented, onDismiss: nil) {
							ShareView(activityItems: [URL(fileURLWithPath: self.directory.path + subItem.lastComponent)])
						}
					}
				}.searchable(text: $searchText) // Search Bar
			}
			.navigationBarTitle(Text(directory.path), displayMode: .inline)
		}
		.background((colorScheme == .light) ? Color.init(white: 0.95) : Color.black)
	}
}

// MARK: Go To View
// This view contains a launchpad to quickly jump to other directories
struct gotoView : View {
	@State var path : String = ""
	@State var userDefaultsKeys : [String] = []
	
	var body : some View {
		
		var subpaths : [FSItem] {
			if (path.split(separator: "/").last?.count ?? 0) > 1 {
				return FSItem(path: parentDirectory(path)).subelements.filter{ subElement in
					return subElement.path.lowercased().contains(path.lowercased())
				}
			} else {
				return []
			}
		}
		
		return VStack{
			NavigationLink(destination: properView(for: FSItem(path: self.path))){
				HStack{
					Spacer()
					Text("Go")
						.padding(10)
						.foregroundColor(.green)
						.font(.body.bold())
					Spacer()
				}
			}
			.buttonStyle(.bordered)
			
			Spacer(minLength: 25)
			
			ScrollView {
				// Search Suggestions
				ForEach(subpaths){ suggestion in
					Button(action: {
						path = parentDirectory(path) + suggestion.lastComponent + "/"
					}, label: {
						Text(suggestion.lastComponent)
							.padding(10)
							.foregroundColor(.primary)
							.font(.body.bold())
					})
						.buttonStyle(.bordered)
						.tint(.teal)
				}
				
				// Pre-defined bookmarks
				BookmarkItem(name: "App Group ⌚️", path: appGroup_directory)
				#if os(iOS) || os(watchOS)
					BookmarkItem(name: "Media 🖥", path: "/var/mobile/Media/")
					BookmarkItem(name: "Documents 🗂", path: documents_directory)
					BookmarkItem(name: "App Container 💾", path: parentDirectory(tmp_directory.path))
				#endif
				
				// User Added Bookmarks
				ForEach(userDefaultsKeys){ key in
					BookmarkItem(key: key, defaultsArray: $userDefaultsKeys)
				}
				
			}
			.padding(.horizontal)
			.searchable(text: $path, prompt: "Path").keyboardType(.URL)
			}.onAppear{
				userDefaultsKeys = userDefaults.dictionaryRepresentation().keys.filter{
					$0.starts(with: "FB_")
				}
			}.navigationTitle("Go To")
	}
}

// MARK: BookmarkItem

struct BookmarkItem: View {
	
	enum BookmarkItemType{
		case system, userAdded
	}
	
	var key : String
	var name : String
	var path : String
	var type : BookmarkItemType
	
	@Binding var defaultsList : [String]
	
	var color : Color{
		switch self.type{
			case .system:
				return .blue
			case .userAdded:
				return .red
		}
	}
	
	// Used for System defined buttons or bookmarks
	init(name: String, path: String){
		self.key = ""
		self.name = name
		self.path = path
		self.type = .system
		self._defaultsList = .constant([])
	}
	
	// Used for user added bookmarks
	init(key: String, defaultsArray : Binding<Array<String>>){
		self.key = key
		self.name = String(key.split(separator: "_").last!)
		self.path = String(userDefaults.string(forKey: key) ?? "/")
		self.type = .userAdded
		self._defaultsList = defaultsArray
	}
	
	var body: some View {
		// Style the button based on the type
		NavigationLink(destination: properView(for: FSItem(path: self.path))){
			Text(name)
				.padding(10)
				.foregroundColor(self.color)
				.font(.body.bold())
		}
		.buttonStyle(.bordered)
		.tint(self.color)
		.padding(.horizontal, 10)
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
							
							NSLog("Removed \"\(key)\"")
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


// MARK: Helper Functions

// Decide what view to present: FileViewer for files, DirectoryBrowser for directories
func properView(for item: FSItem) -> AnyView {
	if item.isFolder{
		let gridEnabled = userDefaults.bool(forKey: "gridStyleEnabled")
		if gridEnabled{
			return DirectoryGridBrowser(directory: item).lazy()
		} else {
			return DirectoryListBrowser(directory: item).lazy()
		}
	} else {
		return FileViewer(file: item).lazy()
	}
}




#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        Browser(path: "/")
    }
}
#endif
