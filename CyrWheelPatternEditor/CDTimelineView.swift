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
    
    
    var widthPerMS: CGFloat = CDTimelineItemView.defaultWidthPerSecond / 1000.0 {
        didSet {
            _removeAllTimeViews()
            self.needsLayout = true
        }
    }
    var startingOffset: CGFloat = 4.0; // TODO: use a shared constant or something...
    
    override func setFrameSize(newSize: NSSize) {
        super.setFrameSize(newSize)
        self.needsLayout = true;
    }
    
    private var _timeViews: [NSTextField] = []
    
    func _removeAllTimeViews() {
        for view in _timeViews {
            view.removeFromSuperview()
        }
        _timeViews = []
    }
    
    func _updateTimeViews() {
        
    }
    
    override func layout() {
        super.layout()
        _updateTimeViews()
    }
    
    
    
}
