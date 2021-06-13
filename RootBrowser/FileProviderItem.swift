//
//  FileProviderItem.swift
//  RootBrowser
//
//  Created by Alessandro Saba on 06/06/21.
//  Copyright © 2021 Alessandro Saba. All rights reserved.
//

import FileProvider

enum ItemType : String{
	case file = "public.file"
	case directory = "public.directory"
	case image = "public.image"
	case text = "public.text"
	//case tidimensionalObj
}

class FileProviderItem: NSObject, NSFileProviderItem {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model
    
	// Proprietà fondamentali
	var filename: String = "Test"
	var typeIdentifier: String = "public.item"
	var itemIdentifier: NSFileProviderItemIdentifier = NSFileProviderItemIdentifier("\(UUID()))")
    var parentItemIdentifier: NSFileProviderItemIdentifier = NSFileProviderItemIdentifier("")
	
	// Impostiamo la visualizzazione in sola lettura, dato che ci serve solo visualizzare
	var capabilities: NSFileProviderItemCapabilities = .allowsReading
	//var documentSize: NSNumber?
    
	
	// Inizializzatore per le 4 proprietà fondamentali. internal perchè non ci serve esporre fuori dalla estensione
	internal init(name: String, type:ItemType, itemID: String, parentID:String) {
		filename = name
		typeIdentifier = type.rawValue
		itemIdentifier = NSFileProviderItemIdentifier(itemID)
		parentItemIdentifier = NSFileProviderItemIdentifier(parentID)
		
		super.init()
	}
	
	internal init(path: String) {
		filename = String(path.split(separator: "/").last ?? "Root")
		itemIdentifier = NSFileProviderItemIdentifier(path)
		parentItemIdentifier = NSFileProviderItemIdentifier(path)
		typeIdentifier = findType(path).rawValue
		
		super.init()
	}
	
	
    
}

func findType(_ path: String) -> ItemType{
	let fileExt = String(path.split(separator: ".").last ?? "")
	
	switch fileExt {
	case "":
		return .directory
	case "txt":
		return .text
	case "png", "jpeg":
		return .image
	default:
		return .file
	}
}
