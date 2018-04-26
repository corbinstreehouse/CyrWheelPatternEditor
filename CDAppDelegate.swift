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
    
    internal var patternDirectoryURL: URL {
        let fileManager = FileManager.default
        let appSupportDir: URL = try! fileManager.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true);
        let editorSupportDir = appSupportDir.appendingPathComponent("CyrWheelPatternEditor", isDirectory: true)
        let patternDir = editorSupportDir.appendingPathComponent("Patterns", isDirectory: true)
        return patternDir
    }
    
    fileprivate func _getDefaultPatternDirectory() -> URL {
        let bundle = Bundle.main
        let url = bundle.url(forResource: "Patterns", withExtension: "framework")
        return url!
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Make sure our patterns are copied ot the user directory before we finish launching
        let patternDir = patternDirectoryURL
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: patternDir.path) {
                // create the base dir, and copy
                let appSupportDir: URL = try! fileManager.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true);
                let editorSupportDir = appSupportDir.appendingPathComponent("CyrWheelPatternEditor", isDirectory: true)
                if !fileManager.fileExists(atPath: editorSupportDir.path) {
                    try fileManager.createDirectory(at: editorSupportDir, withIntermediateDirectories: true, attributes: [:])
                }

                // Copy the default patterns to it..
                try fileManager.copyItem(at: _getDefaultPatternDirectory(), to: patternDir)
            }
        } catch {
            // TODO...handle this..
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        
    }
    
    lazy var mainStoryboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
    
//    @IBAction func mnuNewWheelConnectionClicked(sender: AnyObject) {
//        let contentViewController: CDWheelConnectionViewController = CDWheelConnectionViewController();
//        let window: NSWindow = NSWindow(contentViewController: contentViewController)
//        m_connectionWindows.addObject(window)
//    }
//    
    
}
