//
//  CDTimelineTrackViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/29/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

// patternSequenceProvider

class CDTimelineTrackViewController: NSViewController, CDPatternSequenceChildrenDelegate, CDTimelineTrackViewDataSource, CDPatternSequencePresenter, CDTimelineTrackViewDraggingSourceDelegate, CDTimelineTrackViewDraggingDestinationDelegate {

    @IBOutlet weak var _timelineTrackView: CDTimelineTrackView!
    @IBOutlet weak var _musicTrackView: CDTimelineTrackView!
    @IBOutlet weak var _playheadView: CDPlayheadView!
    @IBOutlet weak var _timelineView: CDTimelineView!

    private var _childrenObserver: CDPatternSequenceChildrenObserver?;

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
    
    func delete(sender: AnyObject?) {
        let selection = self._timelineTrackView.selectionIndexes
        if selection.count > 0 {
            // Select the next item first (selection is maintained automatically)
            let lastIndex = selection.lastIndex + 1
            if lastIndex < _timelineTrackView.numberOfItems {
                _timelineTrackView.selectionIndexes = NSIndexSet(index: lastIndex)
            }
            self.patternSequence.removeChildrenAtIndexes(selection)
        }
        
    }
    
    private let _patternItemPBoardType = CDPatternItem.pasteboardType()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ONly hook this up when we have data to provide
        if self.patternSequence != nil {
            _timelineTrackView.dataSource = self
        }
        _timelineView.playheadView = _playheadView;
        _timelineTrackView.registerForDraggedTypes([_patternItemPBoardType])
    }
    
    override func viewWillAppear() {
        let sequenceProvider: CDPatternSequenceProvider = self.patternSequenceProvider!;
        sequenceProvider.patternRunner.addObserver(self, forKeyPath: CDPatternRunnerPlayheadTimePositionKey, options: [], context: nil)
        
        let parentVC = sequenceProvider as! NSObject
        // Bind the parent to our value
        // TODO: unbind when done!
        parentVC.bind("patternSelectionIndexes", toObject: _timelineTrackView, withKeyPath: "selectionIndexes", options: nil)
    }
    
    private func _updatePlayheadViewPosition() {
        _timelineView.playheadTimePosition = self.patternSequenceProvider!.patternRunner.playheadTimePosition
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == CDPatternRunnerPlayheadTimePositionKey {
            _updatePlayheadViewPosition();
        } else {
            assert(false, "bad observation")
        }
    }
    
    func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
        if anItem.action() == Selector("copy:") || anItem.action() == Selector("cut:") {
            return _timelineTrackView.selectionIndexes.count > 0
        } else if anItem.action() == Selector("paste:") {
            let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
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
    
    @IBAction func copy(sender: AnyObject) {
        if _timelineTrackView.selectionIndexes.count > 0 {
            let data: NSData = _dataForItemsAtIndexes(_timelineTrackView.selectionIndexes)
            let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
            pasteboard.clearContents()
            pasteboard.declareTypes([_patternItemPBoardType], owner: self)
            pasteboard.setData(data, forType: _patternItemPBoardType)
        }
    }
    
    @IBAction func paste(sender: AnyObject) {
        let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
        if let data = pasteboard.dataForType(_patternItemPBoardType) {
            let index = _timelineTrackView.selectionIndexes.count > 0 ? _timelineTrackView.selectionIndexes.lastIndex + 1 : _timelineTrackView.numberOfItems;
            _insertItemsWithData(data, atStartingIndex: index)
        }
    }
    
    @IBAction func cut(sender: AnyObject) {
        if _timelineTrackView.selectionIndexes.count > 0 {
            self.copy(sender)
            self.delete(sender)
        }
    }
    
    func _dataForItemsAtIndexes(indexes: NSIndexSet) -> NSData {
        let selectedChildren: [AnyObject] = self.patternSequence.children.objectsAtIndexes(indexes)
        let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(selectedChildren)
        return data
    }
    
    func _insertItemsWithData(data: NSData, atStartingIndex index:Int) {
        let patternSequenceProvider = self.patternSequenceProvider
        // The unachiver uses this context in initWithCoder:
        CDPatternItem.setCurrentContext(patternSequenceProvider!.managedObjectContext)
        if let newItems = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [CDPatternItem] {
            let targetIndexes = NSIndexSet(indexesInRange: NSRange(location: index, length: newItems.count))
            patternSequence.insertChildren(newItems, atIndexes: targetIndexes)
        } else {
            // Failure message?
            NSLog("Failed to insert items from data: %@", data)
        }
        CDPatternItem.setCurrentContext(nil)
    }
    
    func childrenAllChanged() {
        _timelineTrackView.reloadData()
    }
    
    func childrenInsertedAtIndexes(indexes: NSIndexSet) {
        indexes.enumerateIndexesUsingBlock { (index:Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            self._timelineTrackView.insertItemAtIndex(index)
        }
        // Show new items added a the end
        let lastIndex = indexes.lastIndex
        if lastIndex == self._timelineTrackView.numberOfItems - 1 {
            self._timelineTrackView.scrollItemAtIndexToVisible(lastIndex)
        }
    }
    
    func childrenRemovedAtIndexes(indexes: NSIndexSet) {
        self._timelineTrackView.removeItemsAtIndexes(indexes);
    }
    
    func childrenReplacedAtIndexes(indexes: NSIndexSet) {
        childrenRemovedAtIndexes(indexes)
        childrenInsertedAtIndexes(indexes)
    }
    
    func numberOfItemsInTimelineTrackView(timelineTrackView: CDTimelineTrackView) -> Int {
        if self.patternSequence.children != nil {
            return self.patternSequence.children.count
        } else {
            return 0
        }
    }
    
    func timelineTrackView(timelineTrackView: CDTimelineTrackView, itemAtIndex index: Int) -> CDTimelineItem {
        return self.patternSequence.children[index] as! CDTimelineItem
    }
    
    func timelineTrackView(timelineTrackView: CDTimelineTrackView, makeViewControllerAtIndex index: Int) -> NSViewController {
        let mainStoryboard: NSStoryboard = (NSApp.delegate as! CDAppDelegate).mainStoryboard
        let result = mainStoryboard.instantiateControllerWithIdentifier("TimelineItemView") as! NSViewController
        result.representedObject = self.patternSequence.children[index]
        return result
    }
    

    func timelineTrackView(timelineTrackView: CDTimelineTrackView, pasteboardWriterForIndex index: Int) -> NSPasteboardWriting? {
        let item = self.patternSequence.children[index] as! CDPatternItem
        return item
    }
    
    func timelineTrackView(timelineTrackView: CDTimelineTrackView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forIndexes indexes: NSIndexSet) {
        
    }
    
    func timelineTrackView(timelineTrackView: CDTimelineTrackView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
        
    }
    
    // Dragging destination
    func timelineTrackView(timelineTrackView: CDTimelineTrackView, updateDraggingInfo info: NSDraggingInfo, insertionIndex: Int?) -> NSDragOperation {
        guard let index = insertionIndex else { return .None }
        // If we are the source, then don't allow a move before or after the index being dragged (it doesn't make sense), unless it is a copy
        let sourceAsTV = info.draggingSource() as? CDTimelineTrackView
        if sourceAsTV == timelineTrackView {
            if info.draggingSourceOperationMask() == .Copy {
                return .Copy
            } else {
                // We can only move if we aren't moving before or after a dragged index
                if let draggedIndexes = timelineTrackView.draggedIndexes {
                    if draggedIndexes.containsIndex(index) || draggedIndexes.containsIndex(index-1) {
                        return .None
                    } else {
                        return .Move
                    }
                } else {
                    return .None; // bad?
                }
            }
        } else {
            // other inserts as a copy if we have the right type
            if let types = info.draggingPasteboard().types {
                if types.contains(_patternItemPBoardType) {
                    return .Copy
                }
            }
        }
        return .None
    }
    
    func timelineTrackView(timelineTrackView: CDTimelineTrackView, performDragOperation info: NSDraggingInfo, insertionIndex: Int?) -> Bool {
        guard let insertionIndex = insertionIndex else { return false }
        
        // Do it!
        // TODO: begin updates/endupdates and animations.. and animate the drop target..
        let sourceAsTV = info.draggingSource() as? CDTimelineTrackView
        if sourceAsTV == timelineTrackView {
            let draggedIndexes = _timelineTrackView.draggedIndexes!
            if info.draggingSourceOperationMask() == .Copy {
                let data: NSData = _dataForItemsAtIndexes(draggedIndexes)
                _insertItemsWithData(data, atStartingIndex: insertionIndex)
            } else {
                let shouldSelectItems: Bool = draggedIndexes.isEqualToIndexSet(timelineTrackView.selectionIndexes)
                
                let childrenToMove: [CDPatternItem] = patternSequence.children.objectsAtIndexes(draggedIndexes) as! [CDPatternItem]
                
                patternSequence.removeChildrenAtIndexes(draggedIndexes)
                let targetIndexes: NSMutableIndexSet = NSMutableIndexSet()
                
                let modifiedStartingRow: Int = insertionIndex - draggedIndexes.countOfIndexesInRange(NSRange(location: 0, length: insertionIndex))
                for var r = modifiedStartingRow; r < modifiedStartingRow + childrenToMove.count; r++ {
                    targetIndexes.addIndex(r)
                }
                patternSequence.insertChildren(childrenToMove, atIndexes: targetIndexes)
                
                if shouldSelectItems {
                    timelineTrackView.selectionIndexes = targetIndexes
                }
            }
        } else {
            CDPatternItem.setCurrentContext(patternSequenceProvider!.managedObjectContext)
            var childIndex = UInt(insertionIndex)
            info.enumerateDraggingItemsWithOptions([], forView: timelineTrackView, classes: [CDPatternItem.self], searchOptions: [:], usingBlock: { (item: NSDraggingItem, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let patternItem = item.item as! CDPatternItem
                self.patternSequence.insertObject(patternItem, inChildrenAtIndex: childIndex)
                childIndex++
            })
            CDPatternItem.setCurrentContext(nil)
        }
        return true
    }
}
