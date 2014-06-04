//
//  CDSimulatorLEDPatterns.cpp
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 6/1/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#include "CDSimulatorLEDPatterns.h"


void CDSimulatorLEDPatterns::internalShow() {
    for (int i = 0; i < getLEDCount(); i++) {
        NSColor *color = [NSColor colorWithSRGBRed:m_leds[i].r/255.0 green:m_leds[i].g/255.0 blue:m_leds[i].b/255.0 alpha:1.0];
        [m_cyrWheelView setPixelColor:color atIndex:i];
    }
    [m_cyrWheelView setNeedsDisplay:YES];
    //#warning corbin force display not so great... slows stuff down considerably..
    //    [m_cyrWheelView displayIfNeeded];
}

