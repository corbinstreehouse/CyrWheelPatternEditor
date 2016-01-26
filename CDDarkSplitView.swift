//
//  CDDarkSplitView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/24/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDDarkSplitView: NSSplitView {

    override var wantsUpdateLayer: Bool {
        get {
            return true
        }
    }
    
    override func updateLayer() {
        super.updateLayer()
        self.layer!.backgroundColor = NSColor(SRGBRed: 49.0/255.0, green: 49.0/255.0, blue: 49.0/255.0, alpha: 1.0).CGColor
    }
    
    override var dividerThickness: CGFloat {
        get {
            return 0
        }
    }

    
}
