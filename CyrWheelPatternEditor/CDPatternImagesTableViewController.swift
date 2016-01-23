//
//  CDPatternImagesTableViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 23/01/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternImagesTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var _tableView: NSTableView!
    
    private var _patternImages = [NSImage]()
    private let _ignoredPatternTypes: [LEDPatternType] = [LEDPatternTypeMax, LEDPatternTypeImageLinearFade_UNUSED, LEDPatternTypeImageEntireStrip_UNUSED, LEDPatternTypeBitmap]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the pattern images we have...
    }
    
    
    
    private func _numberOfProgrammedPatterns() -> Int {
        return Int(LEDPatternTypeMax.rawValue) - _ignoredPatternTypes.count;
    }
    
    ///MARK: TableView datasource methods
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        // Two group rows, and then the images
        return _patternImages.count + _numberOfProgrammedPatterns() + 2
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return nil
    }
    
    func tableView(tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if row == 0 {
            return true
        } else if row == (_numberOfProgrammedPatterns() + 1) {
            return true
        } else {
            return false
        }
    }

    

    
    
}
