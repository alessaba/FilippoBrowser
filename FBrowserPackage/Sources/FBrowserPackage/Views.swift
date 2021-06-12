//
//  File.swift
//  
//
//  Created by Filippo Claudi on 10/06/21.
//

import Foundation
import SwiftUI

// MARK: BookmarkItem
/*
@available(iOS 15.0, watchOS 8.0, *)
public struct BookmarkItem: View {
	
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
	
	public init(name: String, path: String, isButton: Bool = false){
		self.key = ""
		self.name = name
		self.path = path
		self.type = isButton ? .button : .system
	}
	
	public init(key: String){
		self.key = key
		self.name = String(key.split(separator: "_").last!)
		self.path = String(userDefaults.string(forKey: key) ?? "/")
		self.type = .userAdded
	}
	
	public var body: some View {
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
		#if os(iOS)
			.safeHover()
		#endif
		Spacer()
	}
}
*/

