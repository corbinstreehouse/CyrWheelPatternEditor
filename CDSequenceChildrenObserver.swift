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
    
    func childrenInsertedAtIndexes(_ indexes: IndexSet);
    func childrenRemovedAtIndexes(_ indexes: IndexSet);
    func childrenReplacedAtIndexes(_ indexes: IndexSet);
}

class CDPatternSequenceChildrenObserver: NSObject {
    fileprivate var _patternSequence: CDPatternSequence!
    
    init(patternSequence: CDPatternSequence, delegate: CDPatternSequenceChildrenDelegate) {
        super.init()
        _patternSequence = patternSequence
        _patternSequence.addObserver(self, forKeyPath: CDPatternChildrenKey, options: [], context: nil)
        _delegate = delegate
    }
    
    deinit {
        _patternSequence.removeObserver(self, forKeyPath: CDPatternChildrenKey)
    }
    
    fileprivate var _delegate: CDPatternSequenceChildrenDelegate!
    
    fileprivate func childrenAllChanged() {
        _delegate.childrenAllChanged()
    }
    
    fileprivate func childrenInsertedAtIndexes(_ indexes: IndexSet) {
        _delegate.childrenInsertedAtIndexes(indexes)
    }
    
    fileprivate func childrenRemovedAtIndexes(_ indexes: IndexSet) {
        _delegate.childrenRemovedAtIndexes(indexes)
    }
    
    fileprivate func childrenReplacedAtIndexes(_ indexes: IndexSet) {
        _delegate.childrenReplacedAtIndexes(indexes)
    }
    
    fileprivate func _childrenChanged(_ change: [NSKeyValueChangeKey : Any]) {
        if let changeKindInt = change[NSKeyValueChangeKey.kindKey] as? UInt  {
            let changeKind: NSKeyValueChange = NSKeyValueChange(rawValue: changeKindInt)!
            switch (changeKind) {
            case NSKeyValueChange.setting:
                childrenAllChanged()
            case NSKeyValueChange.insertion:
                if let indexes = change[NSKeyValueChangeKey.indexesKey] as? IndexSet {
                    childrenInsertedAtIndexes(indexes)
                } else {
                    childrenAllChanged()
                }
            case NSKeyValueChange.removal:
                if let indexes = change[NSKeyValueChangeKey.indexesKey] as? IndexSet {
                    childrenRemovedAtIndexes(indexes)
                } else {
                    childrenAllChanged()
                }
            case NSKeyValueChange.replacement:
                if let indexes = change[NSKeyValueChangeKey.indexesKey] as? IndexSet {
                    childrenReplacedAtIndexes(indexes)
                } else {
                    childrenAllChanged()
                }
            }
        } else {
            childrenAllChanged()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
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
