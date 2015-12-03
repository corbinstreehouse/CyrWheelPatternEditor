//
//  CDRolloverButton.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 12/2/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

extension NSButtonCell {
    func _drawTintedImage(image: NSImage, color: NSColor, frame: NSRect) {
        let newImage = NSImage(size: image.size, flipped: false) { (frame: NSRect) -> Bool in
            image.drawInRect(frame)
            color.set();
            NSRectFillUsingOperation(frame, NSCompositingOperation.CompositeSourceAtop)
            return true;
        }
        newImage.drawInRect(frame)
    }
}


class CDRolloverButtonCell: NSButtonCell {
    override func drawImage(image: NSImage, withFrame frame: NSRect, inView controlView: NSView) {
        // Draw the image tinted
        var color: NSColor?
        let button: CDRolloverButton = controlView as! CDRolloverButton
        if button.highlighted {
            color = button.downColor
        } else if self.mouseInside {
            color = button.hoverColor
        } else {
            color = button.color
        }
        _drawTintedImage(self.image!, color: color!, frame: frame)
    }
    
    override func drawInteriorWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        self.drawBezelWithFrame(cellFrame, inView: controlView)
        if let image = self.image {
            self.drawImage(image, withFrame: self.imageRectForBounds(cellFrame), inView: controlView)   
        }
    }
    
    override func drawBezelWithFrame(frame: NSRect, inView controlView: NSView) {
        let button: CDRolloverButton = controlView as! CDRolloverButton
        if button.bordered {
            
        }
    }

    var mouseInside: Bool = false
    
    override func mouseEntered(event: NSEvent) {
        super.mouseEntered(event)
        mouseInside = true;
    }
    
    override func mouseExited(event: NSEvent) {
         super.mouseExited(event)
        mouseInside = false
    }
    
}

// only does images...
class CDRolloverButton: NSButton {
    
    func _commonInit() {
        setButtonType(NSButtonType.MomentaryPushInButton)
        showsBorderOnlyWhileMouseInside = true // causes us to redraw when mouse is inside..
//        (self.cell as! NSButtonCell).backgroundColor = NSColor.clearColor()
    }
    
    override class func cellClass() -> AnyClass? {
        return CDRolloverButtonCell.self
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
    }

    var color: NSColor = NSColor(SRGBRed: 205.0/255.0, green: 205.0/255.0, blue: 205.0/255.0, alpha: 1.0)
    var downColor: NSColor = NSColor(SRGBRed: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    var hoverColor: NSColor = NSColor(SRGBRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    var borderColor: NSColor = NSColor.whiteColor()
}


class CDPopupButtonCell: NSPopUpButtonCell {
    override func drawImage(image: NSImage, withFrame frame: NSRect, inView controlView: NSView) {
        // Draw the image tinted
        var color: NSColor?
        let button: CDPopupButton = controlView as! CDPopupButton
        if button.highlighted {
            color = button.downColor
        } else if self.mouseInside {
            color = button.hoverColor
        } else {
            color = button.color
        }
        _drawTintedImage(self.image!, color: color!, frame: frame)
    }
    
    override func drawInteriorWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        self.drawBezelWithFrame(cellFrame, inView: controlView)
        if let image = self.image {
            self.drawImage(image, withFrame: self.imageRectForBounds(cellFrame), inView: controlView)
        }
    }
    
    override func drawBezelWithFrame(frame: NSRect, inView controlView: NSView) {
        let button: CDPopupButton = controlView as! CDPopupButton
        if button.bordered {
            
        }
    }
    
    var mouseInside: Bool = false
    
    override func mouseEntered(event: NSEvent) {
        super.mouseEntered(event)
        mouseInside = true;
    }
    
    override func mouseExited(event: NSEvent) {
        super.mouseExited(event)
        mouseInside = false
    }
    
}


class CDPopupButton: NSPopUpButton {
    
    func _commonInit() {
        showsBorderOnlyWhileMouseInside = true // causes us to redraw when mouse is inside..
        //        (self.cell as! NSButtonCell).backgroundColor = NSColor.clearColor()
        self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
    
    override class func cellClass() -> AnyClass? {
        return CDPopupButtonCell.self
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
    }
    
    var color: NSColor = NSColor(SRGBRed: 205.0/255.0, green: 205.0/255.0, blue: 205.0/255.0, alpha: 1.0)
    var downColor: NSColor = NSColor(SRGBRed: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    var hoverColor: NSColor = NSColor(SRGBRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    var borderColor: NSColor = NSColor.whiteColor()
}




