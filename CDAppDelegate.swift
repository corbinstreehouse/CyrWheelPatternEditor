//
//  CDAppDelegate.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/19/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

@NSApplicationMain
class CDAppDelegate: NSObject, NSApplicationDelegate {

    static var appDelegate: CDAppDelegate {
        return NSApp.delegate as! CDAppDelegate
    }
    // This ensures they are around
    internal lazy var connectionWindowControllers: [NSWindowController] = []
    
    internal var patternDirectoryURL: NSURL {
        let fileManager = NSFileManager.defaultManager()
        let appSupportDir: NSURL = try! fileManager.URLForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: true);
        let editorSupportDir = appSupportDir.URLByAppendingPathComponent("CyrWheelPatternEditor", isDirectory: true)
        let patternDir = editorSupportDir.URLByAppendingPathComponent("Patterns", isDirectory: true)
        return patternDir
    }
    
    private func _getDefaultPatternDirectory() -> NSURL {
        let bundle = NSBundle.mainBundle()
        let url = bundle.URLForResource("Patterns", withExtension: "framework")
        return url!
    }
    
    func applicationWillFinishLaunching(notification: NSNotification) {
        // Make sure our patterns are copied ot the user directory before we finish launching
        let patternDir = patternDirectoryURL
        do {
            let fileManager = NSFileManager.defaultManager()
            if !fileManager.fileExistsAtPath(patternDir.path!) {
                // create the base dir, and copy
                let appSupportDir: NSURL = try! fileManager.URLForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: true);
                let editorSupportDir = appSupportDir.URLByAppendingPathComponent("CyrWheelPatternEditor", isDirectory: true)
                if !fileManager.fileExistsAtPath(editorSupportDir.path!) {
                    try fileManager.createDirectoryAtURL(editorSupportDir, withIntermediateDirectories: true, attributes: [:])
                }

                // Copy the default patterns to it..
                try fileManager.copyItemAtURL(_getDefaultPatternDirectory(), toURL: patternDir)
            }
        } catch {
            // TODO...handle this..
            
        }
        
    }

    func applicationDidFinishLaunching(notification: NSNotification) {
        
        
    }
    
    lazy var mainStoryboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
    
    
    
//    @IBAction func mnuNewWheelConnectionClicked(sender: AnyObject) {
//        let contentViewController: CDWheelConnectionViewController = CDWheelConnectionViewController();
//        let window: NSWindow = NSWindow(contentViewController: contentViewController)
//        m_connectionWindows.addObject(window)
//    }
//    
    
}
