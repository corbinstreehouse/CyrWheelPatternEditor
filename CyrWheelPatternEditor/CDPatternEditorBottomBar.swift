//
//  CDPatternEditorBottomBar.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/19/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternEditorBottomBar: CDPatternSequencePresenterViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        
    }
    @IBAction func btnExportClicked(sender: AnyObject) {
        let sp = NSSavePanel()
        sp.allowedFileTypes = ["pat"]
        sp.allowsOtherFileTypes = false
        sp.title = "Export the pattern sequence";
        let window = self.view.window!
        sp.beginSheetModalForWindow(window) { (result) -> Void in
            if result == NSModalResponseOK {
                do {
                    try self.patternSequence.exportToURL(sp.URL!)
                } catch let error as NSError {
                    window.presentError(error)
                }
                
            }
        }
    }
    
    // We use the document to do the heavy lifting of adding/removing items.
    
    private func _getDocument() -> CDDocument {
        // This is a rather ugly way to get to the document..
        return self.parentWindowController!.document as! CDDocument
    }
    
    private func _addItem() {
        let doc = _getDocument()
        doc.addNewPatternItem()
    }
    
    private func _removeSelectedItem() {
        // Find the selection
        if var selectionManager = self.patternSequenceProvider {
            // Try to maintain a selection
            let priorSelection = selectionManager.patternSelectionIndexes;
            _getDocument().removePatternItemsAtIndexes(priorSelection)
            
            if priorSelection.count > 0 && selectionManager.patternSelectionIndexes.count == 0 {
                var firstIndex = priorSelection.firstIndex
                firstIndex--
                if firstIndex >= 0 && firstIndex < self.patternSequence.children.count {
                    selectionManager.patternSelectionIndexes = NSIndexSet(index: firstIndex)
                }
            }
        }
    }
    
    @IBAction func btnAddRemoveClicked(sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self._addItem()
        }  else {
            self._removeSelectedItem()
        }

    }
    
}
