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
//import NotificationCenter

let userDefaults = UserDefaults.standard
let textExtensions = ["txt"]
let listExtensions = ["plist", "json"]
let imageExtensions = ["jpg", "jpeg", "png" , "tiff"]


// MARK: Starting View
// Starting point
struct Browser : View {
	
	var path : String
    @State private var watchFilesPresented : Bool = false // We need it for presenting the popover 🙄
    
	var body: some View {
		NavigationView {
			DirectoryBrowser(directory: FSItem(path: path))
                .navigationBarTitle(Text("File Browser"), displayMode: .inline)
            .navigationBarItems(
                
                leading:
                    Image(systemName: "paperclip.circle.fill")
                        .onTapGesture {
                            UIPasteboard.general.string = "file//" + self.path
                    }
                ,
                trailing:
                NavigationLink(destination: gotoView()){
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.primary)
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
    @State private var popoverPresented : Bool = false
    
    var body: some View {
        Text(self.file.path)
        .onAppear { self.popoverPresented = true }
        .sheet(isPresented: $popoverPresented){
            ActivityView(activityItems: [URL(string: "file://" + self.file.path)!], applicationActivities: nil)
        }.onDisappear{
            NSLog("Share Sheet dismissed.")
        }
        
    }
    
}

// MARK: Directory Viewer
// This is the directory browser, it shows files and subdirectories of a folder
struct DirectoryBrowser : View {
    
    @State private var searchText : String = ""
	var directory : FSItem
    
	var body: some View {
        List{
            
            Section{
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
                HStack {
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
                    
                    
                        
                    
                    //Name of the file/directory
                    NavigationLink(destination: properView(for: subItem)){
                        Text(subItem.lastComponent)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.blue)
                            .padding(.leading)
                            .contextMenu{
								
								VStack {
									Button(action: {
										setFavorite(name: subItem.lastComponent, path: subItem.path)
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
								}
                            }
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
		}
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text(directory.path), displayMode: .inline)
	}
}

// MARK: Go To View
struct gotoView : View {
	@State var path : String = "/"
	
	var body : some View {
		VStack{
            Text("Go To...").bold()
            TextField("Path", text: $path)
                .padding(.all)
                .background(Color.gray)
                .cornerRadius(15)
                .padding(.all)
			HStack{
				NavigationLink(destination: favoritesView()){
					Text("Favorites ♥️")
						.foregroundColor(.primary)
						.bold()
						.padding()
						.background(Color.blue)
						.cornerRadius(15)
				}
				Spacer()
				
				NavigationLink(destination: properView(for: FSItem(path: path))){
					Text("Go")
						.foregroundColor(.primary)
						.bold()
						.padding()
						.background(Color.blue)
						.cornerRadius(15)
				}
				
				Spacer()
				NavigationLink(destination: properView(for: FSItem(path: NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]))){
					Text("Documents")
						.foregroundColor(.primary)
						.bold()
						.padding()
						.background(Color.blue)
						.cornerRadius(15)
				}
			}.padding(.horizontal)
		}
	}
}

extension String : Identifiable{
	public var id : UUID {
		return UUID()
	}
}

struct favoritesView : View {
	var userDefaultsKeys = UserDefaults.standard.dictionaryRepresentation().keys
	
	var body : some View{
		List(userDefaultsKeys.filter{
			return $0.starts(with: "FB_")
		}){ key in
			NavigationLink(destination:
				properView(for: FSItem(path: userDefaults.string(forKey: key) ?? "/"))
			){
				Text(String(key.split(separator: "_").last!))
					.contextMenu{
						Button(action: {
							userDefaults.removeObject(forKey: key)
						}){
							Image(systemName: "bin.xmark.fill")
							Text("Delete")
						}.foregroundColor(.red)
				}
			}
			.listStyle(GroupedListStyle())
		}
	}
}


// MARK: – Helper Functions


struct ActivityView: UIViewControllerRepresentable {
    // Port of the UIActivityViewController to SwiftUI. basically we proxy the arguments then conform to the protocol.
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems,
                                        applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: UIViewControllerRepresentableContext<ActivityView>) {
        NSLog("ActivityVC called. whatever.")
    }
}


// Gets the file extension for later use
func getExtension(_ path: String) -> String {
	return String(path.split(separator: ".").last ?? "")
}

public func setFavorite(name : String, path : String) {
	userDefaults.set(path, forKey: "FB_\(name)")
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
        Browser(path: "/")
    }
}
#endif



