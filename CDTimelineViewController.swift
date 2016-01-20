//
//  CDTimelineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/29/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDTimelineViewController: NSViewController, CDPatternSequenceChildrenDelegate, CDTimelineViewDataSource, CDPatternSequencePresenter {

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
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ONly hook this up when we have data to provide
        if self.patternSequence != nil {
            _timelineView.dataSource = self
        }

//        let parentVC = self.patternSequenceProvider as! NSObject
//        // Bind the parent to our value
//        // TODO: unbind when done!
//        parentVC.bind("patternSelectionIndexes", toObject: _timelineView, withKeyPath: "selectionIndexes", options: nil)
    }
    
    override func viewWillAppear() {
        let parentVC = self.patternSequenceProvider as! NSObject
        // Bind the parent to our value
        // TODO: unbind when done!
        parentVC.bind("patternSelectionIndexes", toObject: _timelineView, withKeyPath: "selectionIndexes", options: nil)
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
    
    
}
