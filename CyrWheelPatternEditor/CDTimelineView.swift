//
//  CDTimelineview.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/25/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

@objc // Needed (I forget why)
protocol CDTimelineViewDataSource : NSObjectProtocol {
    // complete reload or new values
    func numberOfItemsInTimelineView(timelineView: CDTimelineView) -> Int
    func timelineView(timelineView: CDTimelineView, itemAtIndex: Int) -> CDTimelineItem
    optional func timelineView(timelineView: CDTimelineView, makeViewControllerAtIndex: Int) -> NSViewController
}

protocol CDTimelineViewDraggingSourceDelegate {
    func timelineView(timelineView: CDTimelineView, pasteboardWriterForIndex index: Int) -> NSPasteboardWriting?
    func timelineView(timelineView: CDTimelineView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forIndexes indexes: NSIndexSet)
    func timelineView(timelineView: CDTimelineView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation)
}

protocol CDTimelineViewDraggingDestinationDelegate {
    func timelineView(timelineView: CDTimelineView, updateDraggingInfo: NSDraggingInfo, insertionIndex: Int?) -> NSDragOperation
    func timelineView(timelineView: CDTimelineView, performDragOperation: NSDraggingInfo, insertionIndex: Int?) -> Bool
    
}

let CDTimelineNoIndex: Int = -1

// also see:
//static let durationResizeWidth: CGFloat = 5
//static let selectionBorderWidth: CGFloat = 2
//static let normalBorderWidth: CGFloat = 1

let TOP_SPACING: CGFloat = 10.0
let BOTTOM_SPACING: CGFloat = 10.0

extension NSEvent {
    var character: Int {
        let str = charactersIgnoringModifiers!.utf16
        return Int(str[str.startIndex])
    }
}

extension NSView {
    func screenshotAsImage() -> NSImage {
        let bounds = self.bounds
        let imageRep = self.bitmapImageRepForCachingDisplayInRect(bounds)!
        self.cacheDisplayInRect(bounds, toBitmapImageRep: imageRep)
        let image = NSImage(size: imageRep.size)
        image.addRepresentation(imageRep)
        return image
    }
}

class CDTimelineView: NSStackView, NSDraggingSource {
    // TODO: better way of dealing with UI constants/appearance for the view..
    static let itemFillColor = NSColor(SRGBRed: 49.0/255.0, green: 49.0/255.0, blue: 49.0/255.0, alpha: 1.0)
    static let itemBorderColor = NSColor(SRGBRed: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
    static let itemSelectedBorderColor = NSColor.alternateSelectedControlColor()
    // I like a more subtle look for showing the first responder..
    static let selectedBorderColor = NSColor.alternateSelectedControlColor().colorWithAlphaComponent(0.5)
    static let draggingInsertionColor = NSColor.greenColor() // TODO: color??
    
    private let _sideSpacing: CGFloat = 4.0
    private let _dragThreshold: CGFloat = 5

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
        self.edgeInsets = NSEdgeInsetsMake(TOP_SPACING, _sideSpacing, BOTTOM_SPACING, _sideSpacing)
        
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
    
    func _doWorkToChangeSelection(work: () -> Void) {
        self.willChangeValueForKey("selectionIndexes")
        work()
        self.didChangeValueForKey("selectionIndexes")
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
            
            if let draggedIndexes = self.draggedIndexes {
                let mutableIndexes = NSMutableIndexSet(indexSet: draggedIndexes)
                mutableIndexes.shiftIndexesStartingAtIndex(index, by: 1)
                self.draggedIndexes = mutableIndexes
            }
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
            
            if let draggedIndexes = self.draggedIndexes {
                let mutableIndexes = NSMutableIndexSet(indexSet: draggedIndexes)
                mutableIndexes.removeIndex(index)
                self.draggedIndexes = mutableIndexes
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
        guard let layer = self.layer else {
            return;
        }
        if _isFirstResponder && self.selectionIndexes.count == 0 {
            layer.borderWidth = 2.0
            layer.cornerRadius = 2.0
            layer.borderColor = CDTimelineView.selectedBorderColor.CGColor
        } else {
            layer.borderWidth = 0.0
        }
    }
    
    private var _isFirstResponder: Bool {
        return self.window?.firstResponder == self
    }
    
    override func becomeFirstResponder() -> Bool {
        let r = super.becomeFirstResponder()
        self.needsDisplay = true
        return r
    }
    
    override func resignFirstResponder() -> Bool {
        let r = super.resignFirstResponder()
        self.needsDisplay = true
        return r
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
    
    private var _settingViewBeingResized: Bool = false;
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
                _settingViewBeingResized = true;
                self.selectionIndexes = NSIndexSet(index: itemIndex)
                _settingViewBeingResized = false
            }
        }
        
    }
    
