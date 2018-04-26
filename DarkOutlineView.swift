//
//  CustomTableRowView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/7/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

extension NSOutlineView {
    
    var selectedItem: AnyObject? {
        get {
            if self.selectedRow != -1 {
                return self.item(atRow: self.selectedRow) as AnyObject
            } else {
                return nil;
            }
        }
    }
}

// Custom row view for the header item
class FloatingRowView: NSTableRowView {
    
    //    override var wantsUpdateLayer: Bool {
    //        get {
    //            return true;
    //        }
    //    }
    //
    //    override func updateLayer() {
    //        self.layer!.backgroundColor =
    //    }
    
    override func draw(_ dirtyRect: NSRect) {
        // TODO: something more generic/better with colors instead of hardcoding
        let backgroundColor = NSColor(srgbRed: 41.0/255.0, green: 41.0/255.0, blue: 41.0/255.0, alpha: 1.0)
        backgroundColor.set()
        NSRectFillUsingOperation(dirtyRect, NSCompositingOperation.sourceIn)
        
        let borderColor = NSColor(srgbRed: 29.0/255.0, green: 29.0/255.0, blue: 29.0/255.0, alpha: 1.0)
        borderColor.set()
        var topRect = self.bounds
        topRect.size.height = 2.0
        NSRectFillUsingOperation(topRect, NSCompositingOperation.sourceIn)
        
        topRect.origin.y = NSMaxY(self.bounds) - 2.0
        NSRectFillUsingOperation(topRect, NSCompositingOperation.sourceIn)
    }
    
}

class DarkRowView: NSTableRowView {
    //    override var interiorBackgroundStyle: NSBackgroundStyle {
    //        get {
    //            // Make the text not go dark
    //            return NSBackgroundStyle.Dark
    //        }
    //    }
    
    //    override func updateLayer() {
    //        super.updateLayer()
    //        if self.selected && !self.emphasized {
    //            // Change the color to be a variation of the blue
    //            self.layer!.backgroundColor = NSColor.redColor().CGColor// NSColor.secondarySelectedControlColor().colorWithAlphaComponent(0.7).CGColor
    //        }
    //    }
    override func drawSelection(in dirtyRect: NSRect) {
        var color = NSColor.alternateSelectedControlColor
        if !self.isEmphasized {
            color = color.withAlphaComponent(0.6)
        }
        color.set()
        NSRectFillUsingOperation(dirtyRect, NSCompositingOperation.sourceIn)
    }
    
}

class DarkOutlineView: NSOutlineView {
    override func make(withIdentifier identifier: String, owner: Any?) -> NSView? {
        let result = super.make(withIdentifier: identifier, owner: owner)
        if let result = result {
            if result.identifier == NSOutlineViewDisclosureButtonKey {
                result.alphaValue = 0.8 // looks better... not so white
            }
        }
        return result
    }
}
