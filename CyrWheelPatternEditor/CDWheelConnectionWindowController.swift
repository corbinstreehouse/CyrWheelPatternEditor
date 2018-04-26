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
        window.isRestorable = true;
        window.restorationClass = type(of: self)
        window.delegate = self
        
        // for the new UI
        window.titleVisibility = NSWindowTitleVisibility.hidden
        window.titlebarAppearsTransparent = true
        
        let delegate = CDAppDelegate.appDelegate
        delegate.connectionWindowControllers.append(self)
    }
    
    static func restoreWindow(withIdentifier identifier: String, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        let controller: CDWheelConnectionWindowController = storyboard.instantiateController(withIdentifier: "CDWheelConnectionWindowController") as! CDWheelConnectionWindowController
        completionHandler(controller.window, nil)
    }
    
    var connectionViewController: CDWheelConnectionViewController {
        get {
            return self.window?.contentViewController as! CDWheelConnectionViewController
        }
    }
    
    func window(_ window: NSWindow, willPositionSheet sheet: NSWindow, using rect: NSRect) -> NSRect {
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
    
    
    func windowWillClose(_ notification: Notification) {
        let delegate = CDAppDelegate.appDelegate
        if let index = delegate.connectionWindowControllers.index(of: self) {
            delegate.connectionWindowControllers.remove(at: index)
        }
    }
    

}
