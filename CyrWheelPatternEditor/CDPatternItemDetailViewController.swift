//
//  CDPatternItemDetailViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/3/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternItemDetailViewController: CDPatternSequencePresenterViewController {

    @IBOutlet var _popupPatternType: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _popupPatternType.autoenablesItems = false;
        
        _popupPatternType.removeAllItems()
        let disabledPatternTypes = LEDPatternType.nonSelectablePatternTypes
        let hiddenPatternTypes = LEDPatternType.hiddenPatternTypes
        
        // Create a sorted array of pattern types to show excluding ones we can't select
        // TODO: this could be a static copy
        for patternObject in ProgrammedPatternObjectWrapper.allSortedProgrammedPatternsIgnoring(hiddenPatternTypes) {
            _popupPatternType.addItem(withTitle: patternObject.label)
            let item: NSMenuItem = _popupPatternType.lastItem!
            item.tag = Int(patternObject.patternType.rawValue)
            item.isEnabled = !disabledPatternTypes.contains(patternObject.patternType)
        }

        self.view.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
}
