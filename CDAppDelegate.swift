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

    // This ensures they are around
    internal lazy var connectionWindowControllers: [NSWindowController] = []
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        
        
    }
    
    
//    @IBAction func mnuNewWheelConnectionClicked(sender: AnyObject) {
//        let contentViewController: CDWheelConnectionViewController = CDWheelConnectionViewController();
//        let window: NSWindow = NSWindow(contentViewController: contentViewController)
//        m_connectionWindows.addObject(window)
//    }
//    
    
}
