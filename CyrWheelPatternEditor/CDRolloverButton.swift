//
//  CDRolloverButton.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 12/2/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa

protocol CDColoredItemProtocol {
    var color: NSColor { get set }
    var downColor: NSColor  { get set }
    var hoverColor: NSColor  { get set }
    var borderColor: NSColor  { get set }
    var mouseInside: Bool { get set }
}

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
    
    func _drawButtonImage(image: NSImage, withFrame frame: NSRect, button: NSButton, colorItem: CDColoredItemProtocol) {
        var color: NSColor?
        if !button.enabled {
            color = colorItem.color.colorWithAlphaComponent(0.5)
        } else if button.highlighted {
            color = colorItem.downColor
        } else if colorItem.mouseInside {
            color = colorItem.hoverColor
        } else {
            color = colorItem.color
        }
        _drawTintedImage(self.image!, color: color!, frame: frame)
    }
}


class CDRolloverButtonCell: NSButtonCell {
    override func drawImage(image: NSImage, withFrame frame: NSRect, inView controlView: NSView) {
        let button = controlView as! NSButton
        let colorItem = controlView as! CDColoredItemProtocol
        _drawButtonImage(image, withFrame: frame, button: button, colorItem: colorItem)
    }
    
    override func drawInteriorWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        self.drawBezelWithFrame(cellFrame, inView: controlView)
        if let image = self.image {
            self.drawImage(image, withFrame: self.imageRectForBounds(cellFrame), inView: controlView)   
        }
    }
    
    override func drawBezelWithFrame(frame: NSRect, inView controlView: NSView) {
        let button: NSButton = controlView as! NSButton
        if button.bordered {
            
        }
    }

    override func mouseEntered(event: NSEvent) {
        super.mouseEntered(event)
        var colorItem = controlView as! CDColoredItemProtocol
        colorItem.mouseInside = true;
    }
    
    override func mouseExited(event: NSEvent) {
        super.mouseExited(event)
        var colorItem = controlView as! CDColoredItemProtocol
        colorItem.mouseInside = true;
    }
    
}

// only does images...
class CDRolloverButton: NSButton, CDColoredItemProtocol {
    
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
    var mouseInside: Bool = false
}


class CDPopupButtonCell: NSPopUpButtonCell {
    override func drawImage(image: NSImage, withFrame frame: NSRect, inView controlView: NSView) {
        let button = controlView as! NSButton
        let colorItem = controlView as! CDColoredItemProtocol
        _drawButtonImage(image, withFrame: frame, button: button, colorItem: colorItem)
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
    
    override func mouseEntered(event: NSEvent) {
        super.mouseEntered(event)
        var colorItem = controlView as! CDColoredItemProtocol
        colorItem.mouseInside = true;
    }
    
    override func mouseExited(event: NSEvent) {
        super.mouseExited(event)
        var colorItem = controlView as! CDColoredItemProtocol
        colorItem.mouseInside = true;
    }
    
}


class CDPopupButton: NSPopUpButton, CDColoredItemProtocol {
    
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
    var mouseInside: Bool = false

}




