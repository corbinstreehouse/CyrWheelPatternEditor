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
        _outlineView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: true)
        _outlineView.registerForDraggedTypes([CDPatternItem.pasteboardType()])
    }
    
    private func _dataForItemsAtIndexes(indexes: NSIndexSet) -> NSData {
        // create temporary items in the model, then toss them away after achiving them
        var temporaryItems = [CDPatternItem]()
        let doc = _getDocument()
        _enumerateItemsAsPatternItems(indexes) { (patternItem) -> () in
            temporaryItems.append(patternItem)
        }
        
        let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(temporaryItems)
        
        // Free the temporary items in the model
        temporaryItems.forEach { (item: CDPatternItem) -> () in
            doc.removeTemporaryPatternItem(item)
        }
        
        return data
    }
    
    private func _addSelectedItemsToSequence(indexes: NSIndexSet) {
        let doc = _getDocument()
        _enumerateItemsAsPatternItems(indexes) { (patternItem) -> () in
            doc.addPatternItemToChildren(patternItem)
        }
    }
    
    
    private func _getDocument() -> CDDocument {
        // This is a rather ugly way to get to the document..
        return self.parentWindowController!.document as! CDDocument
    }
    
    private func _makeTemporaryPatternItemWithPatternType(patternType: LEDPatternType, imageFilename: String?) -> CDPatternItem {
        let doc = _getDocument()
        let newItem = doc.makeTemporaryPatternItem()
        
        // Make it have the same relative patternDuration/speed as the existing one; images we make have a 0.60 speed on initialization.
        let speedToSet = patternType == LEDPatternTypeImageReferencedBitmap ? 0.60 : newItem.patternSpeed
        
        // Changing the patternType may change the speed (relative), so reset it.. .. maybe I should do this when the patternType changes always? I just don't know how to override it...
        newItem.patternType = patternType
        newItem.patternSpeed = speedToSet
        newItem.imageFilename = imageFilename
        return newItem
    }
    
    private func _makeTemporaryPatteryItemForRow(index: Int) -> CDPatternItem? {
        let item = _outlineView.itemAtRow(index)
        switch item {
        case let programmedItem as ProgrammedPatternObjectWrapper:
            return _makeTemporaryPatternItemWithPatternType(programmedItem.patternType, imageFilename: nil)
        case let imageItem as ImagePatternObjectWrapper:
            if !imageItem.isDirectory {
                return _makeTemporaryPatternItemWithPatternType(LEDPatternTypeImageReferencedBitmap, imageFilename: imageItem.relativeFilename)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    private func _enumerateItemsAsPatternItems(indexes: NSIndexSet, handler: (patternItem: CDPatternItem)->()) {
        for index in indexes {
            if let patternItem = _makeTemporaryPatteryItemForRow(index) {
                handler(patternItem: patternItem)
            }
        }
    }
    
    
    // Add pasteboard support
    func outlineView(outlineView: NSOutlineView, pasteboardWriterForItem item: AnyObject) -> NSPasteboardWriting? {
        let row = outlineView.rowForItem(item)
        if let patternItem = _makeTemporaryPatteryItemForRow(row) {
            let pasteboardItem = NSPasteboardItem()
            let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(patternItem)
            pasteboardItem.setData(data, forType: CDPatternItem.pasteboardType())
            return pasteboardItem
        } else {
            return nil
        }
    }

    @IBAction func _outlineDoubleClick(sender: NSOutlineView) {
        _addSelectedItemsToSequence(sender.selectedRowIndexes)
    }
    
    @IBAction func copy(sender: AnyObject) {
        if _outlineView.selectedRowIndexes.count > 0 {
            let data: NSData = _dataForItemsAtIndexes(_outlineView.selectedRowIndexes)
            let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
            pasteboard.clearContents()
            pasteboard.declareTypes([CDPatternItem.pasteboardType()], owner: self)
            pasteboard.setData(data, forType: CDPatternItem.pasteboardType())
        }
    }

}
