//
//  CDTimelineTrackView.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/25/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


@objc // Needed (I forget why)
protocol CDTimelineTrackViewDataSource : NSObjectProtocol {
    // complete reload or new values
    func numberOfItemsInTimelineTrackView(_ timelineTrackView: CDTimelineTrackView) -> Int
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, itemAtIndex: Int) -> CDTimelineItem
    @objc optional func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, makeViewControllerAtIndex: Int) -> NSViewController
}

protocol CDTimelineTrackViewDraggingSourceDelegate {
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, pasteboardWriterForIndex index: Int) -> NSPasteboardWriting?
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forIndexes indexes: IndexSet)
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation)
}

protocol CDTimelineTrackViewDraggingDestinationDelegate {
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, updateDraggingInfo: NSDraggingInfo, insertionIndex: Int?) -> NSDragOperation
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, performDragOperation: NSDraggingInfo, insertionIndex: Int?) -> Bool
    
}

let CDTimelineNoIndex: Int = -1

// also see:
//static let durationResizeWidth: CGFloat = 5
//static let selectionBorderWidth: CGFloat = 2
//static let normalBorderWidth: CGFloat = 1

let TOP_SPACING: CGFloat = 0.0
let BOTTOM_SPACING: CGFloat = 0.0

extension NSEvent {
    var character: Int {
        let str = charactersIgnoringModifiers!.utf16
        return Int(str[str.startIndex])
    }
}

extension NSView {
    func screenshotAsImage() -> NSImage {
        let bounds = self.bounds
        let imageRep = self.bitmapImageRepForCachingDisplay(in: bounds)!
        self.cacheDisplay(in: bounds, to: imageRep)
        let image = NSImage(size: imageRep.size)
        image.addRepresentation(imageRep)
        return image
    }
}

class CDTimelineTrackView: NSStackView, NSDraggingSource {
    // I like a more subtle look for showing the first responder..
    static let selectedBorderColor = NSColor.alternateSelectedControlColor.withAlphaComponent(0.5)
    static let draggingInsertionColor = NSColor.green // TODO: color??
    static let trackHeight: CGFloat = 50.0 // Variable??
    
    var sideSpacing: CGFloat = 10.0 {
        didSet {
            self.edgeInsets = NSEdgeInsetsMake(TOP_SPACING, sideSpacing, BOTTOM_SPACING, sideSpacing)
        }
    }
    fileprivate let _dragThreshold: CGFloat = 5

