//
//  CDWheelPreviewViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa


// corbin note: I'm now not really using anything in this class to do anything except link the runner with other stuff. something else should own the runner in the bluetooth preview controller use of this
class CDWheelPreviewViewController: NSViewController {

    fileprivate var _patternRunner: CDPatternRunner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = NSApp.delegate as! CDAppDelegate
        _patternRunner = CDPatternRunner(patternDirectoryURL: delegate.patternDirectoryURL as URL)
        _patternRunner.setCyrWheelView(_cyrWheelView)
    }

    var patternRunner: CDPatternRunner {
        get {
            return _patternRunner;
        }
    }

    @IBOutlet weak var _cyrWheelView: CDCyrWheelView!
    
}
