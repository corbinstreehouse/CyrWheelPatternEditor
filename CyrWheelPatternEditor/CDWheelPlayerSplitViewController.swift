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
        let middleChild: CDWheelPreviewViewController = self.childViewControllers[1] as! CDWheelPreviewViewController
        let rightChild: CDWheelPlayerDetailViewController = self.childViewControllers[2] as! CDWheelPlayerDetailViewController
        // The middle controls the runner..really I should push ownership of it to a parent and push it down to the child, or just implement a protocol to get it and set the cyrWheel view like I do in other places
        leftChild.patternRunner = middleChild.patternRunner
        leftChild.detailViewController = rightChild;
    }
    
    
}
