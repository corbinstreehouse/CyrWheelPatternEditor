//
//  CDMainContentViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/31/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

//protocol CDPatternSimulatorDocumentPresenter {
//    var simulatorDocument: CDPatternSimulatorDocument! { get set }
//}

protocol CDPatternSequencePresenter {
    var patternSequence: CDPatternSequence! { get set }
}

protocol CDPatternSequenceProvider {
    var patternSequence: CDPatternSequence! { get }
}

class CDPatternSequenceSplitViewController: NSSplitViewController, CDPatternSequencePresenter {

    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

    }
    
    var patternSequence: CDPatternSequence! {
        didSet {
            for child in self.childViewControllers {
                if var childSequenceVC = child as? CDPatternSequencePresenter {
                    childSequenceVC.patternSequence = self.patternSequence
                }
            }
        }
    }
    
    // Bound to a child's value, so that another view can be bound to this one
    dynamic var patternSelectionIndexes: NSIndexSet = NSIndexSet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
