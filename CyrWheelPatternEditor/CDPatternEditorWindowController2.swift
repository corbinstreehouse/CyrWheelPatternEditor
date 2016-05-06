//
//  CDPatternEditorWindowController2.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 12/29/15.
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDEditorPatternRunner : CDPatternRunner {

//    var showingCurrentSelection: Bool = false
    
    
}

class CDPatternEditorWindowController2: NSWindowController, CDPatternSequenceProvider, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Create the pattern runner 
        let delegate = NSApp.delegate as! CDAppDelegate
        _patternRunner = CDEditorPatternRunner(patternDirectoryURL: delegate.patternDirectoryURL)
//        patternRunner.setCyrWheelView(_cyrWheelView) // Done by a child view controller

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        let window = self.window!
        // TODO: better color management..
        // Agh..the dark appearance makes this not work! this line is basically pointless
        window.backgroundColor = NSColor(SRGBRed: 49.0/255.0, green: 49.0/255.0, blue: 49.0/255.0, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        // I don't want the content to use "vibrant" controls except in particular UI pieces, so I set the appearance to vibrantDark on specific UI view parents
        window.contentView!.appearance = NSAppearance(named: NSAppearanceNameAqua)
        window.delegate = self
        
        
        _documentChanged();
    }
    
    private func _documentChanged() {
        if self.document != nil {
            var mainVC = self.window!.contentViewController as! CDPatternSequencePresenter;
            mainVC.patternSequence = self.patternSequence // This pushes our value to the view controllers
            _startObservingChanges()
            _updatePatternRunner()
        }
    }
    
    override var document: AnyObject? {
        didSet {
            _documentChanged()
        }
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return self.document!.managedObjectContext
    }
    
    var patternSequence: CDPatternSequence? {
        get {
            return self.document?.patternSequence;
        }
    }

    private var _selectedPatternItem: CDPatternItem? {
        get {
            if patternSelectionIndexes.count == 1 {
                return self.patternSequence?.children[patternSelectionIndexes.firstIndex] as? CDPatternItem
            } else {
                return nil
            }
        }
    }

    func window(window: NSWindow, willPositionSheet sheet: NSWindow, usingRect rect: NSRect) -> NSRect {
        // drop it down
        var result = rect;
        result.origin.y -= 23
        return result
    }
    
    
    // Create the main pattern runner here; we associate it with a child view controller later
    private var _patternRunner: CDEditorPatternRunner!
    var patternRunner: CDPatternRunner! {
        return _patternRunner
    }
    
    // Bound to a child's value, so that another view can be bound to this one
    dynamic var patternSelectionIndexes: NSIndexSet = NSIndexSet()
    
    private func _updatePatternRunner() {
        // If we have one selected item, we create a preview for just that. Otherwise, we preview the whole sequence
        if let validSequence = self.patternSequence {
            // Save the position and attempt to restore it!
            let playheadTimePosition = _patternRunner.playheadTimePosition
            let data = validSequence.exportAsData()
            _patternRunner.loadFromData(data)
            _patternRunner.playheadTimePosition = playheadTimePosition
        }
    }

    
    func _startObservingChanges() {
        let context: NSManagedObjectContext = self.managedObjectContext
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: context, queue: nil) { note in
            let needsUpdate = true
//            if let updated = note.userInfo?[NSUpdatedObjectsKey] where updated.count > 0 {
//                print("updated: \(updated)")
//                if let selectedItem = self._selectedPatternItem  {
//                    // If we have a selected item, only reload if we aren't showing a preview for it
//                    if _patternRunner.showingCurrentSelection {
//                        // TODO: maybe nly reload it if it was that item..
//                        if selectedItem
//                    }
//                }
//            }
//            
            if (needsUpdate) {
                self._updatePatternRunner()
            }
            /*
            if let updated = note.userInfo?[NSUpdatedObjectsKey] where updated.count > 0 {
            print("updated: \(updated)")
            }
            
            if let deleted = note.userInfo?[NSDeletedObjectsKey] where deleted.count > 0 {
            print("deleted: \(deleted)")
            }
            
            if let inserted = note.userInfo?[NSInsertedObjectsKey] where inserted.count > 0 {
            print("inserted: \(inserted)")
            }
            if let inserted = note.userInfo?[NSRefreshedObjectsKey] where inserted.count > 0 {
            print("inserted: \(inserted)")
            }
            if let inserted = note.userInfo?[NSInvalidatedObjectsKey] where inserted.count > 0 {
            print("inserted: \(inserted)")
            }
            */
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        var handled = false
        if (theEvent.character == NSRightArrowFunctionKey) {
            self.patternRunner.nextPatternItem()
            handled = true;
        } else if (theEvent.character == NSLeftArrowFunctionKey) {
            self.patternRunner.priorPatternItem();
            handled = true;
        } else if let chars = theEvent.characters {
            if (chars == " ") {
                if self.patternRunner.paused {
                    self.patternRunner.play()
                } else {
                    self.patternRunner.pause()
                }
                handled = true
            }
        }
        if (!handled) {
            super.keyDown(theEvent)
        }
    }
    
    @IBAction func revealInFinder(sender: AnyObject) {
        if let item = self._selectedPatternItem {
            if let relativeFilename = item.imageFilename {
                let fullFilenamePath = CDAppDelegate.appDelegate.patternDirectoryURL.URLByAppendingPathComponent(relativeFilename)
                NSWorkspace.sharedWorkspace().selectFile(fullFilenamePath.path!, inFileViewerRootedAtPath: "")
            }
        }
    }

}
