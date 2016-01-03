//
//  CDSequenceChildrenObserver.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/31/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Foundation

protocol CDPatternSequenceChildrenDelegate {
    func childrenAllChanged();
    
    func childrenInsertedAtIndexes(indexes: NSIndexSet);
    func childrenRemovedAtIndexes(indexes: NSIndexSet);
    func childrenReplacedAtIndexes(indexes: NSIndexSet);
}

class CDPatternSequenceChildrenObserver: NSObject {
    private var _patternSequence: CDPatternSequence!
    
    init(patternSequence: CDPatternSequence, delegate: CDPatternSequenceChildrenDelegate) {
        super.init()
        _patternSequence = patternSequence
        _patternSequence.addObserver(self, forKeyPath: CDPatternChildrenKey, options: [], context: nil)
        _delegate = delegate
    }
    
    deinit {
        _patternSequence.removeObserver(self, forKeyPath: CDPatternChildrenKey)
    }
    
    private var _delegate: CDPatternSequenceChildrenDelegate!
    
    private func childrenAllChanged() {
        _delegate.childrenAllChanged()
    }
    
    private func childrenInsertedAtIndexes(indexes: NSIndexSet) {
        _delegate.childrenInsertedAtIndexes(indexes)
    }
    
    private func childrenRemovedAtIndexes(indexes: NSIndexSet) {
        _delegate.childrenRemovedAtIndexes(indexes)
    }
    
    private func childrenReplacedAtIndexes(indexes: NSIndexSet) {
        _delegate.childrenReplacedAtIndexes(indexes)
    }
    
    private func _childrenChanged(change: [String : AnyObject]) {
        if let changeKindInt = change[NSKeyValueChangeKindKey] as? UInt  {
            let changeKind: NSKeyValueChange = NSKeyValueChange(rawValue: changeKindInt)!
            switch (changeKind) {
            case NSKeyValueChange.Setting:
                childrenAllChanged()
            case NSKeyValueChange.Insertion:
                if let indexes = change[NSKeyValueChangeIndexesKey] as? NSIndexSet {
                    childrenInsertedAtIndexes(indexes)
                } else {
                    childrenAllChanged()
                }
            case NSKeyValueChange.Removal:
                if let indexes = change[NSKeyValueChangeIndexesKey] as? NSIndexSet {
                    childrenRemovedAtIndexes(indexes)
                } else {
                    childrenAllChanged()
                }
            case NSKeyValueChange.Replacement:
                if let indexes = change[NSKeyValueChangeIndexesKey] as? NSIndexSet {
                    childrenReplacedAtIndexes(indexes)
                } else {
                    childrenAllChanged()
                }
            }
        } else {
            childrenAllChanged()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == CDPatternChildrenKey {
            if let change = change {
                self._childrenChanged(change)
            } else {
                self.childrenAllChanged()
            }
        } else {
            assert(false, "bad observation")
        }
    }
    
    
}