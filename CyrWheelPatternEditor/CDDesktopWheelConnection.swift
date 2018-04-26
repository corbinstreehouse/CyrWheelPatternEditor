//
//  CDDesktopWheelConnection.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 4/2/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

extension CDWheelConnection {
    
    func uploadFileFromURL(_ url: URL, filename: String, uploadHandler: @escaping CDWheelConnectionUploadHandler) {
        
        // If it is a cyrwheel file... load it into data..and upload that
        if url.pathExtension == gSequenceEditorExtension {
            do {
                let document = try CDDocument(contentsOf: url, ofType: "public.cyrwheelpattern")
                let data = document.exportToData();
                uploadFileWithData(data, filename: filename, uploadHandler: uploadHandler)
            } catch let error as NSError {
                uploadHandler(0, true, error)
            }
        } else if let dataToWrite = try? Data(contentsOf: url) {
            uploadFileWithData(dataToWrite, filename: filename, uploadHandler: uploadHandler)
        } else {
            let error = NSError(domain: gPatternEditorErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to open the file '\((url as NSURL).filePathURL!)'"])
            uploadHandler(0, true, error)
        }
    }
}

