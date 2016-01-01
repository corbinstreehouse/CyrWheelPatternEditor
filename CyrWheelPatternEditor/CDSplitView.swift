//
//  CDSplitView.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/31/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDSplitView: NSSplitView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override var fittingSize: NSSize {
        get {
            return self.frame.size // don't change our size set in the nib
        }
    }
    
}
