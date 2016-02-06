//
//  CDWheelPlayerSplitViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/5/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDWheelPlayerSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        // Sort of hacky, but hook up our two children together.. i wish we could link to children from IB..
        let leftChild: CDPatternImagesPlayerOutlineViewController = self.childViewControllers[0] as! CDPatternImagesPlayerOutlineViewController
        let rightChild: CDWheelPreviewViewController = self.childViewControllers[1] as! CDWheelPreviewViewController
        leftChild.patternRunner = rightChild.patternRunner
        
        // Set initial sizes..

    }
    
    
}
