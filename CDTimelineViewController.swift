//
//  CDTimelineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/29/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDTimelineViewController: NSViewController, CDPatternSequenceChildrenDelegate, CDTimelineViewDataSource, CDPatternSequencePresenter, CDTimelineViewDraggingSourceDelegate, CDTimelineViewDraggingDestinationDelegate {

    @IBOutlet weak var _timelineView: CDTimelineView!
    
    private var _childrenObserver: CDPatternSequenceChildrenObserver?;

    internal var patternSequence: CDPatternSequence! {
        willSet {
            _childrenObserver = nil
        }
        didSet {
            if let patternSequence = self.patternSequence {
                _childrenObserver = CDPatternSequenceChildrenObserver(patternSequence: patternSequence, delegate: self)
                _timelineView.dataSource = self
                _timelineView.draggingSourceDelegate = self
                _timelineView.draggingDestinationDelegate = self;
            }
        }
    }
    
    func delete(sender: AnyObject?) {
        self.patternSequence.removeChildrenAtIndexes(self._timelineView.selectionIndexes)
    }
    
    private let _patternItemPBoardType = CDPatternItem.pasteboardType()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ONly hook this up when we have data to provide
        if self.patternSequence != nil {
            _timelineView.dataSource = self
        }
        
        _timelineView.registerForDraggedTypes([_patternItemPBoardType])
    }
    
    override func viewWillAppear() {
        let parentVC = self.patternSequenceProvider as! NSObject
        // Bind the parent to our value
        // TODO: unbind when done!
        parentVC.bind("patternSelectionIndexes", toObject: _timelineView, withKeyPath: "selectionIndexes", options: nil)
    }
    
    func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
        if anItem.action() == Selector("copy:") || anItem.action() == Selector("cut:") {
            return _timelineView.selectionIndexes.count > 0
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
        if _timelineView.selectionIndexes.count > 0 {
            let data: NSData = _dataForItemsAtIndexes(_timelineView.selectionIndexes)
            let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
            pasteboard.clearContents()
            pasteboard.declareTypes([_patternItemPBoardType], owner: self)
            pasteboard.setData(data, forType: _patternItemPBoardType)
        }
    }
    
    @IBAction func paste(sender: AnyObject) {
        let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
        if let data = pasteboard.dataForType(_patternItemPBoardType) {
            let index = _timelineView.selectionIndexes.count > 0 ? _timelineView.selectionIndexes.lastIndex + 1 : _timelineView.numberOfItems;
            _insertItemsWithData(data, atStartingIndex: index)
        }
    }
    
    @IBAction func cut(sender: AnyObject) {
        if _timelineView.selectionIndexes.count > 0 {
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
        _timelineView.reloadData()
    }
    
    func childrenInsertedAtIndexes(indexes: NSIndexSet) {
        indexes.enumerateIndexesUsingBlock { (index:Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            self._timelineView.insertItemAtIndex(index)
        }
        // Show new items added a the end
        let lastIndex = indexes.lastIndex
        if lastIndex == self._timelineView.numberOfItems - 1 {
            self._timelineView.scrollItemAtIndexToVisible(lastIndex)
        }
    }
    
    func childrenRemovedAtIndexes(indexes: NSIndexSet) {
        indexes.enumerateIndexesWithOptions([.Reverse]) { (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            self._timelineView.removeItemAtIndex(index)
        }
    }
    
    func childrenReplacedAtIndexes(indexes: NSIndexSet) {
        childrenRemovedAtIndexes(indexes)
        childrenInsertedAtIndexes(indexes)
    }
    
    func numberOfItemsInTimelineView(timelineView: CDTimelineView) -> Int {
        if self.patternSequence.children != nil {
            return self.patternSequence.children.count
        } else {
            return 0
        }
    }
    
    func timelineView(timelineView: CDTimelineView, itemAtIndex index: Int) -> CDTimelineItem {
        return self.patternSequence.children[index] as! CDTimelineItem
    }
    
    func timelineView(timelineView: CDTimelineView, makeViewControllerAtIndex index: Int) -> NSViewController {
        let mainStoryboard: NSStoryboard = (NSApp.delegate as! CDAppDelegate).mainStoryboard
        let result = mainStoryboard.instantiateControllerWithIdentifier("TimelineItemView") as! NSViewController
        result.representedObject = self.patternSequence.children[index]
        return result
    }
    

    func timelineView(timelineView: CDTimelineView, pasteboardWriterForIndex index: Int) -> NSPasteboardWriting? {
        let item = self.patternSequence.children[index] as! CDPatternItem
        return item
    }
    
    func timelineView(timelineView: CDTimelineView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forIndexes indexes: NSIndexSet) {
        
        
        
    }
    
    func timelineView(timelineView: CDTimelineView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
        
    }
    
    // Dragging destination
    func timelineView(timelineView: CDTimelineView, updateDraggingInfo info: NSDraggingInfo, insertionIndex: Int?) -> NSDragOperation {
        guard let index = insertionIndex else { return .None }
        // If we are the source, then don't allow a move before or after the index being dragged (it doesn't make sense), unless it is a copy
        let sourceAsTV = info.draggingSource() as? CDTimelineView
        if sourceAsTV == timelineView {
            if info.draggingSourceOperationMask() == .Copy {
                return .Copy
            } else {
                // We can only move if we aren't moving before or after a dragged index
                if let draggedIndexes = timelineView.draggedIndexes {
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
    
    func timelineView(timelineView: CDTimelineView, performDragOperation info: NSDraggingInfo, insertionIndex: Int?) -> Bool {
        guard let insertionIndex = insertionIndex else { return false }
        
        // Do it!
        // TODO: begin updates/endupdates and animations.. and animate the drop target..
        let sourceAsTV = info.draggingSource() as? CDTimelineView
        if sourceAsTV == timelineView {
            let draggedIndexes = _timelineView.draggedIndexes!
            if info.draggingSourceOperationMask() == .Copy {
                let data: NSData = _dataForItemsAtIndexes(draggedIndexes)
                _insertItemsWithData(data, atStartingIndex: insertionIndex)
            } else {
                let shouldSelectItems: Bool = draggedIndexes.isEqualToIndexSet(timelineView.selectionIndexes)
                
                let childrenToMove: [CDPatternItem] = patternSequence.children.objectsAtIndexes(draggedIndexes) as! [CDPatternItem]
                
                patternSequence.removeChildrenAtIndexes(draggedIndexes)
                let targetIndexes: NSMutableIndexSet = NSMutableIndexSet()
                
                let modifiedStartingRow: Int = insertionIndex - draggedIndexes.countOfIndexesInRange(NSRange(location: 0, length: insertionIndex))
                for var r = modifiedStartingRow; r < modifiedStartingRow + childrenToMove.count; r++ {
                    targetIndexes.addIndex(r)
                }
                patternSequence.insertChildren(childrenToMove, atIndexes: targetIndexes)
                
                if shouldSelectItems {
                    timelineView.selectionIndexes = targetIndexes
                }
            }
        } else {
            CDPatternItem.setCurrentContext(patternSequenceProvider!.managedObjectContext)
            var childIndex = UInt(insertionIndex)
            info.enumerateDraggingItemsWithOptions([], forView: timelineView, classes: [CDPatternItem.self], searchOptions: [:], usingBlock: { (item: NSDraggingItem, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let patternItem = item.item as! CDPatternItem
                self.patternSequence.insertObject(patternItem, inChildrenAtIndex: childIndex)
                childIndex++
            })
            CDPatternItem.setCurrentContext(nil)
        }
        return true
    }
}