    func _commonInit() {
        self.wantsLayer = true;
        self.orientation = .horizontal
        self.layerContentsRedrawPolicy = .onSetNeedsDisplay

        self.setClippingResistancePriority(NSLayoutPriorityRequired, for: NSLayoutConstraintOrientation.horizontal)
        self.setClippingResistancePriority(NSLayoutPriorityRequired, for: NSLayoutConstraintOrientation.vertical)
        self.setHuggingPriority(NSLayoutPriorityDefaultLow - 0.00001, for: NSLayoutConstraintOrientation.horizontal)
        self.setHuggingPriority(NSLayoutPriorityDefaultLow - 0.00001, for: NSLayoutConstraintOrientation.vertical)
        // stack view properties
        self.spacing = 0;
        self.edgeInsets = NSEdgeInsetsMake(TOP_SPACING, sideSpacing, BOTTOM_SPACING, sideSpacing)
        
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
    
    var dataSource: CDTimelineTrackViewDataSource? {
        didSet {
            reloadData();
        }
    }
    
    var numberOfItems: Int {
        get {
            if let d = self.dataSource {
                return d.numberOfItemsInTimelineTrackView(self)
            } else {
                return 0;
            }
        }
    }
    
    fileprivate var _needsUpdate: Bool = false
    
    func reloadData() {
        self.needsLayout = true;
        _needsUpdate = true
        _removeAllTimelineItemViews()
        
    }
    
    fileprivate var _selectionChanged = false
    
    func _doWorkToChangeSelection(_ work: () -> Void) {
        if (!self.updating) {
            self.willChangeValue(forKey: "selectionIndexes")
        }
        work()
        
        if (!self.updating) {
            self.didChangeValue(forKey: "selectionIndexes")
        } else {
            _selectionChanged = true;
        }
        self.needsDisplay = true
    }
    
    func _removeAllTimelineItemViews() {
        for view in self.views {
            self.removeView(view)
        }
        assignViewBeingResized(nil)
        _timelineItemViewControllers.removeAllObjects()
        
        _anchorRow = nil
        _doWorkToChangeSelection({
            self._selectionIndexes = IndexSet()
        })
        
    }
    
    func _delegateTimelineTrackViewControllerAtIndex(_ index: Int) -> NSViewController {
        if let result = dataSource?.timelineTrackView?(self, makeViewControllerAtIndex: index) {
            return result
        } else {
            let vc = NSViewController()
            vc.view = CDTimelineItemView(frame: frame)
            return vc
        }
    }
    
    var widthPerMS: CGFloat = CDTimelineItemView.defaultWidthPerSecond / 1000.0 {
        didSet {
            for view in self.views {
                let view = view as! CDTimelineItemView
                view.widthPerMS = widthPerMS
            }
        }
    }
    
    var _timelineItemViewControllers = NSMutableArray()
    
    func _makeTimelineItemViewAtIndex(_ index: Int, frame: NSRect, timelineItem: CDTimelineItem) -> CDTimelineItemView {
        let vc: NSViewController = _delegateTimelineTrackViewControllerAtIndex(index)
        _timelineItemViewControllers.insert(vc, at: index)
        let result = vc.view as! CDTimelineItemView
        result.timelineItem = timelineItem
        result.widthPerMS = self.widthPerMS
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
        for i in 0 ..< self.numberOfItems {
            let timelineItem = self.dataSource!.timelineTrackView(self, itemAtIndex: i)
            let itemView = _makeTimelineItemViewAtIndex(i, frame: itemFrame, timelineItem: timelineItem)
            self.addView(itemView, in: NSStackViewGravity.leading)
        }
    }
    
    func insertItemAtIndex(_ index: Int) {
        let timelineItem = self.dataSource!.timelineTrackView(self, itemAtIndex: index)
        let itemFrame = _defaultItemViewFrame()
        let itemView = _makeTimelineItemViewAtIndex(index, frame: itemFrame, timelineItem: timelineItem)
        self.insertView(itemView, at: index, in: NSStackViewGravity.leading)
        
        _shiftSelectionFromIndex(index)
    }
    
    func _shiftSelectionFromIndex(_ index: Int) {
        _doWorkToChangeSelection() {
            if let anchorRow = self._anchorRow {
                if anchorRow >= index {
                    self._anchorRow = anchorRow + 1
                }
            }
            
            var mutableIndexes = IndexSet(self._selectionIndexes)
            mutableIndexes.shift(startingAt: index, by: 1) // Swift 3
            self._selectionIndexes = mutableIndexes;
            
            if let draggedIndexes = self.draggedIndexes {
                var mutableIndexes = IndexSet(draggedIndexes)
                mutableIndexes.shift(startingAt: index, by: 1)
                self.draggedIndexes = mutableIndexes
            }
        }
    }
    
    fileprivate var _updateCount = 0
    func beginUpdates() {
        if (_updateCount == 0) {
            _selectionChanged = false
        }
        _updateCount += 1;
    }
    
    func endUpdates() {
        _updateCount -= 1;
        if _updateCount == 0 {
            if (_selectionChanged) {
                _selectionChanged = false;
                self.willChangeValue(forKey: "selectionIndexes")
                self.didChangeValue(forKey: "selectionIndexes")
            }
        }
    }
    
    var updating: Bool {
        return _updateCount > 0
    }
    
    func _adjustIndexSetForIndexRemoval(_ indexSet: IndexSet, index: Int) -> IndexSet {
        var mutableIndexes = IndexSet(indexSet)
        // Remove that item
        mutableIndexes.remove(index)
        // Then move things for all indexes less than it
        mutableIndexes.shift(startingAt: index, by: -1)
        return mutableIndexes
    }
    
    func _removeIndexFromSelection(_ index: Int) {
        // Don't go through the "setter"
        _doWorkToChangeSelection() {
            self._selectionIndexes = self._adjustIndexSetForIndexRemoval(self._selectionIndexes, index: index)
            
            if let anchorRow = self._anchorRow {
                if anchorRow == index {
                    if self._selectionIndexes.count > 0 {
                        self._anchorRow = self._selectionIndexes.first
                    } else {
                        self._anchorRow = nil
                    }
                } else if anchorRow > index {
                    self._anchorRow = anchorRow - 1
                }
            }
            
            if let draggedIndexes = self.draggedIndexes {
                self.draggedIndexes = self._adjustIndexSetForIndexRemoval(draggedIndexes, index: index)
            }
        }
    }

    func removeItemsAtIndexes(_ indexes: IndexSet) {
        beginUpdates()
        (indexes as NSIndexSet).enumerate(options: [.reverse]) { (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            self.removeItemAtIndex(index)
        }
        endUpdates()        
    }
    
    func removeItemAtIndex(_ index: Int) {
        let view = self.views[index]
        self.removeView(view)
        _timelineItemViewControllers.removeObject(at: index)
        _removeIndexFromSelection(index)
    }
    
//        // I don't think this is doing anything anymore...
//    private var _registeredForChanges = false
//    private func _registerForSuperFrameChangesIfNeeded() {
//        if let newSuper = self.superview {
//            if (!_registeredForChanges) {
//                _registeredForChanges = true;
//                weak var weakSelf = self;
//                // We want to know when the clip view's size changes (via the scrollview) so we can fill the height by changing our intrinsic size that we have
//                NSNotificationCenter.defaultCenter().addObserverForName(NSViewFrameDidChangeNotification, object: newSuper, queue: nil, usingBlock: { (note: NSNotification) -> Void in
//                    weakSelf?.invalidateIntrinsicContentSize()
//                    // All our views also depend on our size (for now!)
//                    //                for view in self.views {
//                    //                    view.invalidateIntrinsicContentSize()
//                    //                }
//                })
//                // Invalidate us right away too..
//                self.invalidateIntrinsicContentSize()
//            }
//        }
//    }
//    
//    override func viewWillMoveToSuperview(newSuperview: NSView?) {
//        super.viewWillMoveToSuperview(newSuperview)
//        if _registeredForChanges && newSuperview == nil {
//            _registeredForChanges = false
//            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSViewFrameDidChangeNotification, object: self.superview!)
//        }
//    }
//    
//    // Dynamic height fill:
//    override func viewDidMoveToSuperview() {
//        super.viewDidMoveToSuperview()
//        _registerForSuperFrameChangesIfNeeded()
//    }
//    
//    override func viewDidMoveToWindow() {
//        super.viewDidMoveToWindow()
//        // I'm not getting viewWillMoveToSuperview since it is setup in the nib (strange..)
//        _registerForSuperFrameChangesIfNeeded()
//    }

    override var intrinsicContentSize : NSSize {
        get {
            var requestedSize = super.intrinsicContentSize
            // fill the scroll view width
            if let superview = self.enclosingScrollView {
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

    func scrollItemAtIndexToVisible(_ index: Int) {
        self.layoutSubtreeIfNeeded()
        let viewToShow = self.views[index]
        viewToShow.scrollToVisible(viewToShow.bounds)
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
    
    // old code for highlghting on first responder
    override func updateLayer() {
//        guard let layer = self.layer else {
//            return;
//        }
//        layer.backgroundColor = NSColor(white: 0, alpha: 0.25).CGColor
//        if _isFirstResponder && self.selectionIndexes.count == 0 {
//            layer.borderWidth = 2.0
//            layer.cornerRadius = 2.0
//            layer.borderColor = CDTimelineTrackView.selectedBorderColor.CGColor
//        } else {
//            layer.borderWidth = 0.0
//        }
    }

//    private var _isFirstResponder: Bool {
//        return self.window?.firstResponder == self
//    }
//    
//    override func becomeFirstResponder() -> Bool {
//        let r = super.becomeFirstResponder()
//        self.needsDisplay = true
//        return r
//    }
//    
//    override func resignFirstResponder() -> Bool {
//        let r = super.resignFirstResponder()
//        self.needsDisplay = true
//        return r
//    }
    
    func _resetAnchorRow() {
        if self.selectionIndexes.count > 0 {
            _anchorRow = self.selectionIndexes.first
        } else {
            _anchorRow = nil;
        }
    }
    
    func _updateSelectionState(_ priorSelectedIndexes: IndexSet, newSelectedRows: IndexSet) {
        // easiest implementation for now
        (priorSelectedIndexes as NSIndexSet).enumerate({ (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let itemView = self.views[index] as! CDTimelineItemView
            itemView.selected = false
        })
        
        (newSelectedRows as NSIndexSet).enumerate({ (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let itemView = self.views[index] as! CDTimelineItemView
            itemView.selected = true
        })
    }
    
    fileprivate var _settingViewBeingResized: Bool = false;
    func assignViewBeingResized(_ newView: CDTimelineItemView?) {
        if let oldView = self._viewBeingResized {
            if oldView != newView {
                oldView.resizing = false;
            }
        }
        
        self._viewBeingResized = newView;
        
        if newView != nil {
            if let itemIndex = self.views.index(of: newView!) {
                // drop selection to just this item
                _settingViewBeingResized = true;
                self.selectionIndexes = IndexSet(integer: itemIndex)
                _settingViewBeingResized = false
            }
        }
        
    }
    
    // when non-nil, we can't extend selection, etc.
    fileprivate weak var _viewBeingResized: CDTimelineItemView?
    
    var _shouldUpdateAnchorRow = true
    var _selectionIndexes: IndexSet = IndexSet()
    
    var primaryIndex: Int? {
//        if let r = _anchorRow {
//            NSAssert(_selectionIndexes.containsIndex(r), "validation")
//        }
        return _anchorRow
    }
    
    dynamic var selectionIndexes: IndexSet {
        set(v) {
            if (_selectionIndexes != v) {
                let priorSelectedIndexes = (_selectionIndexes as NSIndexSet).mutableCopy() as! NSMutableIndexSet
                priorSelectedIndexes.remove(v)
                
                _selectionIndexes = v

                // Keep the anchor row valid..
                if _shouldUpdateAnchorRow {
                    _resetAnchorRow()
                }
                _updateSelectionState(priorSelectedIndexes as IndexSet, newSelectedRows: v);
                
                // Don't allow a duration selection when this is selected..
                if !_settingViewBeingResized && v.count != 0 {
                    assignViewBeingResized(nil)
                }
                self.needsDisplay = true
            }
        }
        get {
            return _selectionIndexes;
        }
    }
    
    internal func indexOfView(_ view: NSView?) -> Int? {
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
            return self.views.index(of: v)
        } else {
            return nil
        }

    }

    // selection is based off this row
    var _anchorRow: Int?
    
    
    fileprivate func _indexOfViewAtPoint(_ point: NSPoint) -> Int? {
        // I'm not sure this is a great idea, but hit testing is failing..
        for i in 0 ..< self.views.count {
            let view = views[i]
            if NSPointInRect(point, view.frame) {
                return i
            }
        }
        return nil
    }
    
    fileprivate func _hitIndexForEvent(_ theEvent: NSEvent) -> Int? {
        return _indexOfViewAtPoint(theEvent.locationInView(self))
    }

    // return the last hit
    fileprivate func _processMouseEvent(_ theEvent: NSEvent) {
        if theEvent.type != .leftMouseDown {
            return
        }
        
//        let hitLocation = theEvent.locationInView(self)
//        let hitView = self.hitTest(hitLocation)
        let hitIndex = _hitIndexForEvent(theEvent)
        let newSelectedRows = NSMutableIndexSet()
        var newAnchorRow: Int? = nil
        
        if let hitIndex = hitIndex {
            if let currentAnchorIndex = _anchorRow {
                // If we did hit something, then select from the anchor to it, if extending the selection
                let shiftIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.shift);
                let cmdIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.command);
                if (_viewBeingResized != nil && (cmdIsDown || shiftIsDown)) {
                    // We can't process it; it conflicts with the duration selection
                    newAnchorRow = _anchorRow
                    newSelectedRows.add(self.selectionIndexes)
                    NSBeep();
                } else if (shiftIsDown) {
                    // anchor row direct to the new hit row
                    let firstIndex = min(hitIndex, currentAnchorIndex)
                    let lastIndex = max(hitIndex, currentAnchorIndex)
                    let length = lastIndex - firstIndex + 1
                    newAnchorRow = currentAnchorIndex
                    newSelectedRows.add(in: NSRange(location: firstIndex, length: length))
                } else if (cmdIsDown) {
                    // toggle behavior
                    newAnchorRow = currentAnchorIndex
                    newSelectedRows.add(self.selectionIndexes)
                    if (newSelectedRows.contains(hitIndex)) {
                        newSelectedRows.remove(hitIndex)
                    } else {
                        newSelectedRows.add(hitIndex)
                    }
                } else {
                    // basic selection changing the anchor
                    newAnchorRow = hitIndex
                    newSelectedRows.add(hitIndex)
                }
            } else {
                // no anchor, new selection
                newAnchorRow = hitIndex
                newSelectedRows.add(hitIndex)
            }
        }

        _anchorRow = newAnchorRow
        self.selectionIndexes = newSelectedRows as IndexSet
        assignViewBeingResized(nil) // drop it..
    }
    
    
    fileprivate func _shouldDragBeginWithEvent(_ event: NSEvent) -> Bool {
        // track the mouse a bit to see if we are dragging vs selecting.
        guard let window = self.window else { return false }
        var shouldStartDrag: Bool = false
        if event.clickCount == 1 {
            let startingPoint = event.locationInWindow
            
            window.trackEvents(matching: [NSEventMask.leftMouseUp, NSEventMask.leftMouseDragged], timeout: NSEventDurationForever, mode: RunLoopMode.eventTrackingRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                
                switch event.type {
                case NSEventType.leftMouseDragged:
                    let currentPoint = event.locationInWindow
                    if abs(currentPoint.x - startingPoint.x) > self._dragThreshold || abs(currentPoint.y - startingPoint.y) > self._dragThreshold {
                        // start a drag!
                        shouldStartDrag = true
                        stop.pointee = true;
                    }
                case NSEventType.leftMouseUp:
                    // Didn't do a drag; repost this event (and maybe the drags? probably not needed...)
                    NSApp.postEvent(event, atStart: true)
                    stop.pointee = true
                default:
                    break
                }
            })
        }
        
        return shouldStartDrag
    }
    
    fileprivate func _makeDraggingItemForIndex(_ index: Int, pasteboardWriter: NSPasteboardWriting) -> NSDraggingItem {
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardWriter)
        draggingItem.imageComponentsProvider = {
            let view = self.views[index]

            let component = NSDraggingImageComponent(key: NSDraggingImageComponentIconKey)
            component.contents = view.screenshotAsImage()
            component.frame = self.convert(view.bounds, from: view)

            return [component]
        }
        return draggingItem
    }
    
    fileprivate func _startDraggingSessionWithEvent(_ event: NSEvent, indexes: IndexSet, hitIndex: Int) -> Bool {
        guard let draggingSourceDelegate = draggingSourceDelegate else { return false }
        // Create pasteboard writers
        self.draggedIndexes = indexes // set them..
        var mutableIndexes = IndexSet(indexes)
        
        var leaderIndex: Int? = hitIndex
        var items = [NSDraggingItem]()
        for index in indexes {
            if let writer = draggingSourceDelegate.timelineTrackView(self, pasteboardWriterForIndex: index) {
                let draggingItem = _makeDraggingItemForIndex(index, pasteboardWriter: writer)
                items.append(draggingItem)
            } else {
                // not being dragged if we didn't get a writer
                mutableIndexes.remove(index)
                if leaderIndex == index {
                    leaderIndex = nil
                } else if leaderIndex != nil && index < leaderIndex {
                    leaderIndex = leaderIndex! - 1
                }
            }
        }
        
        // If we have something, try to do it
        if items.count > 0 {
            self.draggedIndexes = mutableIndexes;
            let session = self.beginDraggingSession(with: items, event: event, source: self)
            if let leaderIndex = leaderIndex {
                session.draggingLeaderIndex = leaderIndex
            }
            return true
        } else {
            self.draggedIndexes = nil // drop them.. we didn't do it
            return false
        }
    }
    
    // returns true if it did a drag
    fileprivate func _attemptDragWithEvent(_ event: NSEvent) -> Bool {
        var result: Bool = false
        if draggingSourceDelegate != nil {
            let hitIndex = _hitIndexForEvent(event)
            if let hitIndex = hitIndex {
                if _shouldDragBeginWithEvent(event) {
                    // drag everything if it was hit in a selection
                    if self.selectionIndexes.contains(hitIndex) {
                        result = _startDraggingSessionWithEvent(event, indexes: self.selectionIndexes, hitIndex: hitIndex)
                    } else {
                        // drag just that one row
                        result = _startDraggingSessionWithEvent(event, indexes: IndexSet(integer: hitIndex), hitIndex: hitIndex)
                    }
                    
                }
            }
        }
        return result
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        if self.acceptsFirstResponder {
            self.window?.makeFirstResponder(self)
        }
        
        // First, try to drag
        if _attemptDragWithEvent(theEvent) {
            return;
        }
        
        _shouldUpdateAnchorRow = false
        
        self.window?.trackEvents(matching: [NSEventMask.leftMouseDragged, NSEventMask.leftMouseUp], timeout: NSEventDurationForever, mode: RunLoopMode.eventTrackingRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
        
            self._processMouseEvent(theEvent)
            if event.type == .leftMouseUp {
                stop.pointee = true
            }
        })
        _shouldUpdateAnchorRow = true
    }
    
    func _keepIndexValid(_ index: Int) -> Int {
        var result = index
        if (result < 0) {
            result = 0;
        } else if (result >= self.numberOfItems) {
            result = self.numberOfItems - 1;
        }
        return result
    }
    
    func _selectNextIndexFromAnchorExtending(_ extendingSelection: Bool, goingForward: Bool) {
        _shouldUpdateAnchorRow = false
        
        let itemCount = self.numberOfItems;
        if let anchorIndex = _anchorRow {
            if extendingSelection {
                var firstIndex = self.selectionIndexes.first!
                var endingIndex = self.selectionIndexes.last!
                if anchorIndex == firstIndex {
                    // From the anchor to somewhere past it
                    if goingForward {
                        endingIndex = endingIndex + 1
                    } else if firstIndex == endingIndex {
                        // Dec the first index instead of the ending
                        firstIndex = firstIndex - 1
                    } else {
                        endingIndex = endingIndex - 1
                    }
                } else {
                    // expand at the start of the selection
                    if goingForward {
                        firstIndex = firstIndex + 1
                    } else {
                        firstIndex = firstIndex - 1
                    }
                }
                
                firstIndex = _keepIndexValid(firstIndex)
                endingIndex = _keepIndexValid(endingIndex)
                let length = endingIndex - firstIndex + 1
                // Leave the anchor row where it is
//                self.selectionIndexes = IndexSet(integersIn: NSRange(location: firstIndex, length: length).toRange() ?? 0..<0)  // Swift migrator did this
                self.selectionIndexes = IndexSet(integersIn: firstIndex ..< (firstIndex + length))

            } else {
                var nextIndex = goingForward ? anchorIndex + 1 : anchorIndex - 1;
                nextIndex = _keepIndexValid(nextIndex)
                _anchorRow = nextIndex
                self.selectionIndexes = IndexSet(integer: nextIndex);
            }
            
        } else if itemCount > 0 {
            _anchorRow = goingForward ? 0 : itemCount - 1
            self.selectionIndexes = IndexSet(integer: _anchorRow!)
        }
        // make it visible
        if let anchorRow = _anchorRow {
            self.scrollItemAtIndexToVisible(anchorRow)
        }
        _shouldUpdateAnchorRow = true
    }
    
    override func selectAll(_ sender: Any?) {
        self.selectionIndexes = IndexSet(integersIn: 0 ..< self.numberOfItems)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        var callSuper = false
        let shiftIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.shift);

        if self.numberOfItems > 0 {
            switch theEvent.character {
            case NSRightArrowFunctionKey:
                _selectNextIndexFromAnchorExtending(shiftIsDown, goingForward: true)
            case NSLeftArrowFunctionKey:
                _selectNextIndexFromAnchorExtending(shiftIsDown, goingForward: false)
            case NSDeleteCharacter:
                if self.selectionIndexes.count > 0 {
                    NSApp.sendAction(#selector(NSText.delete(_:)), to: nil, from: self)
                }
            default:
                callSuper = true;
            }
        } else {
            callSuper = true;
        }
        
        if callSuper {
            super.keyDown(with: theEvent)
        }
    }
    
    override var acceptsFirstResponder: Bool  {
        get {
            return true;
        }
    }
    
    var draggingSourceDelegate: CDTimelineTrackViewDraggingSourceDelegate?
    
    
    // MARK: NSDraggingSource protocol implementation
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        // TODO: move to delegate when needed
        if context == NSDraggingContext.withinApplication {
            return NSDragOperation.every
        } else {
            // TODO: maybe allow dropping images on it??
            return NSDragOperation()
        }
    }
    
    var draggedIndexes: IndexSet? // non nil when we are dragging
    
    fileprivate func _fadeDraggedIndexesToValue(_ value: CGFloat) {
        // Fade out all the dragged items a bit..
        if let draggedIndexes = self.draggedIndexes {
            NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) -> Void in
                context.allowsImplicitAnimation = true
                for index in draggedIndexes {
                    let view = self.views[index]
                    view.alphaValue = value
                }
                
                }, completionHandler: nil)
        }
    }
    
    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        if let draggingSourceDelegate = draggingSourceDelegate {
            draggingSourceDelegate.timelineTrackView(self, draggingSession: session, willBeginAtPoint: screenPoint, forIndexes: self.draggedIndexes!)
        }
        _fadeDraggedIndexesToValue(0.5)
    }

    func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if let draggingSourceDelegate = draggingSourceDelegate {
            draggingSourceDelegate.timelineTrackView(self, draggingSession: session, endedAtPoint: screenPoint, operation: operation)
        }
        _fadeDraggedIndexesToValue(1.0)
        // drop the indexes at this point
        self.draggedIndexes = nil
    }
    
    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        return false
    }
    
    fileprivate func _makeDraggingInsertionViewWithFrame(_ frame: NSRect) -> NSView {
        let result = NSView(frame: frame)
        result.wantsLayer = true
        result.layer!.backgroundColor = CDTimelineTrackView.draggingInsertionColor.cgColor
        result.layerContentsRedrawPolicy = .never
        return result
    }
    
    fileprivate let _insertionDividerWidth: CGFloat = 2.0
    fileprivate func _draggingInsertionViewFrameForIndex(_ index: Int) -> NSRect {
        var result: NSRect
        let viewCount = self.views.count
        if index < viewCount {
            result = self.views[index].frame
            result.origin.x -= _insertionDividerWidth/2.0
            result.size.width = _insertionDividerWidth
        } else if viewCount > 0 {
            assert(index == viewCount, "index check")
            // Past the last view
            result = self.views[viewCount-1].frame
            result.origin.x = NSMaxX(result)
            result.origin.x -= _insertionDividerWidth/2.0
            result.size.width = _insertionDividerWidth
        } else {
            // no views...at the start..
            assert(index == 0, "only start should work")
            result = self.bounds
            
            result.origin.x += self.edgeInsets.left
            result.origin.y += self.edgeInsets.top
            result.size.width = _insertionDividerWidth;
            result.size.height = NSHeight(result) - (self.edgeInsets.top + self.edgeInsets.bottom)
        }
        
        return result;
    }
    
    fileprivate var _draggingInsertionPointView: NSView?
    fileprivate func _updateDraggingInsertionPointView() {
        if let index = self.draggingInsertIndex {
            let insertionFrame = _draggingInsertionViewFrameForIndex(index);
            if let v = _draggingInsertionPointView {
                // Just update the frame
                v.frame = insertionFrame
            } else {
                // create it and add it
                let v = _makeDraggingInsertionViewWithFrame(insertionFrame)
                self.addSubview(v)
                _draggingInsertionPointView = v;
            }
        } else {
            if let v = _draggingInsertionPointView {
                v.removeFromSuperview()
                _draggingInsertionPointView = nil;
            }
        }
    }
    

    var draggingDestinationDelegate: CDTimelineTrackViewDraggingDestinationDelegate?
    
    var draggingInsertIndex: Int?  {
        didSet {
            // Add a view for the insertion point
            _updateDraggingInsertionPointView()
        }
    }
    
    fileprivate func _updateDraggingDestinationState(_ draggingInfo: NSDraggingInfo) -> NSDragOperation {
        let point = self.convert(draggingInfo.draggingLocation(), from: nil)
        var result = NSDragOperation()
        var otherIndexToTry: Int?
        
        if let hitIndex = _indexOfViewAtPoint(point) {
            // Find out what view we hit and how far we are in it in order to do an insert before or after it.
            let hitView = self.views[hitIndex]
            let pointInHitView = hitView.convert(draggingInfo.draggingLocation(), from: nil)
            let halfWidth = hitView.bounds.size.width / 2.0
            if pointInHitView.x <= halfWidth {
                // Before it, which is it's index itself for the insertion point
                self.draggingInsertIndex = hitIndex
                // And if this doesn't work, try otherIndexToTry..
                otherIndexToTry = hitIndex + 1
            } else {
                // After it
                self.draggingInsertIndex = hitIndex + 1;
                otherIndexToTry = hitIndex
            }
            result = NSDragOperation.every
        } else {
            // If we didn't hit a child view and instead hit us, find out where in us we are for the insert
            // First, none check
            if self.views.count == 0 {
                self.draggingInsertIndex = 0
                result = NSDragOperation.every
            } else {
                // Make sure we are before or after the first view, and not above another one..which isn't going to work
                if point.x <= NSMinX(self.views[0].frame) {
                    self.draggingInsertIndex = 0
                    result = NSDragOperation.every
                } else if point.x >= NSMaxX(self.views.last!.frame) {
                    self.draggingInsertIndex = self.views.count // Past it
                    result = NSDragOperation.every
                }
            }
        }
        
        // Filter through the delegate
        if let d = self.draggingDestinationDelegate {
            result = d.timelineTrackView(self, updateDraggingInfo: draggingInfo, insertionIndex: self.draggingInsertIndex)
            // If the delegate doesn't accept, implicitlely clear the drop point
            if result == NSDragOperation() {
                // If we have another index, try again..
                if let otherIndexToTry = otherIndexToTry {
                    self.draggingInsertIndex = otherIndexToTry
                    result = d.timelineTrackView(self, updateDraggingInfo: draggingInfo, insertionIndex: self.draggingInsertIndex)
                }
                
                if result == NSDragOperation() {
                    self.draggingInsertIndex = nil
                }
            }
        }
        
        return result
        
    }
    
    fileprivate func _clearDraggingDestinationState() {
        self.draggingInsertIndex = nil
    }
    
    // MARK: NSDraggingDestination protocol implementation..
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return _updateDraggingDestinationState(sender)
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return _updateDraggingDestinationState(sender)
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        _clearDraggingDestinationState()
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // I don't think we need a _updateDraggingDestinationState(sender) call..
        if let d = self.draggingDestinationDelegate {
            if d.timelineTrackView(self, performDragOperation: sender, insertionIndex: self.draggingInsertIndex) {
                return true
            } else {
                // we don't get a conclude??
                _clearDraggingDestinationState();
                return false
            }
        } else {
            _clearDraggingDestinationState();
            return false
        }
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        _clearDraggingDestinationState()
    }
//    func draggingEnded(sender: NSDraggingInfo?) {
//        
//    }
    override func wantsPeriodicDraggingUpdates() -> Bool {
        return true
    }

    
}

