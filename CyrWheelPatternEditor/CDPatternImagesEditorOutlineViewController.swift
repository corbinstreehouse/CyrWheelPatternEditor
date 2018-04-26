//
//  CDPatternImagesEditorOutlineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/4/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternImagesEditorOutlineViewController: CDPatternImagesOutlineViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Drag and drop setup
        _outlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        _outlineView.register(forDraggedTypes: [CDPatternItem.pasteboardType()])
    }
    
    fileprivate func _dataForItemsAt(_ indexes: IndexSet) -> Data {
        // create temporary items in the model, then toss them away after achiving them
        var temporaryItems = [CDPatternItem]()
        let doc = _getDocument()
        _enumerateItemsAsPatternItems(indexes) { (patternItem) -> () in
            temporaryItems.append(patternItem)
        }
        
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: temporaryItems)
        
        // Free the temporary items in the model
        temporaryItems.forEach { (item: CDPatternItem) -> () in
            doc.removeTemporaryPatternItem(item)
        }
        
        return data
    }
    
    fileprivate func _addSelectedItemsToSequence(_ indexes: IndexSet) {
        let doc = _getDocument()
        var insertIndex: Int = 0
        if let temp = self.patternSequenceProvider!.patternSelectionIndexes.last {
            insertIndex = temp + 1;
        } else {
            insertIndex = doc.patternSequence.children!.count
        }
        _enumerateItemsAsPatternItems(indexes) { (patternItem) -> () in
            doc.addPatternItem(toChildren: patternItem, at: insertIndex)
            insertIndex = insertIndex + 1
        }
    }
    
    fileprivate func _getDocument() -> CDDocument {
        // This is a rather ugly way to get to the document..
        return self.parentWindowController!.document as! CDDocument
    }
    
    fileprivate func _makeTemporaryPatternItemWithPatternType(_ patternType: LEDPatternType, imageFilename: String?) -> CDPatternItem {
        let doc = _getDocument()
        let newItem = doc.makeTemporaryPatternItem()
        
        // copy the selected item, if available..
        if let selectedIndex = self.patternSequenceProvider!.patternSelectionIndexes.last {
            let patternSequence: CDPatternSequence = self.patternSequenceProvider!.patternSequence!
            let patternItemToCopy: CDPatternItem = patternSequence.children![selectedIndex] as! CDPatternItem // why isn't this already typed?
            patternItemToCopy.copy(to: newItem)
        }
        
        // Make it have the same relative patternDuration/speed as the existing one; images we make have a 0.60 speed on initialization.
        let speedToSet = patternType == LEDPatternTypeImageReferencedBitmap ? 0.60 : newItem.patternSpeed
        
        // Changing the patternType may change the speed (relative), so reset it.. .. maybe I should do this when the patternType changes always? I just don't know how to override it...
        newItem.patternType = patternType
        newItem.patternSpeed = speedToSet
        newItem.imageFilename = imageFilename
        return newItem
    }
    
    fileprivate func _makeTemporaryPatteryItemForRow(_ index: Int) -> CDPatternItem? {
        let item = _outlineView.item(atRow: index)
        switch item {
        case let programmedItem as ProgrammedPatternObjectWrapper:
            return _makeTemporaryPatternItemWithPatternType(programmedItem.patternType, imageFilename: nil)
        case let imageItem as ImagePatternObjectWrapper:
            if !imageItem.isDirectory {
                return _makeTemporaryPatternItemWithPatternType(imageItem.patternType, imageFilename: imageItem.relativeFilename)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    fileprivate func _enumerateItemsAsPatternItems(_ indexes: IndexSet, handler: (_ patternItem: CDPatternItem)->()) {
        for index in indexes {
            if let patternItem = _makeTemporaryPatteryItemForRow(index) {
                handler(patternItem)
            }
        }
    }
    
    
    // Add pasteboard support
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: AnyObject) -> NSPasteboardWriting? {
        let row = outlineView.row(forItem: item)
        if let patternItem = _makeTemporaryPatteryItemForRow(row) {
            let pasteboardItem = NSPasteboardItem()
            let data: Data = NSKeyedArchiver.archivedData(withRootObject: patternItem)
            pasteboardItem.setData(data, forType: CDPatternItem.pasteboardType())
            return pasteboardItem
        } else {
            return nil
        }
    }

    @IBAction func _outlineDoubleClick(_ sender: NSOutlineView) {
        _addSelectedItemsToSequence(sender.selectedRowIndexes)
    }
    
    @IBAction func copy(_ sender: AnyObject) {
        if _outlineView.selectedRowIndexes.count > 0 {
            let data: Data = _dataForItemsAt(_outlineView.selectedRowIndexes)
            let pasteboard: NSPasteboard = NSPasteboard.general()
            pasteboard.clearContents()
            pasteboard.declareTypes([CDPatternItem.pasteboardType()], owner: self)
            pasteboard.setData(data, forType: CDPatternItem.pasteboardType())
        }
    }

}
