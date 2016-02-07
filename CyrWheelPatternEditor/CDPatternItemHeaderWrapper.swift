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
}

class CDPatternItemHeaderWrapper: NSObject {
    var delegate: CDPatternItemHeaderWrapperChanged?
    
    init(patternItemHeader: CDPatternItemHeader, patternItemFilename: String?, delegate: CDPatternItemHeaderWrapperChanged?) {
        super.init()
        // The name is the string version of what is playing, or the patternItemFilename
        self.patternType = patternItemHeader.patternType
        self.colorEnabled = CDPatternTypeNeedsColor(patternItemHeader.patternType)
        self.duration = CDPatternTimeIntervalForDuration(patternItemHeader.duration)
        self.looping = patternItemHeader.patternEndCondition == CDPatternEndConditionOnButtonClick
        self.speed = CDPatternItemGetSpeedFromDuration(patternItemHeader.patternDuration, patternItemHeader.patternType)
        self.speedEnabled = CDPatternItemGetSpeedEnabled(patternItemHeader.patternType)
        self.color = CDEncodedColorTransformer.colorFromCRGBColor(patternItemHeader.color)
        self.velocityBasedBrightness = patternItemHeader.shouldSetBrightnessByRotationalVelocity == 0 ? false : true
        if patternItemFilename != nil {
            self.patternName = patternItemFilename
        } else {
            self.patternName = CDPatternItemNames.nameForPatternType(patternItemHeader.patternType)
        }
        self.delegate = delegate; // set last
    }
    
    init(label: String) {
        self.patternName = label
    }
    
    var patternType: LEDPatternType = LEDPatternTypeCount

    // alias...for bindings
    dynamic var label: String {
        return self.patternName
    }
    
    dynamic var patternName: String!
    dynamic var duration: NSTimeInterval = 0
    dynamic var looping: Bool = false
    dynamic var color: NSColor = NSColor.blackColor() {
        didSet {
            delegate?.patternItemColorChanged(self)
        }
    }
    dynamic var colorEnabled = false
    dynamic var speed: Double = 0.6 {
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
}
