//
//  IntentHandler.swift
//  FileBrowserIntent
//
//  Created by Filippo Claudi on 09/06/2019.
//  Copyright © 2019 Filippo Claudi. All rights reserved.
//

import Intents
import Foundation

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
		guard intent is GetDirectoryListingIntent else { fatalError("Got an unexpected type of intent :-(")}
        return self //GetDirectoryListingIntentHandler()
    }
    
}


class GFI : NSObject, GetDirectoryListingIntentHandling {
	
	public var fm = FileManager.default
	
	func handle(intent: GetDirectoryListingIntent, completion: @escaping (GetDirectoryListingIntentResponse) -> Void) {
		
		let dirListing = try? fm.contentsOfDirectory(atPath: intent.path!)[0]
		
		if dirListing != nil {
			NSLog("Got a valid directory: \(intent.path!)\n\(dirListing!)")
			completion(.success(dirList: dirListing!))
		} 
	}
	
	func resolvePath(for intent: GetDirectoryListingIntent, with completion: @escaping (GetDirectoryListingPathResolutionResult) -> Void) {
		
		if intent.path == .none {
			completion(.needsValue())
		} else if (try? fm.contentsOfDirectory(atPath: intent.path!)) == [] {
			NSLog("\(intent.path!) is not a valid directory.")
			completion(.unsupported(forReason: .wrongPath))
		} else {
			completion(.success(with: intent.path!))
		}
	}
	
	
	
}

