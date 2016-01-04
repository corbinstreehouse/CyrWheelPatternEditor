//
//  CDTimelineview.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/25/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

@objc // temporary....maybe, I am going to use KVO on it too
protocol CDTimelineItem: NSObjectProtocol {
    var duration : NSTimeInterval { get set }
}

@objc // Needed (I forget why)
protocol CDTimelineViewDataSource : NSObjectProtocol {
    // complete reload or new values
    func numberOfItemsInTimelineView(timelineView: CDTimelineView) -> Int
    func timelineView(timelineView: CDTimelineView, itemAtIndex: Int) -> CDTimelineItem
    optional func timelineView(timelineView: CDTimelineView, makeViewControllerAtIndex: Int) -> NSViewController
}

let CDTimelineNoIndex: Int = -1

let TOP_SPACING: CGFloat = 10.0
let BOTTOM_SPACING: CGFloat = 10.0
let TIMELINE_ITEM_FILL_COLOR = NSColor(SRGBRed: 49.0/255.0, green: 49.0/255.0, blue: 49.0/255.0, alpha: 1.0)
// the border color
let CDTimelineItemBorderColor = NSColor(SRGBRed: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)

// also see:
//static let durationResizeWidth: CGFloat = 5
//static let selectionBorderWidth: CGFloat = 2
//static let normalBorderWidth: CGFloat = 1


extension NSEvent {
    var character: Int {
        let str = charactersIgnoringModifiers!.utf16
        return Int(str[str.startIndex])
    }
}

class CDTimelineView: NSStackView {