    // when non-nil, we can't extend selection, etc.
    private weak var _viewBeingResized: CDTimelineItemView?
    
    var _shouldUpdateAnchorRow = true
    var _selectionIndexes: NSIndexSet = NSIndexSet()
    
    var primaryIndex: Int? {
//        if let r = _anchorRow {
//            NSAssert(_selectionIndexes.containsIndex(r), "validation")
//        }
        return _anchorRow
    }
    
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
    
    internal func indexOfView(view: NSView?) -> Int? {
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
    
    private func _hitIndexForEvent(theEvent: NSEvent) -> Int? {
        let hitLocation = theEvent.locationInView(self)
        let hitView = self.hitTest(hitLocation)
        return indexOfView(hitView)
    }

    // return the last hit
    private func _processMouseEvent(theEvent: NSEvent) {
        if theEvent.type != .LeftMouseDown {
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
        assignViewBeingResized(nil) // drop it..
    }
    
    
    private func _shouldDragBeginWithEvent(event: NSEvent) -> Bool {
        // track the mouse a bit to see if we are dragging vs selecting.
        guard let window = self.window else { return false }
        var shouldStartDrag: Bool = false
        if event.clickCount == 1 {
            let startingPoint = event.locationInWindow
            
            window.trackEventsMatchingMask([NSEventMask.LeftMouseUpMask, NSEventMask.LeftMouseDraggedMask], timeout: NSEventDurationForever, mode: NSEventTrackingRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                
                switch event.type {
                case NSEventType.LeftMouseDragged:
                    let currentPoint = event.locationInWindow
                    if abs(currentPoint.x - startingPoint.x) > self._dragThreshold || abs(currentPoint.y - startingPoint.y) > self._dragThreshold {
                        // start a drag!
                        shouldStartDrag = true
                        stop.memory = true;
                    }
                case NSEventType.LeftMouseUp:
                    // Didn't do a drag; repost this event (and maybe the drags? probably not needed...)
                    NSApp.postEvent(event, atStart: true)
                    stop.memory = true
                default:
                    break
                }
            })
        }
        
        return shouldStartDrag
    }
    
    private func _makeDraggingItemForIndex(index: Int, pasteboardWriter: NSPasteboardWriting) -> NSDraggingItem {
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardWriter)
        draggingItem.imageComponentsProvider = {
            let view = self.views[index]

            let component = NSDraggingImageComponent(key: NSDraggingImageComponentIconKey)
            component.contents = view.screenshotAsImage()
            component.frame = self.convertRect(view.bounds, fromView: view)

            return [component]
        }
        return draggingItem
    }
    
