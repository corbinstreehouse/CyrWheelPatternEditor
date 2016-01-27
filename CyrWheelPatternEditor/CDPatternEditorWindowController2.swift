//
//  CDPatternEditorWindowController2.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/29/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternEditorWindowController2: NSWindowController, CDPatternSequenceProvider, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        let window = self.window!
        // TODO: better color management..
        // Agh..the dark appearance makes this not work! this line is basically pointless
        window.backgroundColor = NSColor(SRGBRed: 49.0/255.0, green: 49.0/255.0, blue: 49.0/255.0, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        // I don't want the content to use "vibrant" controls except in particular UI pieces, so I set the appearance to vibrantDark on specific UI view parents
        window.contentView!.appearance = NSAppearance(named: NSAppearanceNameAqua)
        window.delegate = self
        _documentChanged();
    }
    
    private func _documentChanged() {
        if self.document != nil {
            var mainVC = self.window!.contentViewController as! CDPatternSequencePresenter;
            mainVC.patternSequence = self.patternSequence
        }
    }
    
    override var document: AnyObject? {
        didSet {
            _documentChanged()
        }
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return self.document!.managedObjectContext
    }
    
    var patternSequence: CDPatternSequence! {
        get {
            return self.document!.patternSequence;
        }
    }

    // Bound to a child's value, so that another view can be bound to this one
    dynamic var patternSelectionIndexes: NSIndexSet = NSIndexSet()

    
    func window(window: NSWindow, willPositionSheet sheet: NSWindow, usingRect rect: NSRect) -> NSRect {
        // drop it down
        var result = rect;
        result.origin.y -= 23
        return result
    }

    
}
