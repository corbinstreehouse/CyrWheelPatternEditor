//
//  CDTimelineview.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/25/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

@objc // temporary..
protocol CDTimelineItem {
    var duration : NSTimeInterval { get }
}

@objc // cuz I use it there for testing (For now)
protocol CDTimelineViewDataSource : NSObjectProtocol {
    // complete reload or new values
    func numberOfItemsInTimelineView(timelineView: CDTimelineView) -> Int
    func timelineView(timelineView: CDTimelineView, itemAtIndex: Int) -> CDTimelineItem
}

class CDTimelineView: NSStackView {

    func _commonInit() {
        self.wantsLayer = true;
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay
        
        // stack view properties
        self.spacing = 0;
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonInit();
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit();
    }
    
    var dataSource: CDTimelineViewDataSource? {
        didSet {
            reloadData();
        }
    }
    
    var numberOfItems: Int {
        get {
            if let d = self.dataSource {
                return d.numberOfItemsInTimelineView(self)
            } else {
                return 0;
            }
        }
    }
    
    var _needsUpdate: Bool = false
    
    func reloadData() {
        self.needsLayout = true;
        _needsUpdate = true
        _removeAllTimelineItemViews()
        
    }
    
    // MARK: private stuff
    
    func _removeAllTimelineItemViews() {
        for view in self.views {
            self.removeView(view)
        }
    }
    
    func _makeTimelineItemViewWithFrame(frame: NSRect, timelineItem: CDTimelineItem) -> CDTimelineItemView {
        let result = CDTimelineItemView(frame: frame)
        result.timelineItem = timelineItem
        return result
    }
    
    func _updateIfNeeded() {
        if !_needsUpdate {
            return;
        }
        _needsUpdate = false
        let itemFrame = NSRect(x: 0, y: 0, width: 100, height: self.frame.height)
        for var i = 0; i < self.numberOfItems; i++ {
            let timelineItem = self.dataSource!.timelineView(self, itemAtIndex: i)
            let itemView = _makeTimelineItemViewWithFrame(itemFrame, timelineItem: timelineItem)
            self.addView(itemView, inGravity: NSStackViewGravity.Leading)
        }
    }
    
    override func viewWillMoveToSuperview(newSuperview: NSView?) {
        if let oldsuper = self.superview {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSViewFrameDidChangeNotification, object: oldsuper)
        }
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let newSuper = self.superview {
            // We want to know when the clip view's size changes (via the scrollview) so we can fill the height by changing our intrinsic size that we have
            NSNotificationCenter.defaultCenter().addObserverForName(NSViewFrameDidChangeNotification, object: newSuper, queue: nil, usingBlock: { (note: NSNotification) -> Void in
                self.invalidateIntrinsicContentSize()
            })
        }
    }
    
    override var intrinsicContentSize : NSSize {
        get {
            var requestedSize = super.intrinsicContentSize
            if let superview = self.superview {
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

//    override var frame: NSRect {
//        didSet {
//            NSLog("frame: %@", NSStringFromRect(self.frame));
//            
//        }
//    }
    
    override func layout() {
        _updateIfNeeded()
        super.layout()
    }
    
    override var wantsUpdateLayer: Bool {
        get {
            return true;
        }
    }
    
    override func updateLayer() {
//        guard let layer = self.layer else {
//            return;
//        }
//        layer.backgroundColor = NSColor.clearColor();
//        layer.borderColor = NSColor.grayColor().CGColor
//        layer.borderWidth = 2.0
    }
    

}
