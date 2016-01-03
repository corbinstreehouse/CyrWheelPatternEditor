//
//  CDMainContentViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/31/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

protocol CDPatternSequencePresenter {
    var patternSequence: CDPatternSequence! { get set }
}

protocol CDPatternSequenceProvider {
    var patternSequence: CDPatternSequence! { get }
}


class CDMainContentViewController: NSSplitViewController, CDPatternSequencePresenter {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
