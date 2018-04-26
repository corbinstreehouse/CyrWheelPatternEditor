//
//  CDTimecodeBackgroundView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 4/9/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDTimecodeBackgroundView: NSView {
    
    fileprivate let shadowHeight: CGFloat = 3.0

    override var wantsUpdateLayer: Bool {
        get {
            return true
        }
    }
    
    func _commonInit() {
        self.layerContentsRedrawPolicy = .onSetNeedsDisplay
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
    }
    
    override var isFlipped: Bool { return true; }
    
    override func updateLayer() {
        guard let layer = self.layer else {
            return;
        }
        let image = NSImage(size: NSSize(width: 1, height: self.bounds.size.height), flipped: true) { (imageBounds: NSRect) -> Bool in
            let g = NSGradient(starting: CDThemeColors.lightBackgroundColor, ending: CDThemeColors.lightestBackgroundColor)!
            var gradientRect = imageBounds
            gradientRect.size.height = imageBounds.height // / 2.0
            g.draw(in: gradientRect, angle: 90)
            
            
            // Draw a bottom line separator
            var bottomRect = imageBounds
            bottomRect.size.height = 1
            
            bottomRect.origin.y = imageBounds.maxY - 2 - self.shadowHeight
            CDThemeColors.lightBackgroundColor.set()
            NSRectFill(bottomRect)
            
            bottomRect.origin.y = imageBounds.maxY - 1 - self.shadowHeight
            CDThemeColors.separatorColor.set()
            NSRectFill(bottomRect)
            
            
            let shadowGradient = NSGradient(starting: CDThemeColors.separatorColor, ending: CDThemeColors.separatorColor.withAlphaComponent(0))!
            gradientRect.size.height = self.shadowHeight
            gradientRect.origin.y = imageBounds.maxY - self.shadowHeight
            shadowGradient.draw(in: gradientRect, angle: 90)
            
            return true
        }
        
        layer.contents = image
    }

        

    
    
}
