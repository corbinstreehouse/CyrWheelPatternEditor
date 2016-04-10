//
//  CDTimelineItemView.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/25/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

extension NSEvent {
    func locationInView(view: NSView) -> NSPoint {
        return view.convertPoint(self.locationInWindow, fromView: nil)
    }
}

class CDTimelineItemView: CDBorderedView {
    // TODO: better way of dealing with UI constants/appearance for the view..
    static let itemBorderColor = NSColor(SRGBRed: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
    static let itemSelectedBorderColor = NSColor.alternateSelectedControlColor()
    static let itemFillColor = NSColor(SRGBRed: 49.0/255.0, green: 49.0/255.0, blue: 49.0/255.0, alpha: 1.0)
    static let durationResizeWidth: CGFloat = 5
    static let selectionBorderWidth: CGFloat = 2
    static let normalBorderWidth: CGFloat = 1
    
    static let minWidth: CGFloat = 5.0
    static let cornerRadius: CGFloat = 4.0
    
    // Each second will be X points on screen
    static let defaultWidthPerSecond: CGFloat = 50.0
    

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonSetup()
    }

    func _commonSetup() {
        self.backgroundColor = CDTimelineItemView.itemFillColor
        self.cornerRadius = CDTimelineItemView.cornerRadius
        self.borderWidth = CDTimelineItemView.normalBorderWidth
    }
    
    func _updateBorderColor() {
        self.borderColor = self.selected /*&& !self.resizing*/ ? CDTimelineItemView.itemSelectedBorderColor : CDTimelineItemView.itemBorderColor;
        self.borderWidth = self.selected || self.resizing ? CDTimelineItemView.selectionBorderWidth : CDTimelineItemView.normalBorderWidth
    }
    
    // weak??
    var timelineItem: CDTimelineItem! {
        didSet {
            let obj: NSObject = self.timelineItem as! NSObject
            obj.addObserver(self, forKeyPath: "duration", options: [], context: nil)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    deinit {
        let obj: NSObject = self.timelineItem as! NSObject
        obj.removeObserver(self, forKeyPath: "duration")
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

    private func _widthForDuration(duration: NSTimeInterval) -> CGFloat {
        return CGFloat(duration) * CDTimelineItemView.defaultWidthPerSecond
    }
    
    private func _durationForWidth(width: CGFloat) -> NSTimeInterval {
        return NSTimeInterval(width / CDTimelineItemView.defaultWidthPerSecond)
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            var result: NSRect = NSRect(origin: NSZeroPoint, size: super.intrinsicContentSize)
            result.size.width = _widthForDuration(timelineItem.duration)
            if let superview = self.superview {
                result.size.height = superview.bounds.size.height - TOP_SPACING - BOTTOM_SPACING
            } else {
                result.size.height = 50; // abitrary until we have a super..
            }
            if result.size.width < CDTimelineItemView.minWidth {
                result.size.width = CDTimelineItemView.minWidth
            }
            let alignedRect = self.backingAlignedRect(result, options: NSAlignmentOptions.AlignAllEdgesOutward)
            return alignedRect.size
        }
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.invalidateIntrinsicContentSize() // Because it is based on our superview
    }
        
//    override var wantsUpdateLayer: Bool {
//        get {
//            return true;
//        }
//    }
    
    private var _resizingView: CDBorderedView?
    
    override func updateLayer() {
        _updateBorderColor()
        super.updateLayer()
    }
    
    override func layout() {
        if self.resizing  {
            if _resizingView == nil {
                let frame = _resizeDrawingRect()
                let v = CDBorderedView(frame: frame)
                v.cornerRadius = self.cornerRadius
                v.borderWidth = CDTimelineItemView.selectionBorderWidth
                v.borderColor = NSColor.yellowColor()
                v.translatesAutoresizingMaskIntoConstraints = true
                v.autoresizingMask = [NSAutoresizingMaskOptions.ViewMinXMargin, .ViewHeightSizable];
                v.borderEdge = .Right
                self.addSubview(v)
                _resizingView = v
                
            }
        } else {
            if let r = _resizingView {
                r.removeFromSuperview()
                _resizingView = nil
            }
        }
        super.layout()
    }
    
    private func _enclosingTimelineTrackView() -> CDTimelineTrackView? {
        var itemView: CDTimelineTrackView? = nil
        var localView: NSView? = self
        while localView != nil {
            itemView = localView as? CDTimelineTrackView
            if itemView != nil {
                break;
            }
            localView = localView!.superview
        }
        return itemView
    }

    private func _leftSideResizeRect() -> NSRect {
        var bounds = self.bounds;
        bounds.size.width = CDTimelineItemView.durationResizeWidth;
        return bounds
    }
    
    private func _resizeDrawingRect() -> NSRect {
        var bounds = self.bounds;
        bounds.origin.x = NSMaxX(bounds) - CDTimelineItemView.durationResizeWidth
        bounds.size.width = CDTimelineItemView.durationResizeWidth;
        return bounds
    }

    private func _durationHitRect() -> NSRect {
        var bounds = _resizeDrawingRect();
        bounds.size.width *= 2.0 // goes into the other view's area
        return bounds
    }
    
    var resizing = false {
        didSet {
            self.needsLayout = true
            self.needsDisplay = true
        }
    }
    
    func _trackEventsForResizingFromEvent(theEvent: NSEvent) {
        let tv = self._enclosingTimelineTrackView()!
        tv.assignViewBeingResized(self) // affects selection
        
        self.resizing = true
        let startingPoint = theEvent.locationInWindow
        let startingDuration = timelineItem.duration
        
        self.window?.trackEventsMatchingMask([NSEventMask.LeftMouseDraggedMask, NSEventMask.LeftMouseUpMask], timeout: NSEventDurationForever, mode: NSDefaultRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let currentPoint = event.locationInWindow
            let distanceMoved = currentPoint.x - startingPoint.x
            // cap it at 0...which would be an instantaenous flip...
            let newDuration = max(startingDuration + self._durationForWidth(distanceMoved), 0)
            
            if self.timelineItem.duration != newDuration {
                self.timelineItem.duration = newDuration
                self.invalidateIntrinsicContentSize()
            }
            
            if event.type == .LeftMouseUp {
                stop.memory = true
            }
        })
        
    }
    
    override func mouseDown(theEvent: NSEvent) {
        var callSuper = true;
        // Go into resize mode if clicking on the right edge w/no modifiers
        let shiftIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask);
        let cmdIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.CommandKeyMask);
        if (!cmdIsDown && !shiftIsDown) {
            let hitBounds = _durationHitRect()
            let hitPoint =  theEvent.locationInView(self)
            if NSPointInRect(hitPoint, hitBounds) {
                _trackEventsForResizingFromEvent(theEvent)
                callSuper = false
            } else if NSPointInRect(hitPoint, _leftSideResizeRect()) {
                // forward to our left sibling (if any)
                if let enclosingView = self._enclosingTimelineTrackView() {
                    if let index = enclosingView.indexOfView(self) {
                        if index > 0 {
                            let sibling = enclosingView.views[index - 1]
                            sibling.mouseDown(theEvent)
                            callSuper = false
                        }
                    }
                }
                
            }
        }
        if callSuper {
            super.mouseDown(theEvent)
        }
        
    }
    
    
}
