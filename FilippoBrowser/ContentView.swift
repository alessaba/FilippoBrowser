//
//  ContentView.swift
//  FilippoBrowser
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import SwiftUI
import UIKit
import Foundation
import FBrowser

import QuickLook
import SceneKit

import FLEX

let userDefaults = UserDefaults.standard
let appGroup_directory = (FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.FilippoBrowser") ?? URL(string: "file://")!).path + "/"
let documents_directory = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]).path + "/"
let tmp_directory = FileManager.default.temporaryDirectory

// MARK: Starting View
// Starting point
struct Browser : View {
	
	@State var path : String
	@State var gridStyleEnabled : Bool = UserDefaults.standard.bool(forKey: "gridStyleEnabled")
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
                            //UIPasteboard.general.string = "file//" + self.path
                    }
                ,
                trailing:
					HStack{
						Image(systemName: gridStyleEnabled ? "list.dash" :  "square.grid.2x2.fill").onTapGesture {
							UserDefaults.standard.flex_toggleBool(forKey: "gridStyleEnabled")
							//UserDefaults.standard.toggleBool(forKey: "gridStyleEnabled")
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
	@State private var popoverPresented : Bool = false
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
								VStack {
									Text(subItem.lastComponent)
									Button(action: {
										setFavorite(name: subItem.lastComponent, path: subItem.path)
										let newFavorite = UIMutableApplicationShortcutItem(type: "FB_\(subItem.lastComponent)", localizedTitle: subItem.lastComponent, localizedSubtitle: subItem.path, icon: UIApplicationShortcutIcon(systemImageName: subItem.isFolder ? "folder.fill" : "square.and.arrow.down.fill"))
										UIApplication.shared.shortcutItems?.append(newFavorite)
										NSLog("Added to Favorites.")
									}){
										Image(systemName: "heart.circle.fill")
										Text("Add to Favorites")
									}
									
									Button(action: {
										NSLog("Copy Path button pressed")
										UIPasteboard.general.string = "file://" + self.directory.path + subItem.lastComponent
									}){
										Image(systemName: "doc.circle.fill")
										Text("Copy Path")
									}
									
									Button(action: {
										self.popoverPresented = true
									}){
										Image(systemName: "square.and.arrow.up.on.square.fill")
										Text("Share")
									}
								}
                            }
					}.sheet(isPresented: $popoverPresented, onDismiss: nil) {
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

#warning("Fix Dark cells in Light mode (gridView)")
// MARK: Directory Grid Viewer
// This is the directory browser, it shows files and subdirectories of a folder in grid style
struct DirectoryGridBrowser : View {
	@State private var searchText : String = ""
	@State private var popoverPresented : Bool = false
	var directory : FSItem
	
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
						.background(Color.init(.displayP3, white: 0.15, opacity: 1.0))
						.cornerRadius(10.0)
						.contextMenu{
							VStack {
								Text(subItem.lastComponent)
								Button(action: {
									setFavorite(name: subItem.lastComponent, path: subItem.path)
									let newFavorite = UIMutableApplicationShortcutItem(type: "FB_\(subItem.lastComponent)", localizedTitle: subItem.lastComponent, localizedSubtitle: subItem.path, icon: UIApplicationShortcutIcon(systemImageName: subItem.itemType.rawValue)) //subItem.isFolder ? "folder.fill" : "square.and.arrow.down.fill"))
									UIApplication.shared.shortcutItems?.append(newFavorite)
									NSLog("Added to Favorites.")
								}){
									Image(systemName: "heart.circle.fill")
									Text("Add to Favorites")
								}
								
								Button(action: {
									NSLog("Copy Path button pressed")
									UIPasteboard.general.string = "file://" + self.directory.path + subItem.lastComponent
								}){
									Image(systemName: "doc.circle.fill")
									Text("Copy Path")
								}
							
								Button(action: {
									self.popoverPresented = true
								}){
									Image(systemName: "square.and.arrow.up.on.square.fill")
									Text("Share")
								}
							}
						}
						.sheet(isPresented: $popoverPresented, onDismiss: nil) {
							ActivityView(activityItems: [URL(string: "file://" + self.directory.path + subItem.lastComponent)!], applicationActivities: nil)
						}
					}
				}.searchable(text: $searchText)
			}
			.navigationBarTitle(Text(directory.path), displayMode: .inline)
		}
	}
}

