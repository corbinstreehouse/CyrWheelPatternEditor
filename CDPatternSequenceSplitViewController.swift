//
//  CDMainContentViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/31/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternSplitView: NSSplitView {
    
    override var dividerColor: NSColor {
        get {
            // TODO: better colors management..
            return NSColor(srgbRed: 29.0/255.0, green: 29.0/255.0, blue: 29.0/255.0, alpha: 1.0)
        }
    }
    override var dividerThickness: CGFloat {
        get {
            return 2
        }
    }



}

class CDPatternSequenceSplitViewController: NSSplitViewController, CDPatternSequencePresenter {

//    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//
//    }
    
    var patternSequence: CDPatternSequence! {
        didSet {
            for child in self.childViewControllers {
                if var childSequenceVC = child as? CDPatternSequencePresenter {
                    childSequenceVC.patternSequence = self.patternSequence
                }
            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
