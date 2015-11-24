//
//  CDWheelConnectionWindowController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/20/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDWheelConnectionWindowController: NSWindowController, NSWindowRestoration, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        let window: NSWindow = self.window!
        window.restorable = true;
        window.restorationClass = self.dynamicType
        window.delegate = self
        let delegate = NSApp.delegate as! CDAppDelegate
        delegate.connectionWindows.append(window)
    }
    
    static func restoreWindowWithIdentifier(identifier: String, state: NSCoder, completionHandler: (NSWindow?, NSError?) -> Void) {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let controller: CDWheelConnectionWindowController = storyboard.instantiateControllerWithIdentifier("CDWheelConnectionWindowController") as! CDWheelConnectionWindowController
        completionHandler(controller.window, nil)
    }
    
    var connectionViewController: CDWheelConnectionViewController {
        get {
            return self.window?.contentViewController as! CDWheelConnectionViewController
        }
    }
    
    
//    func window(window: NSWindow, willEncodeRestorableState state: NSCoder) {
//        connectionViewController.encodeRestorableStateWithCoder(<#T##coder: NSCoder##NSCoder#>)
//    }
//    
//    func window(window: NSWindow, didDecodeRestorableState state: NSCoder) {
//        <#code#>
//    }
    
    
    func windowWillClose(notification: NSNotification) {
        let delegate = NSApp.delegate as! CDAppDelegate
        if let index = delegate.connectionWindows.indexOf(self.window!) {
            delegate.connectionWindows.removeAtIndex(index)
        }
    }
    

}
