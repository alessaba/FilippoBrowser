//
//  FileProviderItem.swift
//  RootBrowser
//
//  Created by Filippo Claudi on 06/06/21.
//  Copyright © 2021 Filippo Claudi. All rights reserved.
//

import FileProvider

class FileProviderItem: NSObject, NSFileProviderItem {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        return NSFileProviderItemIdentifier("\(UUID()))")
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        return NSFileProviderItemIdentifier("")
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return .allowsAll
    }
    
    var filename: String {
        return ""
    }
    
    var typeIdentifier: String {
        return ""
    }
    
}
