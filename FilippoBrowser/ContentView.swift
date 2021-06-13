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
	var body: some View {
		NavigationView {
			properDirectoryBrowser(for: FSItem(path: path))
			.navigationBarTitle(Text("File Browser"), displayMode: .inline)
            .navigationBarItems(
                
                leading:
                    Image(systemName: "f.circle.fill")
						.padding(.vertical, 10)
						.safeHover()
                        .onTapGesture {
								#if os(iOS)
								FLEXManager.shared.showExplorer()
								//UIApplication.shared.shortcutItems?.removeAll()
								#endif
								NSLog("FLEX activated!")
                    }
                ,
                trailing:
					HStack{
						Image(systemName: gridStyleEnabled ? "list.dash" :  "square.grid.2x2.fill").onTapGesture {
							userDefaults.flex_toggleBool(forKey: "gridStyleEnabled")
							//userDefaults.toggleBool(forKey: "gridStyleEnabled")
							gridStyleEnabled.toggle()
							//NSLog("Grid: \(gridStyleEnabled)")
						}
						
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
			properView(for: FSItem(path: NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]))
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
				Image(uiImage: UIImage(contentsOfFile: self.file.path)!)
				.resizable()
				.aspectRatio(contentMode: .fit)
			} else if (self.file.itemType == .threeD){
				SceneView(filePath: self.file.path)
			} else {
				QuickLookView(filePath: self.file.path)
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
	
	var body: some View {
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
								ItemContextMenu(subItem, sharePresented: $sharePresented)
                            }
					}.sheet(isPresented: $sharePresented, onDismiss: nil) {
						ActivityView(activityItems: [URL(string: "file://" + self.directory.path + subItem.lastComponent)!], applicationActivities: nil)
					}
                    
                    
                    //Detail subtext: Number of subelements in case of folders. Size of the file in case of files
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
			}
		.searchable(text: $searchText)
		.listStyle(GroupedListStyle())
		.navigationBarTitle(Text(directory.path), displayMode: .inline)
	}
}

// MARK: Directory Grid Viewer
// This is the directory browser, it shows files and subdirectories of a folder in grid style
struct DirectoryGridBrowser : View {
	@State private var searchText : String = ""
	@State private var sharePresented : Bool = false
	var directory : FSItem
	@Environment(\.colorScheme) var colorScheme
	
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
									.lineLimit(1)
									.foregroundColor(.blue)
							}
							
							//Detail subtext: Number of subelements in case of folders. Size of the file in case of files
							if subItem.isFolder {
								Text("\(subItem.subelements.count) \((subItem.subelements.count != 1) ? "elements" : "element" )")
									.foregroundColor(.secondary)
							} else {
								Text(subItem.fileSize)
									.foregroundColor(.secondary)
							}
						}
						.padding(.all, 10)
						.background(cellColor)
						.cornerRadius(10.0)
						//.shadow(radius: (colorScheme == .light) ? 3 : 0)
						.contextMenu{
							ItemContextMenu(subItem, sharePresented: $sharePresented)
						}
						.sheet(isPresented: $sharePresented, onDismiss: nil) {
							ActivityView(activityItems: [URL(string: "file://" + self.directory.path + subItem.lastComponent)!], applicationActivities: nil)
						}
					}
				}.searchable(text: $searchText)
			}
			.navigationBarTitle(Text(directory.path), displayMode: .inline)
		}
		.background((colorScheme == .light) ? Color.init(white: 0.95) : Color.black)
	}
}

// MARK: Go To View
struct gotoView : View {
	@State var path : String = "/"
	#warning("Must set a @State Property on the keys variable so when the variable is modified, the list is redrawn")
	let userDefaultsKeys = userDefaults.dictionaryRepresentation().keys.filter{
		$0.starts(with: "FB_")
	}
	
	var body : some View {
		VStack{
            Text("Go To...").bold()
            
			HStack{
				TextField("Path", text: $path)
					.padding(.all)
					.textFieldStyle(.roundedBorder)
				#warning("Could add / at the end if not already present")
				BookmarkItem(name: "Go", path: path, isButton: true)
			}
			
			
			Spacer(minLength: 25)
			
			ScrollView {
				BookmarkItem(name: "App Group ⌚️", path: appGroup_directory)
				
				#if os(iOS) || os(watchOS)
					BookmarkItem(name: "Media 🖥", path: "/var/mobile/Media/")
					BookmarkItem(name: "Documents 🗂", path: documents_directory)
					BookmarkItem(name: "App Container 💾", path: parentDirectory(tmp_directory.path))
				#endif
				
				#warning("Should find a way to update deletion and adding of elements in realtime")
				ForEach(userDefaultsKeys){ key in
					BookmarkItem(key: key)
				}
			}.padding(.horizontal)
		}
	}
}

// MARK: BookmarkItem

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
				.padding((self.type == .button) ? 0 : 10)
				.foregroundColor(self.color)
				.font(.system(size: 15).bold())
		}
		.buttonStyle(BorderedButtonStyle(tint: self.color))
		.padding(.horizontal, (self.type == .button) ? 0 : 10)
		#if os(iOS)
		.contextMenu{
			Button(role: .destructive,
				   action: {
							userDefaults.removeObject(forKey: self.key)
							
							UIApplication.shared.shortcutItems?.removeAll(where: { shortcut in
								return shortcut.type == self.key
							})
					},
					label: {
							Image(systemName: "bin.xmark.fill")
							Text("Delete")
					}
			)
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
		return properDirectoryBrowser(for: item)
	} else {
		return AnyView(FileViewer(file: item))
	}
}

func properDirectoryBrowser(for item: FSItem) -> AnyView {
	let gridEnabled = userDefaults.bool(forKey: "gridStyleEnabled")
	if gridEnabled{
		return AnyView(DirectoryGridBrowser(directory: item))
	} else {
		return AnyView(DirectoryListBrowser(directory: item))
	}
}



#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        Browser(path: "/")
    }
}
#endif
