//
//  CDPatternItemHeaderWrapper.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/7/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

// For bindings to the struct and a callback
protocol CDPatternItemHeaderWrapperChanged {
    func patternItemSpeedChanged(item: CDPatternItemHeaderWrapper)
    func patternItemColorChanged(item: CDPatternItemHeaderWrapper)
    func patternItemVelocityBasedBrightnessChanged(item: CDPatternItemHeaderWrapper)
    func patternItemBitmapOptionsChanged(item: CDPatternItemHeaderWrapper)
}

//extension LEDBitmapPatternOptions: RawRepresentable {
//    
//    public typealias RawValue = UInt32
//    /// Convert from a value of `RawValue`, yielding `nil` iff
//    /// `rawValue` does not correspond to a value of `Self`.
//    public init?(rawValue: UInt32) {
//        
//    }
//    /// The corresponding value of the "raw" type.
//    ///
//    /// `Self(rawValue: self.rawValue)!` is equivalent to `self`.
//    public var rawValue: UInt32 {
//        get {
//            
//        }
//    }
//
//}

class CDPatternItemHeaderWrapper: NSObject {
    var delegate: CDPatternItemHeaderWrapperChanged?
    
    private func _commonInitAfterPatternType() {
        self.colorEnabled = CDPatternTypeNeedsColor(patternType)
        self.speedEnabled = CDPatternItemGetSpeedEnabled(patternType)
    }
    
    init(patternItemHeader: CDPatternItemHeader, patternItemFilename: String?, patternSequenceFilename: String?, delegate: CDPatternItemHeaderWrapperChanged?) {
        super.init()
        // The name is the string version of what is playing, or the patternItemFilename
        self.patternType = patternItemHeader.patternType
        _commonInitAfterPatternType()
        self.duration = CDPatternTimeIntervalForDuration(patternItemHeader.duration)
        self.looping = patternItemHeader.patternEndCondition == CDPatternEndConditionOnButtonClick
        self.speed = CDPatternItemGetSpeedFromDuration(patternItemHeader.patternDuration, patternItemHeader.patternType)

        if self.colorEnabled {
            // compiler is fucking up...
            // CRASHES IN THE method..mystery why..
            let c = patternItemHeader.color
    //        self.color = CDEncodedColorTransformer.colorFromCRGBColor(patternItemHeader.color)
            self.color = NSColor(SRGBRed: CGFloat(c.red)*255.0, green: CGFloat(c.green)*255.0, blue: CGFloat(c.blue)*255.0, alpha: 1.0)
        } else {
            // black looks better when disabled.
        }
        
        self.patternSequenceFilename = patternSequenceFilename

        self.velocityBasedBrightness = patternItemHeader.shouldSetBrightnessByRotationalVelocity == 0 ? false : true
        if patternItemFilename != nil {
            self.patternName = patternItemFilename
        } else {
            self.patternName = CDPatternItemNames.nameForPatternType(patternItemHeader.patternType)
        }
        
        if self.isBitmapType {
            self.bitmapPatternOptions = patternItemHeader.patternOptions.bitmapOptions
        }
        
        self.delegate = delegate; // set last
    }
    
    init(patternType: LEDPatternType, label: String) {
        super.init()
        self.patternType = patternType
        _commonInitAfterPatternType()
        self.patternName = label
    }
    
    init(patternType: LEDPatternType) {
        super.init()
        self.patternType = patternType
        _commonInitAfterPatternType()
        self.patternName = CDPatternItemNames.nameForPatternType(patternType)
        if self.colorEnabled {
            self.color = NSColor(SRGBRed: 1.0, green: 0, blue: 0, alpha: 1)
        }
    }

    dynamic var canDelete = false;

    var patternType: LEDPatternType = LEDPatternTypeCount

    dynamic var patternSequenceFilename: String?
    
    // alias...for bindings
    dynamic var label: String {
        return self.patternName
    }
    
    dynamic var patternName: String!
    dynamic var duration: NSTimeInterval = 0
    dynamic var looping: Bool = false
    // Use the sRGB color space as a starting point
    dynamic var color: NSColor = NSColor(SRGBRed: 0, green: 0, blue: 0, alpha: 1.0) {
        didSet {
            delegate?.patternItemColorChanged(self)
        }
    }
    dynamic var colorEnabled = false
    dynamic var speed: Double = 0.5 {
        didSet {
            delegate?.patternItemSpeedChanged(self)
        }
    }
    dynamic var speedEnabled: Bool = false
    dynamic var velocityBasedBrightness: Bool = false {
        didSet {
            delegate?.patternItemVelocityBasedBrightnessChanged(self)
        }
    }
    // TODO: create a preview image for this item..
    dynamic var image: NSImage? = nil
    
    dynamic var isBitmapType: Bool {
        return self.patternType == LEDPatternTypeBitmap || self.patternType == LEDPatternTypeImageReferencedBitmap
    }
    
    dynamic var shouldStretchBitmap: Bool = false {
        didSet {
            delegate?.patternItemBitmapOptionsChanged(self)
        }
    }
    dynamic var shouldInterpolateStretchedPixels: Bool = false {
        didSet {
            delegate?.patternItemBitmapOptionsChanged(self)
        }
    }
    dynamic var shouldInterpolateToNextRow: Bool = false {
        didSet {
            delegate?.patternItemBitmapOptionsChanged(self)
        }
    }
    
    dynamic var pov: Bool = false {
        didSet {
            delegate?.patternItemBitmapOptionsChanged(self)
        }
    }
    
    var bitmapPatternOptions: LEDBitmapPatternOptions {
        get {
            return LEDBitmapPatternOptions(shouldInterpolateStretchedPixels: shouldInterpolateStretchedPixels ? 1 : 0, shouldStretchBitmap:  shouldStretchBitmap ? 1 : 0,
                shouldInterpolateToNextRow: shouldInterpolateToNextRow ? 1 : 0,
                pov: pov ? 1 : 0,
                reserved: 0)
        }
        set(value) {
            pov = value.pov == 1 ? true : false;
            shouldStretchBitmap = value.shouldStretchBitmap == 1 ? true : false;
            shouldInterpolateStretchedPixels = value.shouldInterpolateStretchedPixels == 1 ? true : false
            shouldInterpolateToNextRow = value.shouldInterpolateToNextRow == 1 ? true : false
        }
    }
}
