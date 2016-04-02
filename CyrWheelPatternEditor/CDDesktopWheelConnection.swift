//
//  CDDesktopWheelConnection.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 4/2/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

extension CDWheelConnection {

    func presentError(error: NSError) {
        NSApp.presentError(error)
    }
    
    func uploadFile(url: NSURL, filename: String) {
        
        // If it is a cyrwheel file... load it into data..and upload that
        if url.pathExtension != "pat" {
            do {
                let document = try CDDocument(contentsOfURL: url, ofType: "public.cyrwheelpattern")
                let data = document.exportToData();
                writeNewSequenceFileWithData(data, filename: filename)
            } catch let error as NSError {
                presentError(error);
            }
        } else if let dataToWrite = NSData(contentsOfURL: url) {
            writeNewSequenceFileWithData(dataToWrite, filename: filename)
        } else {
            // error can't open file...
            NSLog("can't open URL for writing: %@", url);
        }
    }
}

