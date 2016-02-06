//
//  CDWheelPlayerDetailViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/6/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDWheelPlayerDetailViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
    
    // These are just exposed for bindings hookup by another class
    @IBOutlet weak var chkbxShowPreview: NSButton!
    @IBOutlet weak var chkbxAutoPlayOnWheel: NSButton!
    @IBOutlet var btnPlayOnWheel: NSButton!
    
    
}
