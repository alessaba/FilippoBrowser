//
//  File.swift
//  
//
//  Created by Alessandro Saba on 10/06/21.
//

import Foundation
import SwiftUI
import CryptoKit

public let userDefaults : UserDefaults = UserDefaults.standard
public let fileManager : FileManager = FileManager.default

public let appGroup_directory = (fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.FilippoBrowser") ?? URL(string: "file://")!).path + "/"
public let documents_directory = (fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]).path + "/" //URL.documentsDirectory
public let tmp_directory =  FSItem(url: fileManager.temporaryDirectory)


public func setFavorite(_ item : FSItem){ //(name: String, path: String) {
	userDefaults.set(item.path, forKey: "FB4_\(item.uuid)")
	userDefaults.synchronize()
	
	let newFavorite = UIMutableApplicationShortcutItem(type: "FB4_\(item.uuid)", localizedTitle: item.lastComponent, localizedSubtitle: item.path, icon: UIApplicationShortcutIcon(systemImageName: item.isFolder ? "folder.fill" : "square.and.arrow.down.fill"))
	UIApplication.shared.shortcutItems?.append(newFavorite)
}

/*
public func properView(for item: FSItem) -> AnyView {
	return AnyView(Text("Stub"))
}
*/

private struct LazyView<Content : View> : View {
	var content : () -> Content
	var body: some View {
		self.content()
	}
}

#if os(iOS)
// How to add SwiftUI properties not supported by every version of your build target
extension View {
	// This is really ugly but it's the only way i could find to not require iOS 13.4 just for the hover function
	public func safeHover() -> AnyView {
		if #available(iOS 13.4, *){
			return AnyView(hoverEffect(.lift))
		} else {
			return AnyView(_fromValue: Self.self)!
		}
	}
	
	public func any() -> AnyView {
		return AnyView(self)
	}
	
	public func lazy() -> AnyView {
		return AnyView(LazyView{self})
	}
}
#endif

// Not sure how better it is compared to just using \.self in a id parameter of a List() but ok
extension String : Identifiable{
	public var id : UUID {
		return UUID()
	}
}

infix operator **
func **(sinistra: Int, destra: Int) -> Int {
	var result : Int = 1
	for _ in 1...destra{
		result *= sinistra
	}
	return result
}

func hash(_ str : String) -> String {
	String(CryptoKit.SHA256.hash(data: str.data(using: .utf8) ?? Data()).description.dropFirst(15))
}

// MARK: Troubleshooting Functions

// v4 introduced a different way of handling bookmarks. let's make a function to convert old ones at launch
// We could have also done this at the first v4 launch, then checking every launch if a userdefault named "v4Upgraded" was true. But i am going to use this manually in the "secret" debug menu
public func bookmarksUpgrade_4(){
	let oldKeys = userDefaults.dictionaryRepresentation().keys.filter{
		($0.starts(with: "FB4_"))
	}
	
	rebuildShortcuts()
	
	for k in oldKeys {
		let val = userDefaults.string(forKey:k)
		print("Setting \("FB4_\(hash(val!))") for \(val!.dropLast(1))")
		userDefaults.removeObject(forKey: k)
		setFavorite(FSItem(path: val!))
		//userDefaults.set(val!.dropLast(1), forKey: "FB4_\(hash(val!))")
	}
	
	print(oldKeys.description)
}

public func rebuildShortcuts(){
	UIApplication.shared.shortcutItems?.removeAll()
	//setFavorite(<#T##item: FSItem##FSItem#>)
}
