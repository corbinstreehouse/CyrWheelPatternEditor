//
//  CDEditorCyrWheelViewController
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/8/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa


// Basically was CDWheelPreviewViewController
class CDEditorCyrWheelViewController: NSViewController {

    @IBOutlet weak var _cyrWheelView: CDCyrWheelView!
    @IBOutlet weak var _playButton: CDRolloverButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // required
        let provider = self.patternSequenceProvider!
        provider.patternRunner.setCyrWheelView(_cyrWheelView);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("_wheelStateChanged:"), name: CDPatternRunnerStateChangedNotificationName, object: provider.patternRunner)
        _updateButtons()
    }
    
    private func _updateButtons() {
        if (_patternRunner!.paused) {
            _playButton.image = NSImage(named: "play")
        } else {
            _playButton.image = NSImage(named: "pause")
        }
    }
    
    @objc func _wheelStateChanged(note: NSNotification) {
        _updateButtons()
    }
    
    private var _patternRunner: CDPatternRunner? {
        return self.patternSequenceProvider?.patternRunner
    }
    
    @IBAction func btnFirstClicked(sender: NSButton) {
        _patternRunner?.moveToTheStart()
    }
    
    @IBAction func btnPriorClicked(sender: NSButton) {
        _patternRunner?.rewind();
    }
    
    @IBAction func btnPlayPauseClicked(sender: NSButton) {
        if let patternRunner = _patternRunner {
            if patternRunner.paused {
                patternRunner.play()
            } else {
                patternRunner.pause()
            }
        }
    }
    
    @IBAction func btnNextClicked(sender: NSButton) {
        _patternRunner?.nextPatternItem()
    }
    
    @IBAction func btnEndClicked(sender: NSButton) {
        _patternRunner?.moveToTheStart()
    }


}

