//
//  CDDarkSplitView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/24/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

// I might want to make this split view resizable at some point in the future
class CDNoWidthSplitView: NSSplitView {

    override var wantsUpdateLayer: Bool {
        get {
            return true
        }
    }
    
    override func updateLayer() {
//        super.updateLayer()
    }
    
    override var dividerThickness: CGFloat {
        get {
            return 0
        }
    }

    
}
