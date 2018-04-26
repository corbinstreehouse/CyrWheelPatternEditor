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
        NotificationCenter.default.addObserver(self, selector: #selector(CDEditorCyrWheelViewController._wheelStateChanged(_:)), name: NSNotification.Name(rawValue: CDPatternRunnerStateChangedNotificationName), object: provider.patternRunner)
        _updateButtons()
    }
    
    fileprivate func _updateButtons() {
        if (_patternRunner!.isPaused) {
            _playButton.image = NSImage(named: "play")
        } else {
            _playButton.image = NSImage(named: "pause")
        }
    }
    
    @objc func _wheelStateChanged(_ note: Notification) {
        _updateButtons()
    }
    
    fileprivate var _patternRunner: CDPatternRunner? {
        return self.patternSequenceProvider?.patternRunner
    }
    
    @IBAction func btnFirstClicked(_ sender: NSButton) {
        _patternRunner?.moveToTheStart()
    }
    
    @IBAction func btnPriorClicked(_ sender: NSButton) {
        _patternRunner?.rewind();
    }
    
    @IBAction func btnPlayPauseClicked(_ sender: NSButton) {
        if let patternRunner = _patternRunner {
            if patternRunner.isPaused {
                patternRunner.play()
            } else {
                patternRunner.pause()
            }
        }
    }
    
    @IBAction func btnNextClicked(_ sender: NSButton) {
        _patternRunner?.nextPatternItem()
    }
    
    @IBAction func btnEndClicked(_ sender: NSButton) {
        _patternRunner?.moveToTheStart()
    }


}

