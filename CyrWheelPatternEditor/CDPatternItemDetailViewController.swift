//
//  CDPatternItemDetailViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/3/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternItemDetailViewController: NSViewController, CDPatternSequencePresenter {

    @IBOutlet var _popupPatternType: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _popupPatternType.removeAllItems()
        
        for var i: Int16 = 0; i <= Int16(LEDPatternTypeMax.rawValue); i++ {
            let type = LEDPatternType.init(i)
            let name = CDPatternItemNames.nameForPatternType(type)
            _popupPatternType.addItemWithTitle(name)
            let item: NSMenuItem = _popupPatternType.lastItem!
            item.tag = Int(i)
        }
        // update the UI since we changed the content
//        if self.patternItem {
//            popupPatternType.selectItemWithTag(self.patternItem.patternType)
//        }

        
        self.view.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
    
    dynamic var patternSequence: CDPatternSequence! 

}
