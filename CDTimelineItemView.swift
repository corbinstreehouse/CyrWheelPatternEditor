//
//  CDTimelineItemView.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/25/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDTimelineItemView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var timelineItem: CDTimelineItem! {
        didSet {
            let obj: NSObject = self.timelineItem as! NSObject
            obj.addObserver(self, forKeyPath: "duration", options: [], context: nil)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    var selected: Bool = false {
        didSet {
            self.needsDisplay = true
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "duration" {
            self.invalidateIntrinsicContentSize();
        }
    }

    // Each second will be X points on screen
    static let defaultWidthPerSecond: CGFloat = 50.0
    
    override var intrinsicContentSize: NSSize {
        get {
            var result: NSRect = NSRect(origin: NSZeroPoint, size: super.intrinsicContentSize)
            result.size.width = CGFloat(timelineItem.duration) * CDTimelineItemView.defaultWidthPerSecond
            if let superview = self.superview {
                result.size.height = superview.bounds.size.height
            } else {
                result.size.height = 50; // abitrary
            }
            let alignedRect = self.backingAlignedRect(result, options: NSAlignmentOptions.AlignAllEdgesOutward)
            return alignedRect.size
        }
    }
        
    override var wantsUpdateLayer: Bool {
        get {
            return true;
        }
    }
    
    override func updateLayer() {
        guard let layer = self.layer else {
            return;
        }
        let borderColor = self.selected ? NSColor.alternateSelectedControlColor() : NSColor.grayColor();
        layer.borderColor = borderColor.CGColor
        layer.backgroundColor = NSColor.lightGrayColor().CGColor
        layer.cornerRadius = 4.0;
        layer.borderWidth = 2.0
    }
    
    
    
}
