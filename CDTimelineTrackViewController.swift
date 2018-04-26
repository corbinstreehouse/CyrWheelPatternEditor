//
//  CDTimelineTrackViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/29/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDTimelineTrackViewController: NSViewController, CDPatternSequenceChildrenDelegate, CDTimelineTrackViewDataSource, CDPatternSequencePresenter, CDTimelineTrackViewDraggingSourceDelegate, CDTimelineTrackViewDraggingDestinationDelegate {
    
    // ivars
    fileprivate var _wasPausedBeforeTimelineDragging = false
    fileprivate var _childrenObserver: CDPatternSequenceChildrenObserver?
    fileprivate let _patternItemPBoardType = CDPatternItem.pasteboardType()

    // outlets/ivars
    @IBOutlet weak var _timelineTrackView: CDTimelineTrackView!
    @IBOutlet weak var _musicTrackView: CDTimelineTrackView!
    @IBOutlet weak var _playheadView: CDPlayheadView!
    @IBOutlet weak var _timelineView: CDTimelineView! {
        didSet {
            _timelineView?.delegate = self
        }
    }

    internal var patternSequence: CDPatternSequence! {
        willSet {
            _childrenObserver = nil
        }
        didSet {
            if let patternSequence = self.patternSequence {
                _childrenObserver = CDPatternSequenceChildrenObserver(patternSequence: patternSequence, delegate: self)
                _timelineTrackView.dataSource = self
                _timelineTrackView.draggingSourceDelegate = self
                _timelineTrackView.draggingDestinationDelegate = self;
                _updatePlayheadViewPosition();
            }
        }
    }
    
    func delete(_ sender: AnyObject?) {
        let selection = self._timelineTrackView.selectionIndexes
        if let lastIndex = selection.last {
            // Select the next item first (selection is maintained automatically)
            let nextIndex = lastIndex + 1
            if nextIndex < _timelineTrackView.numberOfItems {
                _timelineTrackView.selectionIndexes = IndexSet(integer: nextIndex)
            }
            self.patternSequence.removeChildren(at: selection as IndexSet)
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ONly hook this up when we have data to provide
        if self.patternSequence != nil {
            _timelineTrackView.dataSource = self
        }
        _timelineView.playheadView = _playheadView;
        _timelineTrackView.register(forDraggedTypes: [_patternItemPBoardType])
    }
    
    override func viewWillAppear() {
        let sequenceProvider: CDPatternSequenceProvider = self.patternSequenceProvider!;
        sequenceProvider.patternRunner.addObserver(self, forKeyPath: CDPatternRunnerPlayheadTimePositionKey, options: [], context: nil)
        
        let parentVC = sequenceProvider as! NSObject
        // Bind the parent to our value
        // TODO: unbind when done!
        parentVC.bind("patternSelectionIndexes", to: _timelineTrackView, withKeyPath: "selectionIndexes", options: nil)
    }
    
    fileprivate func _updatePlayheadViewPosition() {
        _timelineView.playheadTimePosition = self.patternSequenceProvider!.patternRunner.playheadTimePosition
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == CDPatternRunnerPlayheadTimePositionKey {
            _updatePlayheadViewPosition();
        } else {
            assert(false, "bad observation")
        }
    }
    
    func validateUserInterfaceItem(_ anItem: NSValidatedUserInterfaceItem) -> Bool {
        if anItem.action == #selector(CDTimelineTrackViewController.copy(_:)) || anItem.action == #selector(CDTimelineTrackViewController.cut(_:)) {
            return _timelineTrackView.selectionIndexes.count > 0
        } else if anItem.action == #selector(CDTimelineTrackViewController.paste(_:)) {
            let pasteboard: NSPasteboard = NSPasteboard.general()
            if let types = pasteboard.types {
                if types.contains(_patternItemPBoardType) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    @IBAction func copy(_ sender: AnyObject) {
        if _timelineTrackView.selectionIndexes.count > 0 {
            let data: Data = _dataForItemsAtIndexes(_timelineTrackView.selectionIndexes as IndexSet)
            let pasteboard: NSPasteboard = NSPasteboard.general()
            pasteboard.clearContents()
            pasteboard.declareTypes([_patternItemPBoardType], owner: self)
            pasteboard.setData(data, forType: _patternItemPBoardType)
        }
    }
    
    @IBAction func paste(_ sender: AnyObject) {
        let pasteboard: NSPasteboard = NSPasteboard.general()
        if let data = pasteboard.data(forType: _patternItemPBoardType) {
            let index = _timelineTrackView.selectionIndexes.last != nil ? _timelineTrackView.selectionIndexes.last! + 1 : _timelineTrackView.numberOfItems;
            _insertItemsWithData(data, atStartingIndex: index)
        }
    }
    
    @IBAction func cut(_ sender: AnyObject) {
        if _timelineTrackView.selectionIndexes.count > 0 {
            self.copy(sender)
            self.delete(sender)
        }
    }
    
    func _dataForItemsAtIndexes(_ indexes: IndexSet) -> Data {
        let selectedChildren: [AnyObject] = self.patternSequence.children!.objects(at: indexes) as [AnyObject]
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: selectedChildren)
        return data
    }
    
    func _insertItemsWithData(_ data: Data, atStartingIndex index:Int) {
        let patternSequenceProvider = self.patternSequenceProvider
        // The unachiver uses this context in initWithCoder:
        CDPatternItem.setCurrentContext(patternSequenceProvider!.managedObjectContext)
        if let newItems = NSKeyedUnarchiver.unarchiveObject(with: data) as? [CDPatternItem] {
            let targetIndexes = IndexSet(integersIn: NSRange(location: index, length: newItems.count).toRange() ?? 0..<0)
            patternSequence.insertChildren(newItems, at: targetIndexes)
        } else {
            // Failure message?
            print("Failed to insert items from data:\(data)")
        }
        CDPatternItem.setCurrentContext(nil)
    }
    
    func childrenAllChanged() {
        _timelineTrackView.reloadData()
    }
    
    func childrenInsertedAtIndexes(_ indexes: IndexSet) {
        for index in indexes {
            self._timelineTrackView.insertItemAtIndex(index)
        }
        // Show new items added a the end
        if let lastIndex = indexes.last {
            if lastIndex == self._timelineTrackView.numberOfItems - 1 {
                self._timelineTrackView.scrollItemAtIndexToVisible(lastIndex)
            }
        }
    }
    
    func childrenRemovedAtIndexes(_ indexes: IndexSet) {
        self._timelineTrackView.removeItemsAtIndexes(indexes);
    }
    
    func childrenReplacedAtIndexes(_ indexes: IndexSet) {
        childrenRemovedAtIndexes(indexes)
        childrenInsertedAtIndexes(indexes)
    }
    
    func numberOfItemsInTimelineTrackView(_ timelineTrackView: CDTimelineTrackView) -> Int {
        if let children = self.patternSequence.children {
            return children.count
        } else {
            return 0
        }
    }
    
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, itemAtIndex index: Int) -> CDTimelineItem {
        return self.patternSequence.children![index] as! CDTimelineItem
    }
    
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, makeViewControllerAtIndex index: Int) -> NSViewController {
        let mainStoryboard: NSStoryboard = (NSApp.delegate as! CDAppDelegate).mainStoryboard
        let result = mainStoryboard.instantiateController(withIdentifier: "TimelineItemView") as! NSViewController
        result.representedObject = self.patternSequence.children![index]
        return result
    }
    

    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, pasteboardWriterForIndex index: Int) -> NSPasteboardWriting? {
        let item = self.patternSequence.children![index] as! CDPatternItem
        return item
    }
    
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forIndexes indexes: IndexSet) {
        
    }
    
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
        
    }
    
    // Dragging destination
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, updateDraggingInfo info: NSDraggingInfo, insertionIndex: Int?) -> NSDragOperation {
        guard let index = insertionIndex else { return NSDragOperation() }
        // If we are the source, then don't allow a move before or after the index being dragged (it doesn't make sense), unless it is a copy
        let sourceAsTV = info.draggingSource() as? CDTimelineTrackView
        if sourceAsTV == timelineTrackView {
            if info.draggingSourceOperationMask() == .copy {
                return .copy
            } else {
                // We can only move if we aren't moving before or after a dragged index
                if let draggedIndexes = timelineTrackView.draggedIndexes {
                    if draggedIndexes.contains(index) || draggedIndexes.contains(index-1) {
                        return NSDragOperation()
                    } else {
                        return .move
                    }
                } else {
                    return NSDragOperation(); // bad?
                }
            }
        } else {
            // other inserts as a copy if we have the right type
            if let types = info.draggingPasteboard().types {
                if types.contains(_patternItemPBoardType) {
                    return .copy
                }
            }
        }
        return NSDragOperation()
    }
    
    func timelineTrackView(_ timelineTrackView: CDTimelineTrackView, performDragOperation info: NSDraggingInfo, insertionIndex: Int?) -> Bool {
        guard let insertionIndex = insertionIndex else { return false }
        
        // Do it!
        // TODO: begin updates/endupdates and animations.. and animate the drop target..
        let sourceAsTV = info.draggingSource() as? CDTimelineTrackView
        if sourceAsTV == timelineTrackView {
            let draggedIndexes = _timelineTrackView.draggedIndexes!
            if info.draggingSourceOperationMask() == .copy {
                let data: Data = _dataForItemsAtIndexes(draggedIndexes as IndexSet)
                _insertItemsWithData(data, atStartingIndex: insertionIndex)
            } else {
                let shouldSelectItems: Bool = draggedIndexes == timelineTrackView.selectionIndexes
                
                let childrenToMove: [CDPatternItem] = patternSequence.children!.objects(at: draggedIndexes as IndexSet) as! [CDPatternItem]
                
                patternSequence.removeChildren(at: draggedIndexes as IndexSet)
                var targetIndexes = IndexSet()
                
                let modifiedStartingRow: Int = insertionIndex - draggedIndexes.count(in: NSRange(location: 0, length: insertionIndex).toRange() ?? 0..<0)
                for r in modifiedStartingRow ..< modifiedStartingRow + childrenToMove.count {
                    targetIndexes.insert(r)
                }
                patternSequence.insertChildren(childrenToMove, at: targetIndexes)
                
                if shouldSelectItems {
                    timelineTrackView.selectionIndexes = targetIndexes
                }
            }
        } else {
            CDPatternItem.setCurrentContext(patternSequenceProvider!.managedObjectContext)
            var childIndex = UInt(insertionIndex)
            info.enumerateDraggingItems(options: [], for: timelineTrackView, classes: [CDPatternItem.self], searchOptions: [:], using: { (item: NSDraggingItem, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let patternItem = item.item as! CDPatternItem
                self.patternSequence.insertObject(patternItem, inChildrenAt: childIndex)
                childIndex += 1
            })
            CDPatternItem.setCurrentContext(nil)
        }
        return true
    }
}

extension CDTimelineTrackViewController: CDTimelineViewDelegate {
    
    func timelineViewChanged(_ reason: CDTimelineViewChangeReason) {
        let patternRunner = self.patternSequenceProvider!.patternRunner
        switch (reason) {
        case .playheadTimePositionMoved:
            patternRunner?.playheadTimePosition = _timelineView.playheadTimePosition
        case .playheadTimeDraggingStarted:
            _wasPausedBeforeTimelineDragging = (patternRunner?.isPaused)!
            if !_wasPausedBeforeTimelineDragging {
                patternRunner?.pause();
            }
        case .playheadTimeDraggingEnded:
            patternRunner?.playheadTimePosition = _timelineView.playheadTimePosition
            if !_wasPausedBeforeTimelineDragging {
                patternRunner?.play()
            }
        }
        
    }
}