// MARK: Go To View
struct gotoView : View {
	@State var path : String = "/"
	#warning("Must set a @State Property on the keys variable so when the variable is modified, the list is redrawn")
	let userDefaultsKeys = UserDefaults.standard.dictionaryRepresentation().keys.filter{
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
		#warning("ContextMenu does not seem to work now")
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
		.safeHover()
		Spacer()
	}
	
}


// MARK: UIKit Views

struct ActivityView: UIViewControllerRepresentable {
    // Port of the UIActivityViewController to SwiftUI. basically we proxy the arguments then conform to the protocol.
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) { NSLog("ActivityVC called") }
}

struct SceneView: UIViewControllerRepresentable {
	let filePath: String
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<SceneView>) -> UIViewController {
		let scene = SCNScene(named: String(filePath.dropLast()))
		let sceneView = SCNView()
		sceneView.allowsCameraControl = true
		//sceneView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
		sceneView.scene = scene!
		sceneView.isJitteringEnabled = true //Smooth the movement
		sceneView.antialiasingMode = .multisampling2X // Lotta power needed but lil bit smoothr
		sceneView.preferredFramesPerSecond = 60
		sceneView.showsStatistics = true
		
		//scene?.rootNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 10, z: 0, duration: 5)))
		
		let camera = SCNCamera()
		let camera_node = SCNNode()
		camera_node.camera = camera
		camera_node.position = SCNVector3(-3,3,3)
		
		sceneView.scene?.rootNode.addChildNode(camera_node)
		
		let sceneVC = UIViewController()
		sceneVC.view = sceneView
		return sceneVC
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<SceneView>) { NSLog("SceneVC called.") }
}

struct QuickLookView: UIViewControllerRepresentable {
	let filePath: String
	
	class QuickLookDataSource : NSObject, QLPreviewControllerDataSource{
		let parent: QuickLookView
		
		init(parent: QuickLookView) { self.parent = parent }
		
		func numberOfPreviewItems(in controller: QLPreviewController) -> Int { return 1 }
		
		func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
			let tempPath = (tmp_directory.appendingPathComponent(String(parent.filePath.split(separator: "/").last ?? "")))
			
			do{
				try FileManager.default.copyItem(at: URL(string: "file://\(parent.filePath)")!, to: tempPath)
			} catch {
				print("Failed to copy to tmp")
			}
			
			return tempPath as NSURL
		}
	}
	
	func makeCoordinator() -> QuickLookDataSource {
		return QuickLookDataSource(parent: self)
	}
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<QuickLookView>) -> UIViewController {
		let qv = QLPreviewController()
		qv.dataSource = context.coordinator
		
		let navigationController = UINavigationController(rootViewController: qv)
		return navigationController
	}

	func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<QuickLookView>) { NSLog("QuickLook called.") }
}



// MARK: – Helper Functions

public func setFavorite(name : String, path : String) {
	userDefaults.set(path, forKey: "FB_\(name)")
	userDefaults.synchronize()
}

// Decide what view to present: FileViewer for files, DirectoryBrowser for directories
func properView(for item: FSItem) -> AnyView {
	if item.isFolder{
		return properDirectoryBrowser(for: item)
	} else {
        return AnyView(FileViewer(file: item))
	}
}

func properDirectoryBrowser(for item: FSItem) -> AnyView {
	let gridEnabled = UserDefaults.standard.bool(forKey: "gridStyleEnabled")
	if gridEnabled{
		return AnyView(DirectoryGridBrowser(directory: item))
	} else {
		return AnyView(DirectoryListBrowser(directory: item))
	}
}


extension View {
	// This is really ugly but it's the only way i could find to not require iOS 13.4 just for the hover function
	func safeHover() -> AnyView {
		if #available(iOS 13.4, *){
			return AnyView(hoverEffect(.lift))
		} else {
			return AnyView(_fromValue: Self.self)!
		}
	}
}

extension String : Identifiable{
	public var id : UUID {
		return UUID()
	}
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        Browser(path: "/")
    }
}
#endif
