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
    @IBAction func btnExportClicked(_ sender: AnyObject) {
        let sp = NSSavePanel()
        sp.allowedFileTypes = ["pat"]
        sp.allowsOtherFileTypes = false
        sp.title = "Export the pattern sequence";
        let window = self.view.window!
        sp.beginSheetModal(for: window) { (result) -> Void in
            if result == NSModalResponseOK {
                do {
                    try self.patternSequence.export(to: sp.url!)
                } catch let error as NSError {
                    window.presentError(error)
                }
                
            }
        }
    }
    
    // We use the document to do the heavy lifting of adding/removing items.
    
    fileprivate func _getDocument() -> CDDocument {
        // This is a rather ugly way to get to the document..
        return self.parentWindowController!.document as! CDDocument
    }
    
    fileprivate func _addItem() {
        let doc = _getDocument()
        doc.addNewPatternItem()
    }
    
    fileprivate func _removeSelectedItem() {
        // Find the selection
        if var selectionManager = self.patternSequenceProvider {
            // Try to maintain a selection
            let priorSelection = selectionManager.patternSelectionIndexes;
            _getDocument().removePatternItems(at: priorSelection as IndexSet)
            
            if priorSelection.count > 0 && selectionManager.patternSelectionIndexes.count == 0 {
                if let first = priorSelection.first {
                    var firstIndex = first - 1
                    if firstIndex >= 0 && firstIndex < self.patternSequence.children!.count {
                        selectionManager.patternSelectionIndexes = IndexSet(integer: firstIndex)
                    }
                }
            }
        }
    }
    
    @IBAction func btnAddRemoveClicked(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self._addItem()
        }  else {
            self._removeSelectedItem()
        }

    }
    
}
