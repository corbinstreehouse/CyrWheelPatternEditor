
//
//  CDBorderedView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 4/9/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

enum CDBorderedViewEdge : Int {
    
    case Both
    case Left
    case Right
}

class CDBorderedView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay
    }
    
    override var layer: CALayer? {
        didSet {
            //            if let layer = self.layer {
            //                layer.borderColor = self.borderColor?.CGColor
            //                layer.backgroundColor = NSColor.redColor().CGColor; //self.backgroundColor?.CGColor
            //                layer.borderWidth = self.borderWidth
            //                layer.cornerRadius = self.cornerRadius
            //
            //            }
        }
    }
    
    var borderColor: NSColor? = nil {
        willSet(v) {
            //            self.layer?.borderColor = self.borderColor?.CGColor
            if (v != borderColor) {
                self.needsDisplay = true;
            }
        }
    }
    var backgroundColor: NSColor? = nil {
        willSet(v) {
            //            self.layer?.backgroundColor = self.backgroundColor?.CGColor
            if (v != backgroundColor) {
                self.needsDisplay = true;
            }
            
        }
    }
    var borderWidth: CGFloat = 0 {
        willSet(v) {
            //            self.layer?.borderWidth = self.borderWidth
            if (v != borderWidth) {
                self.needsDisplay = true;
            }
            
        }
    }
    var cornerRadius: CGFloat = 0 {
        willSet(v) {
            //            self.layer?.cornerRadius = self.cornerRadius
            if (v != cornerRadius) {
                self.needsDisplay = true;
            }
            
        }
    }
    override var wantsUpdateLayer: Bool {
        get {
            return true
        }
    }
    
    var borderEdge: CDBorderedViewEdge = CDBorderedViewEdge.Both {
        willSet(v) {
            if (v != borderEdge) {
                self.needsDisplay = true
            }
        }
    }
    
    override func updateLayer() {
        if let layer = self.layer {
            if self.borderColor != nil && self.borderWidth > 0 {
                
                // TODO: cache these and use the same values...
                
                let centerWidth = CGFloat(8) // probably cus the cornerRadius
                let width: CGFloat = CGFloat(2) * self.borderWidth + centerWidth
                let size = NSSize(width: width, height: width)
                let image = NSImage(size: size, flipped: false, drawingHandler: { (rect: NSRect) -> Bool in
                    let tmpRect = NSInsetRect(rect, self.borderWidth/2.0, self.borderWidth/2.0)
                    if let fillColr = self.backgroundColor {
                        let p = NSBezierPath(roundedRect: tmpRect, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
                        fillColr.set()
                        p.fill()
                    }
                    if let strokeColor = self.borderColor {
                        let p = NSBezierPath(roundedRect: tmpRect, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
                        strokeColor.set()
                        p.lineWidth = self.borderWidth
                        p.stroke()
                    }
                    
                    return true
                })
                layer.contents = image.CGImageForProposedRect(nil, context: nil, hints: nil)
                if self.borderEdge == .Right {
                    layer.contentsRect = CGRect(x: 0.5, y: 0, width: 0.5, height: 1)
                    layer.contentsCenter = CGRect(x: 0, y: 0.5, width: 0, height: 0)
                } else {
                    layer.contentsCenter = CGRect(x: 0.5, y: 0.5, width: 0, height: 0)
                }
                layer.contentsScale = self.window != nil ? self.window!.backingScaleFactor : 1.0
            } else {
                layer.contents = nil
                layer.backgroundColor = self.backgroundColor?.CGColor
            }
            //            layer.borderColor = self.borderColor?.CGColor
            //            layer.backgroundColor = self.backgroundColor?.CGColor
            //            layer.borderWidth = self.borderWidth
            //            layer.cornerRadius = self.cornerRadius
        }
    }
}