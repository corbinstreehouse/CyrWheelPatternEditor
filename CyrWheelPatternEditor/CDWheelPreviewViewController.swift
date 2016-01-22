//
//  CDWheelPreviewViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDWheelPreviewViewController: NSViewController, CDPatternSequencePresenter, CDPatternSequenceChildrenDelegate {

    private var _childrenObserver: CDPatternSequenceChildrenObserver?
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
    
    var patternSequence: CDPatternSequence! {
        didSet {
            // Load the sequence and start watching for changes.
            _childrenObserver = CDPatternSequenceChildrenObserver(patternSequence: patternSequence, delegate: self)
        }
    }
    
    private func _reloadSequence() {
//        _patternRunner.pause()
        
        
        
    }

    // MARK: CDPatternSequenceChildrenObserver delegate methods
    func childrenAllChanged() {
        _reloadSequence()
    }
    
    func childrenInsertedAtIndexes(indexes: NSIndexSet) {
        _reloadSequence();
    }
    
    func childrenRemovedAtIndexes(indexes: NSIndexSet) {
        _reloadSequence()
    }
    func childrenReplacedAtIndexes(indexes: NSIndexSet) {
        _reloadSequence()
    }
    // MARK: Delegate end

    
}
