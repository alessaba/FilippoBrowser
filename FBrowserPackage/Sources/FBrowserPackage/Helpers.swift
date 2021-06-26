//
//  File.swift
//  
//
//  Created by Alessandro Saba on 10/06/21.
//

import Foundation
import SwiftUI

public let userDefaults : UserDefaults = UserDefaults.standard
public let fileManager : FileManager = FileManager.default

public let appGroup_directory = (fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.FilippoBrowser") ?? URL(string: "file://")!).path + "/"
public let documents_directory = (fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]).path + "/"
public let tmp_directory = fileManager.temporaryDirectory


public func setFavorite(name: String, path: String) {
	userDefaults.set(path, forKey: "FB_\(name)")
	userDefaults.synchronize()
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
