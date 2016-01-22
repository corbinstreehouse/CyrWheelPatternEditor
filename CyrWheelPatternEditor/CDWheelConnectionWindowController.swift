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
        
        // for the new UI
        window.titleVisibility = NSWindowTitleVisibility.Hidden
        window.titlebarAppearsTransparent = true
        
        let delegate = CDAppDelegate.appDelegate
        delegate.connectionWindowControllers.append(self)
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
    
    func window(window: NSWindow, willPositionSheet sheet: NSWindow, usingRect rect: NSRect) -> NSRect {
        // drop it down
        var result = rect;
        result.origin.y -= 36
        return result
    }

    
//    func window(window: NSWindow, willEncodeRestorableState state: NSCoder) {
//        connectionViewController.encodeRestorableStateWithCoder(<#T##coder: NSCoder##NSCoder#>)
//    }
//    
//    func window(window: NSWindow, didDecodeRestorableState state: NSCoder) {
//        <#code#>
//    }
    
    
    func windowWillClose(notification: NSNotification) {
        let delegate = CDAppDelegate.appDelegate
        if let index = delegate.connectionWindowControllers.indexOf(self) {
            delegate.connectionWindowControllers.removeAtIndex(index)
        }
    }
    

}
