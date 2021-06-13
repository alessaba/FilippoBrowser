//
//  File.swift
//  
//
//  Created by Alessandro Saba on 10/06/21.
//

import Foundation
import SwiftUI

// MARK: ContextMenu

#if os(iOS)
public struct ItemContextMenu : View {
	var subItem : FSItem
	@Binding var isSharePresented : Bool
	
	public init(_ subItem: FSItem, sharePresented: Binding<Bool>){
		self.subItem = subItem
		self._isSharePresented = sharePresented
	}
	
	public var body: some View{
		VStack {
			Text(subItem.lastComponent)
			Button(action: {
				subItem.isBookmarked.toggle()
				let newFavorite = UIMutableApplicationShortcutItem(type: "FB_\(subItem.lastComponent)", localizedTitle: subItem.lastComponent, localizedSubtitle: subItem.path, icon: UIApplicationShortcutIcon(systemImageName: subItem.isFolder ? "folder.fill" : "square.and.arrow.down.fill"))
				UIApplication.shared.shortcutItems?.append(newFavorite)
				
			}){
				Image(systemName: subItem.isBookmarked ? "heart.slash.circle.fill" : "heart.circle.fill")
				Text(subItem.isBookmarked ? "Remove from Favorites" : "Add to Favorites")
			}
			
			Button(action: {
				NSLog("Copy Path button pressed")
				UIPasteboard.general.string = "file://" + subItem.path
			}){
				Image(systemName: "doc.circle.fill")
				Text("Copy Path")
			}
			
			Button(action: {
				isSharePresented = true
			}){
				Image(systemName: "square.and.arrow.up.on.square.fill")
				Text("Share")
			}
		}
	}
}
#endif

// MARK: BookmarkItem
/*
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
}*/