    func _commonInit() {
        self.wantsLayer = true;
        self.orientation = .Horizontal
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay

        self.setClippingResistancePriority(NSLayoutPriorityRequired, forOrientation: NSLayoutConstraintOrientation.Horizontal)
        self.setClippingResistancePriority(NSLayoutPriorityRequired, forOrientation: NSLayoutConstraintOrientation.Vertical)
        self.setHuggingPriority(NSLayoutPriorityDefaultLow - 0.00001, forOrientation: NSLayoutConstraintOrientation.Horizontal)
        self.setHuggingPriority(NSLayoutPriorityDefaultLow - 0.00001, forOrientation: NSLayoutConstraintOrientation.Vertical)
        // stack view properties
        self.spacing = 0;
        self.edgeInsets = NSEdgeInsetsMake(TOP_SPACING, 0, BOTTOM_SPACING, 0)
        
        self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
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
    func _doWorkToChangeSelection(work: () -> Void) {
        self.willChangeValueForKey("selectionIndexes")
        work()
        self.didChangeValueForKey("selectionIndexes")
        
    }
    
    func _removeAllTimelineItemViews() {
        for view in self.views {
            self.removeView(view)
        }
        _viewBeingResized = nil;
        _timelineItemViewControllers.removeAllObjects()
        
        _anchorRow = nil
        _doWorkToChangeSelection({
            self._selectionIndexes = NSIndexSet()
        })
        
    }
    
    func _delegateTimelineViewControllerAtIndex(index: Int) -> NSViewController {
        if let result = dataSource?.timelineView?(self, makeViewControllerAtIndex: index) {
            return result
        } else {
            let vc = NSViewController()
            vc.view = CDTimelineItemView(frame: frame)
            return vc
        }
    }
    
    var _timelineItemViewControllers = NSMutableArray()
    
    func _makeTimelineItemViewAtIndex(index: Int, frame: NSRect, timelineItem: CDTimelineItem) -> CDTimelineItemView {
        let vc: NSViewController = _delegateTimelineViewControllerAtIndex(index)
        _timelineItemViewControllers.insertObject(vc, atIndex: index)
        let result = vc.view as! CDTimelineItemView
        result.timelineItem = timelineItem
        return result
    }
    
    func _defaultItemViewFrame() -> NSRect {
        return NSRect(x: 0, y: 0, width: 100, height: self.frame.height)
    }
    
    func _updateIfNeeded() {
        if !_needsUpdate {
            return;
        }
        _needsUpdate = false
        let itemFrame = _defaultItemViewFrame()
        for var i = 0; i < self.numberOfItems; i++ {
            let timelineItem = self.dataSource!.timelineView(self, itemAtIndex: i)
            let itemView = _makeTimelineItemViewAtIndex(i, frame: itemFrame, timelineItem: timelineItem)
            self.addView(itemView, inGravity: NSStackViewGravity.Leading)
        }
    }
    
    func insertItemAtIndex(index: Int) {
        let timelineItem = self.dataSource!.timelineView(self, itemAtIndex: index)
        let itemFrame = _defaultItemViewFrame()
        let itemView = _makeTimelineItemViewAtIndex(index, frame: itemFrame, timelineItem: timelineItem)
        self.insertView(itemView, atIndex: index, inGravity: NSStackViewGravity.Leading)
        
        _shiftSelectionFromIndex(index)
    }
    
    func _shiftSelectionFromIndex(index: Int) {
        _doWorkToChangeSelection() {
            if let anchorRow = self._anchorRow {
                if anchorRow >= index {
                    self._anchorRow = anchorRow + 1
                }
            }
            
            let mutableIndexes = NSMutableIndexSet(indexSet: self._selectionIndexes)
            mutableIndexes.shiftIndexesStartingAtIndex(index, by: 1)
            self._selectionIndexes = mutableIndexes;
        }
    }
    
    
    func _removeIndexFromSelection(index: Int) {
        // Don't go through the "setter"
        _doWorkToChangeSelection() {
            let mutableIndexes = NSMutableIndexSet(indexSet: self._selectionIndexes)
            mutableIndexes.removeIndex(index)
            self._selectionIndexes = mutableIndexes;
            
            if self._anchorRow == index {
                if self._selectionIndexes.count > 0 {
                    self._anchorRow = self._selectionIndexes.firstIndex
                } else {
                    self._anchorRow = nil
                }
            }
        }
    }
    
    func removeItemAtIndex(index: Int) {
        let view = self.views[index]
        self.removeView(view)
        _timelineItemViewControllers.removeObjectAtIndex(index)
        _removeIndexFromSelection(index)
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
                // All our vies also depend on our size (for now!)
//                for view in self.views {
//                    view.invalidateIntrinsicContentSize()
//                }
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

    func scrollItemAtIndexToVisible(index: Int) {
        self.layoutSubtreeIfNeeded()
        let viewToShow = self.views[index]
        viewToShow.scrollRectToVisible(viewToShow.bounds)
//        self.enclosingScrollView?.scrollRectToVisible(viewToShow.frame)
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
    
    func _resetAnchorRow() {
        if self.selectionIndexes.count > 0 {
            _anchorRow = self.selectionIndexes.firstIndex
        } else {
            _anchorRow = nil;
        }
    }
    
    func _updateSelectionState(priorSelectedIndexes: NSIndexSet, newSelectedRows: NSIndexSet) {
        // easiest implementation for now
        priorSelectedIndexes.enumerateIndexesUsingBlock({ (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let itemView = self.views[index] as! CDTimelineItemView
            itemView.selected = false
        })
        
        newSelectedRows.enumerateIndexesUsingBlock({ (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let itemView = self.views[index] as! CDTimelineItemView
            itemView.selected = true
        })
    }
    
    func assignViewBeingResized(newView: CDTimelineItemView?) {
        if let oldView = self._viewBeingResized {
            if oldView != newView {
                oldView.resizing = false;
            }
        }
        
        self._viewBeingResized = newView;
        
        
        if newView != nil {
            if let itemIndex = self.views.indexOf(newView!) {
                // drop selection to just this item
                self.selectionIndexes = NSIndexSet(index: itemIndex)
            }
        }
        
    }
    
    // when non-nil, we can't extend selection, etc.
    private weak var _viewBeingResized: CDTimelineItemView?
    
    var _shouldUpdateAnchorRow = true
    var _selectionIndexes: NSIndexSet = NSIndexSet()
    dynamic var selectionIndexes: NSIndexSet {
        set(v) {
            if (!_selectionIndexes.isEqualToIndexSet(v)) {
                let priorSelectedIndexes = _selectionIndexes.mutableCopy() as! NSMutableIndexSet
                priorSelectedIndexes.removeIndexes(v)
                
                _selectionIndexes = v

                // Keep the anchor row valid..
                if _shouldUpdateAnchorRow {
                    _resetAnchorRow()
                }
                _updateSelectionState(priorSelectedIndexes, newSelectedRows: v);
                
                // Don't allow a duration selection when this is selected..
                if v.count != 0 {
                    assignViewBeingResized(nil)
                }
            }
        }
        get {
            return _selectionIndexes;
        }
    }
    
    func indexOfView(view: NSView?) -> Int? {
        var itemView: CDTimelineItemView? = nil
        var localView: NSView? = view
        while localView != nil {
            itemView = localView as? CDTimelineItemView
            if itemView != nil {
                break;
            }
            localView = localView!.superview
        }
        
        if let v = itemView {
            return self.views.indexOf(v)
        } else {
            return nil
        }

    }

    // selection is based off this row
    var _anchorRow: Int?

    // return the last hit
    func processMouseEvent(theEvent: NSEvent) {
        if theEvent.type != .LeftMouseDown {
            return
        }
        
        let hitLocation = theEvent.locationInView(self)
        let hitView = self.hitTest(hitLocation)
        let hitIndex = self.indexOfView(hitView)
        let newSelectedRows = NSMutableIndexSet()
        var newAnchorRow: Int? = nil
        
        if let hitIndex = hitIndex {
            if let currentAnchorIndex = _anchorRow {
                // If we did hit something, then select from the anchor to it, if extending the selection
                let shiftIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask);
                let cmdIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.CommandKeyMask);
                if (_viewBeingResized != nil && (cmdIsDown || shiftIsDown)) {
                    // We can't process it; it conflicts with the duration selection
                    newAnchorRow = _anchorRow
                    newSelectedRows.addIndexes(self.selectionIndexes)
                    NSBeep();
                } else if (shiftIsDown) {
                    // anchor row direct to the new hit row
                    let firstIndex = min(hitIndex, currentAnchorIndex)
                    let lastIndex = max(hitIndex, currentAnchorIndex)
                    let length = lastIndex - firstIndex + 1
                    newAnchorRow = currentAnchorIndex
                    newSelectedRows.addIndexesInRange(NSRange(location: firstIndex, length: length))
                } else if (cmdIsDown) {
                    // toggle behavior
                    newAnchorRow = currentAnchorIndex
                    newSelectedRows.addIndexes(self.selectionIndexes)
                    if (newSelectedRows.contains(hitIndex)) {
                        newSelectedRows.removeIndex(hitIndex)
                    } else {
                        newSelectedRows.addIndex(hitIndex)
                    }
                } else {
                    // basic selection changing the anchor
                    newAnchorRow = hitIndex
                    newSelectedRows.addIndex(hitIndex)
                }
            } else {
                // no anchor, new selection
                newAnchorRow = hitIndex
                newSelectedRows.addIndex(hitIndex)
            }
        }

        _anchorRow = newAnchorRow
        self.selectionIndexes = newSelectedRows
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if self.acceptsFirstResponder {
            self.window?.makeFirstResponder(self)
        }
        
        _shouldUpdateAnchorRow = false
        
//        var lastHitIndex = processMouseEvent(theEvent, lastHitIndex: nil)
        
        self.window?.trackEventsMatchingMask([NSEventMask.LeftMouseDraggedMask, NSEventMask.LeftMouseUpMask], timeout: NSEventDurationForever, mode: NSDefaultRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
        
            self.processMouseEvent(theEvent)
            if event.type == .LeftMouseUp {
                stop.memory = true
            }
        })
        _shouldUpdateAnchorRow = true
    }
    
    func _keepIndexValid(index: Int) -> Int {
        var result = index
        if (result < 0) {
            result = 0;
        } else if (result >= self.numberOfItems) {
            result = self.numberOfItems - 1;
        }
        return result
    }
    
    func _selectNextIndexFromAnchorExtending(extendingSelection: Bool, goingForward: Bool) {
        _shouldUpdateAnchorRow = false
        
        let itemCount = self.numberOfItems;
        if let anchorIndex = _anchorRow {
            if extendingSelection {
                var firstIndex = self.selectionIndexes.firstIndex
                var endingIndex = self.selectionIndexes.lastIndex
                if anchorIndex == firstIndex {
                    // From the anchor to somewhere past it
                    if goingForward {
                        endingIndex++
                    } else if firstIndex == endingIndex {
                        // Dec the first index instead of the ending
                        firstIndex--
                    } else {
                        endingIndex--
                    }
                } else {
                    // expand at the start of the selection
                    if goingForward {
                        firstIndex++
                    } else {
                        firstIndex--
                    }
                }
                
                firstIndex = _keepIndexValid(firstIndex)
                endingIndex = _keepIndexValid(endingIndex)
                let length = endingIndex - firstIndex + 1
                // Leave the anchor row where it is
                self.selectionIndexes = NSIndexSet(indexesInRange: NSRange(location: firstIndex, length: length))
            } else {
                var nextIndex = goingForward ? anchorIndex + 1 : anchorIndex - 1;
                nextIndex = _keepIndexValid(nextIndex)
                _anchorRow = nextIndex
                self.selectionIndexes = NSIndexSet(index: nextIndex);
            }
            
        } else if itemCount > 0 {
            _anchorRow = goingForward ? 0 : itemCount - 1
            self.selectionIndexes = NSIndexSet(index: _anchorRow!)
        }
        _shouldUpdateAnchorRow = true
    }
    
    override func keyDown(theEvent: NSEvent) {
        var callSuper = false
        let shiftIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask);

        switch theEvent.character {
        case NSRightArrowFunctionKey:
            _selectNextIndexFromAnchorExtending(shiftIsDown, goingForward: true)
        case NSLeftArrowFunctionKey:
            _selectNextIndexFromAnchorExtending(shiftIsDown, goingForward: false)
        default:
            callSuper = true;
        }
        
        if callSuper {
            super.keyDown(theEvent)
        }
    }
    
    override var acceptsFirstResponder: Bool  {
        get {
            return true;
        }
    }
    
//    override func hitTest(aPoint: NSPoint) -> NSView? {
//        var hitView = super.hitTest(aPoint);
//        // push hits on the left edge of the non-0 view to to the prior one to resize it..
//        if let reallyHitView = hitView as? CDTimelineItemView {
//            if let index = self.views.indexOf(reallyHitView) {
//                if index > 0 {
//                    // did we hit the left of it?
//                    let resizeLeftRect = self.convertRect(reallyHitView.leftSideResizeRect(), fromView: reallyHitView)
//                    if NSPointInRect(aPoint, resizeLeftRect) {
//                        // REturn the view to our left.
//                        hitView = self.views[index - 1]
//                    }
//                }
//            }
//        }
//        return hitView;
//    }
    

}

