//
//  CDWheelPreviewViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

// Descend from CDPatternSequencePresenterViewController?
class CDWheelPreviewViewController: NSViewController, CDPatternSequencePresenter {

//    private var _childrenObserver: CDPatternSequenceChildrenObserver?
    private var _patternRunner: CDPatternRunner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = NSApp.delegate as! CDAppDelegate
        _patternRunner = CDPatternRunner(patternDirectoryURL: delegate.patternDirectoryURL)
        _patternRunner.setCyrWheelView(_cyrWheelView)
        _reloadSequence()
    }

    @IBOutlet weak var _cyrWheelView: CDCyrWheelView!
    
    @IBAction func btnFirstClicked(sender: NSButton) {
        _patternRunner.moveToTheStart()
    }
    
    @IBAction func btnPriorClicked(sender: NSButton) {
        _patternRunner.priorPatternItem();
    }
    
    @IBAction func btnPlayPauseClicked(sender: NSButton) {
        if _patternRunner.paused {
            _patternRunner.play()
        } else {
            _patternRunner.pause()
        }
    }
    
    @IBAction func btnNextClicked(sender: NSButton) {
        _patternRunner.nextPatternItem()
    }
    
    @IBAction func btnEndClicked(sender: NSButton) {
        _patternRunner.moveToTheStart()
    }
    
    func _startObservingChanges() {
        
        let context: NSManagedObjectContext = self.patternSequenceProvider!.managedObjectContext
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: context, queue: nil) { note in
            
            /*
            if let updated = note.userInfo?[NSUpdatedObjectsKey] where updated.count > 0 {
                print("updated: \(updated)")
            }
            
            if let deleted = note.userInfo?[NSDeletedObjectsKey] where deleted.count > 0 {
                print("deleted: \(deleted)")
            }
            
            if let inserted = note.userInfo?[NSInsertedObjectsKey] where inserted.count > 0 {
                print("inserted: \(inserted)")
            }
            if let inserted = note.userInfo?[NSRefreshedObjectsKey] where inserted.count > 0 {
                print("inserted: \(inserted)")
            }
            if let inserted = note.userInfo?[NSInvalidatedObjectsKey] where inserted.count > 0 {
                print("inserted: \(inserted)")
            }
            */
            self._reloadSequence()
        }
    }
    
    var patternSequence: CDPatternSequence! {
        didSet {
            // Load the sequence and start watching for changes.
//            _childrenObserver = CDPatternSequenceChildrenObserver(patternSequence: patternSequence, delegate: self) // not needed..
            _startObservingChanges()
            _reloadSequence()
        }
    }
    
    private func _reloadSequence() {
        if let validSequence = self.patternSequence {
            let data = validSequence.exportAsData()
            _patternRunner.loadFromData(data)
        }
    }

    // MARK: CDPatternSequenceChildrenObserver delegate methods
//    func childrenAllChanged() {
//        _reloadSequence()
//    }
//    
//    func childrenInsertedAtIndexes(indexes: NSIndexSet) {
//        _reloadSequence();
//    }
//    
//    func childrenRemovedAtIndexes(indexes: NSIndexSet) {
//        _reloadSequence()
//    }
//    func childrenReplacedAtIndexes(indexes: NSIndexSet) {
//        _reloadSequence()
//    }
    // MARK: Delegate end

    
}
