//
//  CDTimelineView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 4/9/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa


class CDTimelineView: NSView {
    
    
    
    override var intrinsicContentSize : NSSize {
        get {
            var requestedSize = super.intrinsicContentSize
            // Make sure we fill our children timelines
            for v in self.subviews {
                requestedSize.width = max(v.intrinsicContentSize.width, requestedSize.width);
            }
            
            if let superview = self.superview {
                // Make sure we fill the super
                let superBounds = superview.bounds;
                requestedSize.height = superBounds.size.height;
                // fill the height
                if requestedSize.width < superBounds.size.width {
                    requestedSize.width = superBounds.size.width
                }
            }
            return requestedSize
        }
    }
    
    
}
