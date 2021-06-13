//
//  File.swift
//  
//
//  Created by Alessandro Saba on 10/06/21.
//

import Foundation
import SwiftUI

public let userDefaults = UserDefaults.standard
public let appGroup_directory = (FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.FilippoBrowser") ?? URL(string: "file://")!).path + "/"
public let documents_directory = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]).path + "/"
public let tmp_directory = FileManager.default.temporaryDirectory


public func setFavorite(name: String, path: String) {
	userDefaults.set(path, forKey: "FB_\(name)")
	userDefaults.synchronize()
}

/*
public func properView(for item: FSItem) -> AnyView {
	return AnyView(Text("Stub"))
}
*/

#if os(iOS)
extension View {
	// This is really ugly but it's the only way i could find to not require iOS 13.4 just for the hover function
	public func safeHover() -> AnyView {
		if #available(iOS 13.4, *){
			return AnyView(hoverEffect(.lift))
		} else {
			return AnyView(_fromValue: Self.self)!
		}
	}
}
#endif

extension String : Identifiable{
	public var id : UUID {
		return UUID()
	}
}