    private func _startDraggingSessionWithEvent(event: NSEvent, indexes: NSIndexSet, hitIndex: Int) -> Bool {
        guard let draggingSourceDelegate = draggingSourceDelegate else { return false }
        // Create pasteboard writers
        self.draggedIndexes = indexes // set them..
        let mutableIndexes = NSMutableIndexSet(indexSet: indexes)
        
        var leaderIndex: Int? = hitIndex
        var items = [NSDraggingItem]()
        for index in indexes {
            if let writer = draggingSourceDelegate.timelineView(self, pasteboardWriterForIndex: index) {
                let draggingItem = _makeDraggingItemForIndex(index, pasteboardWriter: writer)
                items.append(draggingItem)
            } else {
                // not being dragged if we didn't get a writer
                mutableIndexes.removeIndex(index)
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
            let session = self.beginDraggingSessionWithItems(items, event: event, source: self)
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
    private func _attemptDragWithEvent(event: NSEvent) -> Bool {
        var result: Bool = false
        if draggingSourceDelegate != nil {
            let hitIndex = _hitIndexForEvent(event)
            if let hitIndex = hitIndex {
                if _shouldDragBeginWithEvent(event) {
                    // drag everything if it was hit in a selection
                    if self.selectionIndexes.containsIndex(hitIndex) {
                        result = _startDraggingSessionWithEvent(event, indexes: self.selectionIndexes, hitIndex: hitIndex)
                    } else {
                        // drag just that one row
                        result = _startDraggingSessionWithEvent(event, indexes: NSIndexSet(index: hitIndex), hitIndex: hitIndex)
                    }
                    
                }
            }
        }
        return result
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if self.acceptsFirstResponder {
            self.window?.makeFirstResponder(self)
        }
        
        // First, try to drag
        if _attemptDragWithEvent(theEvent) {
            return;
        }
        
        _shouldUpdateAnchorRow = false
        
        self.window?.trackEventsMatchingMask([NSEventMask.LeftMouseDraggedMask, NSEventMask.LeftMouseUpMask], timeout: NSEventDurationForever, mode: NSEventTrackingRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
        
            self._processMouseEvent(theEvent)
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
    
    override func selectAll(sender: AnyObject?) {
        self.selectionIndexes = NSIndexSet(indexesInRange: NSRange(location: 0, length: self.numberOfItems))
    }
    
    override func keyDown(theEvent: NSEvent) {
        var callSuper = false
        let shiftIsDown = theEvent.modifierFlags.contains(NSEventModifierFlags.ShiftKeyMask);

        switch theEvent.character {
        case NSRightArrowFunctionKey:
            _selectNextIndexFromAnchorExtending(shiftIsDown, goingForward: true)
        case NSLeftArrowFunctionKey:
            _selectNextIndexFromAnchorExtending(shiftIsDown, goingForward: false)
        case NSDeleteCharacter:
            if self.selectionIndexes.count > 0 {
                NSApp.sendAction("delete:", to: nil, from: self)
            }
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
    
    var draggingSourceDelegate: CDTimelineViewDraggingSourceDelegate?
    
    
    // MARK: NSDraggingSource protocol implementation
    func draggingSession(session: NSDraggingSession, sourceOperationMaskForDraggingContext context: NSDraggingContext) -> NSDragOperation {
        // TODO: move to delegate when needed
        if context == NSDraggingContext.WithinApplication {
            return NSDragOperation.Every
        } else {
            // TODO: maybe allow dropping images on it??
            return NSDragOperation.None
        }
    }
    
    var draggedIndexes: NSIndexSet? // non nil when we are dragging
    
    private func _fadeDraggedIndexesToValue(value: CGFloat) {
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
    
    func draggingSession(session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint) {
        if let draggingSourceDelegate = draggingSourceDelegate {
            draggingSourceDelegate.timelineView(self, draggingSession: session, willBeginAtPoint: screenPoint, forIndexes: self.draggedIndexes!)
        }
        _fadeDraggedIndexesToValue(0.5)
    }

    func draggingSession(session: NSDraggingSession, movedToPoint screenPoint: NSPoint) {
        
    }
    
    func draggingSession(session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
        if let draggingSourceDelegate = draggingSourceDelegate {
            draggingSourceDelegate.timelineView(self, draggingSession: session, endedAtPoint: screenPoint, operation: operation)
        }
        _fadeDraggedIndexesToValue(1.0)
        // drop the indexes at this point
        self.draggedIndexes = nil
    }
    
    func ignoreModifierKeysForDraggingSession(session: NSDraggingSession) -> Bool {
        return false
    }
    
    private func _makeDraggingInsertionViewWithFrame(frame: NSRect) -> NSView {
        let result = NSView(frame: frame)
        result.wantsLayer = true
        result.layer!.backgroundColor = CDTimelineView.draggingInsertionColor.CGColor
        result.layerContentsRedrawPolicy = .Never
        return result
    }
    
    private let _insertionDividerWidth: CGFloat = 2.0
    private func _draggingInsertionViewFrameForIndex(index: Int) -> NSRect {
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
    
    private var _draggingInsertionPointView: NSView?
    private func _updateDraggingInsertionPointView() {
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
    

    var draggingDestinationDelegate: CDTimelineViewDraggingDestinationDelegate?
    
    var draggingInsertIndex: Int?  {
        didSet {
            // Add a view for the insertion point
            _updateDraggingInsertionPointView()
        }
    }
    
    private func _updateDraggingDestinationState(draggingInfo: NSDraggingInfo) -> NSDragOperation {
        let point = self.convertPoint(draggingInfo.draggingLocation(), fromView: nil)
        var result = NSDragOperation.None
        var otherIndexToTry: Int?
        if let viewAtPoint = self.hitTest(point) {
            if viewAtPoint == self {
                // If we didn't hit a child view and instead hit us, find out where in us we are for th einsert
                // First, none check
                if self.views.count == 0 {
                    self.draggingInsertIndex = 0
                    result = NSDragOperation.Every
                } else {
                    // Make sure we are before or after the first view, and not above another one..which isn't going to work
                    if point.x <= NSMinX(self.views[0].frame) {
                        self.draggingInsertIndex = 0
                        result = NSDragOperation.Every
                    } else if point.x >= NSMaxX(self.views.last!.frame) {
                        self.draggingInsertIndex = self.views.count // Past it
                        result = NSDragOperation.Every
                    }
                }
                
            } else if let hitIndex = indexOfView(viewAtPoint) {
                // Find out what view we hit and how far we are in it in order to do an insert before or after it.
                let hitView = self.views[hitIndex]
                let pointInHitView = hitView.convertPoint(draggingInfo.draggingLocation(), fromView: nil)
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
                result = NSDragOperation.Every
            } else {
                // Hit something else? what???
            }
        }
        
        // Filter through the delegate
        if let d = self.draggingDestinationDelegate {
            result = d.timelineView(self, updateDraggingInfo: draggingInfo, insertionIndex: self.draggingInsertIndex)
            // If the delegate doesn't accept, implicitlely clear the drop point
            if result == .None {
                // If we have another index, try again..
                if let otherIndexToTry = otherIndexToTry {
                    self.draggingInsertIndex = otherIndexToTry
                    result = d.timelineView(self, updateDraggingInfo: draggingInfo, insertionIndex: self.draggingInsertIndex)
                }
                
                if result == .None {
                    self.draggingInsertIndex = nil
                }
            }
        }
        
        return result
        
    }
    
    private func _clearDraggingDestinationState() {
        self.draggingInsertIndex = nil
    }
    
    // MARK: NSDraggingDestination protocol implementation..
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return _updateDraggingDestinationState(sender)
    }
    
    override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        return _updateDraggingDestinationState(sender)
    }
    
    override func draggingExited(sender: NSDraggingInfo?) {
        _clearDraggingDestinationState()
    }
    
    override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        // I don't think we need a _updateDraggingDestinationState(sender) call..
        if let d = self.draggingDestinationDelegate {
            if d.timelineView(self, performDragOperation: sender, insertionIndex: self.draggingInsertIndex) {
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
    
    override func concludeDragOperation(sender: NSDraggingInfo?) {
        _clearDraggingDestinationState()
    }
//    func draggingEnded(sender: NSDraggingInfo?) {
//        
//    }
    override func wantsPeriodicDraggingUpdates() -> Bool {
        return true
    }

    
}

