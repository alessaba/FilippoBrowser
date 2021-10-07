//
//  PreviewProvider.swift
//  PropertyLister
//
//  Created by Filippo Claudi on 7/10/21.
//  Copyright © 2021 Filippo Claudi. All rights reserved.
//

import QuickLook

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    

    /*
     Use a QLPreviewProvider to provide data-based previews.
     
     To set up your extension as a data-based preview extension:

     - Modify the extension's Info.plist by setting
       <key>QLIsDataBasedPreview</key>
       <true/>
     
     - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.

     - Remove
       <key>NSExtensionMainStoryboard</key>
       <string>MainInterface</string>
     
       and replace it by setting the NSExtensionPrincipalClass to this class, e.g.
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
     
     - Implement providePreview(for:)
     */
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
    
        //You can create a QLPreviewReply in several ways, depending on the format of the data you want to return.
        //To return Data of a supported content type:
        
        let contentType = UTType.propertyList // replace with your data type
        
        let reply = QLPreviewReply.init(dataOfContentType: contentType, contentSize: CGSize.init(width: 800, height: 800)) { (replyToUpdate : QLPreviewReply) in
			
			
			let data = try? String(contentsOfFile: request.fileURL.path).data(using: .utf8) ?? "Could not access \(request.fileURL)".data(using: .utf8)
            
            //setting the stringEncoding for text and html data is optional and defaults to String.Encoding.utf8
            replyToUpdate.stringEncoding = .utf8
            
            //initialize your data here
            
            return data!
        }
                
        return reply
    }

}
