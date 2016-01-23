//
//  CDPatternImagesTableViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 23/01/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

extension Array {
    func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}


// For binding the cell object value to
class PatternObjectWrapper : NSObject {
    dynamic var label: String
    dynamic var image: NSImage?
    init(label: String, image: NSImage?) {
        self.label = label
        self.image = image
    }
    
}

class CDPatternImagesTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var _tableView: NSTableView!
    
    private var _patternImages = [NSImage]()
    private let _ignoredPatternTypes: [LEDPatternType] = [LEDPatternTypeMax, LEDPatternTypeImageLinearFade_UNUSED, LEDPatternTypeImageEntireStrip_UNUSED, LEDPatternTypeBitmap]
    private var _patternTypes: [PatternObjectWrapper] = [PatternObjectWrapper]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a sorted array of pattern types to show
        for rawType in LEDPatternTypeMin.rawValue...LEDPatternTypeMax.rawValue  {
            let patternType = LEDPatternType(rawType)
            let patternImage: NSImage? = nil // TODO: image preview!
            let patternTypeWrapper = PatternObjectWrapper(label: CDPatternItemNames.nameForPatternType(patternType), image: patternImage)
            if !_ignoredPatternTypes.contains(patternType) {
                let index = _patternTypes.insertionIndexOf(patternTypeWrapper) {
                    return $0.label.localizedStandardCompare($1.label) == NSComparisonResult.OrderedAscending
                }
                
                _patternTypes.insert(patternTypeWrapper, atIndex: index)

            }
        }
        
        // Load the pattern images we have...
    }
    
    
    ///MARK: TableView datasource methods
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        // Two group rows, and then the images
        return _patternImages.count + _patternTypes.count + 2
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let nextGroupRow = _patternTypes.count + 1
        if row == 0 {
            
        } else if row == nextGroupRow {
            
        } else if row > 0 && row < nextGroupRow {
            // Subtract one for the group row
            return _patternTypes[row - 1]
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if row == 0 {
            return true
        } else if row == (_patternTypes.count + 1) {
            return true
        } else {
            return false
        }
    }
    
    
    
}
