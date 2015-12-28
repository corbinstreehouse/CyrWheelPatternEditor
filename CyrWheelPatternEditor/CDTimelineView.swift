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
    var duration : NSTimeInterval { get }
}

@objc // cuz I use it there for testing (For now)
protocol CDTimelineViewDataSource : NSObjectProtocol {
    // complete reload or new values
    func numberOfItemsInTimelineView(timelineView: CDTimelineView) -> Int
    func timelineView(timelineView: CDTimelineView, itemAtIndex: Int) -> CDTimelineItem
}

let CDTimelineNoIndex: Int = -1

extension NSEvent {
    var character: Int {
        let str = charactersIgnoringModifiers!.utf16
        return Int(str[str.startIndex])
    }
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
        _viewBeingResized = nil;
        
        _anchorRow = nil
        _selectedIndexes = NSIndexSet()
    }
    
    func _makeTimelineItemViewWithFrame(frame: NSRect, timelineItem: CDTimelineItem) -> CDTimelineItemView {
        let result = CDTimelineItemView(frame: frame)
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
            let itemView = _makeTimelineItemViewWithFrame(itemFrame, timelineItem: timelineItem)
            self.addView(itemView, inGravity: NSStackViewGravity.Leading)
        }
    }
    
    func insertItemAtIndex(index: Int) {
        let timelineItem = self.dataSource!.timelineView(self, itemAtIndex: index)
        let itemFrame = _defaultItemViewFrame()
        let itemView = _makeTimelineItemViewWithFrame(itemFrame, timelineItem: timelineItem)
        self.insertView(itemView, atIndex: index, inGravity: NSStackViewGravity.Leading)
        
        _shiftSelectionFromIndex(index)
    }
    
    func _shiftSelectionFromIndex(index: Int) {
        if let anchorRow = _anchorRow {
            if anchorRow >= index {
                _anchorRow = anchorRow + 1
            }
        }
        
        let mutableIndexes = NSMutableIndexSet(indexSet: _selectedIndexes)
        mutableIndexes.shiftIndexesStartingAtIndex(index, by: 1)
        _selectedIndexes = mutableIndexes;
    }
    
    
    func _removeIndexFromSelection(index: Int) {
        // Don't go through the "setter"
        let mutableIndexes = NSMutableIndexSet(indexSet: _selectedIndexes)
        mutableIndexes.removeIndex(index)
        _selectedIndexes = mutableIndexes;
        
        if _anchorRow == index {
            if _selectedIndexes.count > 0 {
                _anchorRow = _selectedIndexes.firstIndex
            } else {
                _anchorRow = nil
            }
        }
    }
    
    func removeItemAtIndex(index: Int) {
        let view = self.views[index]
        self.removeView(view)
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
        if self.selectedIndexes.count > 0 {
            _anchorRow = self.selectedIndexes.firstIndex
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
            // drop selection
            self.selectedIndexes = NSIndexSet()
        }
        
    }
    
    // when non-nil, we can't extend selection, etc.
    private weak var _viewBeingResized: CDTimelineItemView?
    
    var _shouldUpdateAnchorRow = true
    var _selectedIndexes: NSIndexSet = NSIndexSet()
    var selectedIndexes: NSIndexSet {
        set(v) {
            if (!_selectedIndexes.isEqualToIndexSet(v)) {
                let priorSelectedIndexes = _selectedIndexes.mutableCopy() as! NSMutableIndexSet
                priorSelectedIndexes.removeIndexes(v)
                
                _selectedIndexes = v

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
            return _selectedIndexes;
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
                    newSelectedRows.addIndexes(self.selectedIndexes)
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
                    newSelectedRows.addIndexes(self.selectedIndexes)
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
        self.selectedIndexes = newSelectedRows
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
                var firstIndex = self.selectedIndexes.firstIndex
                var endingIndex = self.selectedIndexes.lastIndex
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
                self.selectedIndexes = NSIndexSet(indexesInRange: NSRange(location: firstIndex, length: length))
            } else {
                var nextIndex = goingForward ? anchorIndex + 1 : anchorIndex - 1;
                nextIndex = _keepIndexValid(nextIndex)
                _anchorRow = nextIndex
                self.selectedIndexes = NSIndexSet(index: nextIndex);
            }
            
        } else if itemCount > 0 {
            _anchorRow = goingForward ? 0 : itemCount - 1
            self.selectedIndexes = NSIndexSet(index: _anchorRow!)
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
    

}

