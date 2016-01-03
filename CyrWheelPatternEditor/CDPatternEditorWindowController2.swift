//
//  CDPatternEditorWindowController2.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/29/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternEditorWindowController2: NSWindowController, CDPatternSequenceProvider {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        let window = self.window!
        window.backgroundColor = NSColor(SRGBRed: 41.0/255.0, green: 41.0/255.0, blue: 41.0/255.0, alpha: 1.0)
//        window.titleVisibility = NSWindowTitleVisibility.Hidden
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        window.contentView!.appearance = NSAppearance(named: NSAppearanceNameAqua)
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

    
    var patternSequence: CDPatternSequence! {
        get {
            return self.document!.patternSequence;
        }
    }

    
}
