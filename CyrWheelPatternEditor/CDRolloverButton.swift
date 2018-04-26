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
    func _drawTintedImage(_ image: NSImage, color: NSColor, frame: NSRect) {
        let newImage = NSImage(size: image.size, flipped: false) { (frame: NSRect) -> Bool in
            image.draw(in: frame)
            color.set();
            NSRectFillUsingOperation(frame, NSCompositingOperation.sourceAtop)
            return true;
        }
        newImage.draw(in: frame)
    }
    
    func _drawButtonImage(_ image: NSImage, withFrame frame: NSRect, button: NSButton, colorItem: CDColoredItemProtocol) {
        var color: NSColor?
        if !button.isEnabled {
            color = colorItem.color.withAlphaComponent(0.5)
        } else if button.isHighlighted {
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
    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        let button = controlView as! NSButton
        let colorItem = controlView as! CDColoredItemProtocol
        _drawButtonImage(image, withFrame: frame, button: button, colorItem: colorItem)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        self.drawBezel(withFrame: cellFrame, in: controlView)
        if let image = self.image {
            self.drawImage(image, withFrame: self.imageRect(forBounds: cellFrame), in: controlView)   
        }
    }
    
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        let button: NSButton = controlView as! NSButton
        if button.isBordered {
            
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        var colorItem = controlView as! CDColoredItemProtocol
        colorItem.mouseInside = true;
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        var colorItem = controlView as! CDColoredItemProtocol
        colorItem.mouseInside = true;
    }
    
}

// only does images...
class CDRolloverButton: NSButton, CDColoredItemProtocol {
    
    func _commonInit() {
        setButtonType(NSButtonType.momentaryPushIn)
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

    var color: NSColor = NSColor(srgbRed: 205.0/255.0, green: 205.0/255.0, blue: 205.0/255.0, alpha: 1.0)
    var downColor: NSColor = NSColor(srgbRed: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    var hoverColor: NSColor = NSColor(srgbRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    var borderColor: NSColor = NSColor.white
    var mouseInside: Bool = false
}


class CDPopupButtonCell: NSPopUpButtonCell {
    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        let button = controlView as! NSButton
        let colorItem = controlView as! CDColoredItemProtocol
        _drawButtonImage(image, withFrame: frame, button: button, colorItem: colorItem)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        self.drawBezel(withFrame: cellFrame, in: controlView)
        if let image = self.image {
            self.drawImage(image, withFrame: self.imageRect(forBounds: cellFrame), in: controlView)
        }
    }
    
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        let button: CDPopupButton = controlView as! CDPopupButton
        if button.isBordered {
            
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        var colorItem = controlView as! CDColoredItemProtocol
        colorItem.mouseInside = true;
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
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
    
    var color: NSColor = NSColor(srgbRed: 205.0/255.0, green: 205.0/255.0, blue: 205.0/255.0, alpha: 1.0)
    var downColor: NSColor = NSColor(srgbRed: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    var hoverColor: NSColor = NSColor(srgbRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    var borderColor: NSColor = NSColor.white
    var mouseInside: Bool = false

}




