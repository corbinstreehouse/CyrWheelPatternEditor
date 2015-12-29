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

enum CDBorderedViewEdge : Int {
    
    case Both
    case Left
    case Right
}

class CDBorderedView: NSView {
    
    static let durationResizeWidth: CGFloat = 8
    static let selectionBorderWidth: CGFloat = 2
    static let normalBorderWidth: CGFloat = 1
    
    // Each second will be X points on screen
    static let defaultWidthPerSecond: CGFloat = 50.0
    static let minWidth: CGFloat = 5.0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay
    }

    override var layer: CALayer? {
        didSet {
//            if let layer = self.layer {
//                layer.borderColor = self.borderColor?.CGColor
//                layer.backgroundColor = NSColor.redColor().CGColor; //self.backgroundColor?.CGColor
//                layer.borderWidth = self.borderWidth
//                layer.cornerRadius = self.cornerRadius
//                
//            }
        }
    }
    
    var borderColor: NSColor? = nil {
        willSet(v) {
//            self.layer?.borderColor = self.borderColor?.CGColor
            if (v != borderColor) {
                self.needsDisplay = true;
            }
        }
    }
    var backgroundColor: NSColor? = nil {
        willSet(v) {
//            self.layer?.backgroundColor = self.backgroundColor?.CGColor
            if (v != backgroundColor) {
                self.needsDisplay = true;
            }

        }
    }
    var borderWidth: CGFloat = 0 {
        willSet(v) {
//            self.layer?.borderWidth = self.borderWidth
            if (v != borderWidth) {
                self.needsDisplay = true;
            }

        }
    }
    var cornerRadius: CGFloat = 0 {
        willSet(v) {
//            self.layer?.cornerRadius = self.cornerRadius
            if (v != cornerRadius) {
                self.needsDisplay = true;
            }

        }
    }
    override var wantsUpdateLayer: Bool {
        get {
            return true
        }
    }

    var borderEdge: CDBorderedViewEdge = CDBorderedViewEdge.Both {
        willSet(v) {
            if (v != borderEdge) {
                self.needsDisplay = true
            }
        }
    }
    
    override func updateLayer() {
        if let layer = self.layer {
            if self.borderColor != nil && self.borderWidth > 0 {
                
// TODO: cache these and use the same values...
                
                let centerWidth = CGFloat(8) // probably cus the cornerRadius
                let width: CGFloat = CGFloat(2) * self.borderWidth + centerWidth
                let size = NSSize(width: width, height: width)
                let image = NSImage(size: size, flipped: false, drawingHandler: { (rect: NSRect) -> Bool in
                    let tmpRect = NSInsetRect(rect, self.borderWidth/2.0, self.borderWidth/2.0)
                    if let fillColr = self.backgroundColor {
                        let p = NSBezierPath(roundedRect: tmpRect, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
                        fillColr.set()
                        p.fill()
                    }
                    if let strokeColor = self.borderColor {
                        let p = NSBezierPath(roundedRect: tmpRect, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
                        strokeColor.set()
                        p.lineWidth = self.borderWidth
                        p.stroke()
                    }
                    
                    return true
                })
                layer.contents = image.CGImageForProposedRect(nil, context: nil, hints: nil)
                if self.borderEdge == .Right {
                    layer.contentsRect = CGRect(x: 0.5, y: 0, width: 0.5, height: 1)
                    layer.contentsCenter = CGRect(x: 0, y: 0.5, width: 0, height: 0)
                } else {
                    layer.contentsCenter = CGRect(x: 0.5, y: 0.5, width: 0, height: 0)
                }
                layer.contentsScale = self.window != nil ? self.window!.backingScaleFactor : 1.0
            } else {
                layer.contents = nil
                layer.backgroundColor = self.backgroundColor?.CGColor
            }
//            layer.borderColor = self.borderColor?.CGColor
//            layer.backgroundColor = self.backgroundColor?.CGColor
//            layer.borderWidth = self.borderWidth
//            layer.cornerRadius = self.cornerRadius
        }
    }
}

class CDTimelineItemView: CDBorderedView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonSetup()
    }

    func _commonSetup() {
        self.backgroundColor = NSColor.lightGrayColor()
        self.cornerRadius = 4.0
        self.borderWidth = CDTimelineItemView.normalBorderWidth
    }
    
    func _updateBorderColor() {
        self.borderColor = self.selected && !self.resizing ? NSColor.alternateSelectedControlColor() : NSColor.grayColor();
        self.borderWidth = self.selected || self.resizing ? CDTimelineItemView.selectionBorderWidth : CDTimelineItemView.normalBorderWidth
    }
    
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
                result.size.height = superview.bounds.size.height
            } else {
                result.size.height = 50; // abitrary
            }
            if result.size.width < CDTimelineItemView.minWidth {
                result.size.width = CDTimelineItemView.minWidth
            }
            let alignedRect = self.backingAlignedRect(result, options: NSAlignmentOptions.AlignAllEdgesOutward)
            return alignedRect.size
        }
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
                let frame = _durationHitRect()
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
    
    func _enclosingTimelineView() -> CDTimelineView? {
        var itemView: CDTimelineView? = nil
        var localView: NSView? = self
        while localView != nil {
            itemView = localView as? CDTimelineView
            if itemView != nil {
                break;
            }
            localView = localView!.superview
        }
        return itemView
    }
    
    func _durationHitRect() -> NSRect {
        var bounds = self.bounds;
        bounds.origin.x = NSMaxX(bounds) - CDTimelineItemView.durationResizeWidth
        bounds.size.width = CDTimelineItemView.durationResizeWidth
        return bounds
    }
    
    var resizing = false {
        didSet {
            self.needsLayout = true
        }
    }
    
    func _trackEventsForResizingFromEvent(theEvent: NSEvent) {
        let tv = self._enclosingTimelineView()!
        tv.assignViewBeingResized(self) // affects selection
        
        self.resizing = true
        let startingPoint = theEvent.locationInWindow
        let startingDuration = timelineItem.duration
        
        self.window?.trackEventsMatchingMask([NSEventMask.LeftMouseDraggedMask, NSEventMask.LeftMouseUpMask], timeout: NSEventDurationForever, mode: NSDefaultRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let currentPoint = event.locationInWindow
            let distanceMoved = currentPoint.x - startingPoint.x
            let newDuration = startingDuration + self._durationForWidth(distanceMoved)
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
            }
        }
        if callSuper {
            super.mouseDown(theEvent)
        }
        
    }
    
    
}
