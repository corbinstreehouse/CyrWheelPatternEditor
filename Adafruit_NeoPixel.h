//
//  Adafruit_NeoPixel.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/12/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#ifndef __CyrWheelPatternEditor__Adafruit_NeoPixel__
#define __CyrWheelPatternEditor__Adafruit_NeoPixel__

#include "Arduino.h"

// 'type' flags for LED pixels (third parameter to constructor):
#define NEO_GRB     0x01 // Wired for GRB data order
#define NEO_COLMASK 0x01
#define NEO_KHZ800  0x02 // 800 KHz datastream
#define NEO_SPDMASK 0x02

// Trinket flash space is tight, v1 NeoPixels aren't handled by default.
// Remove the ifndef/endif to add support -- but code will be bigger.
// Conversely, can comment out the #defines to save space on other MCUs.
#ifndef __AVR_ATtiny85__
#define NEO_RGB     0x00 // Wired for RGB data order
#define NEO_KHZ400  0x00 // 400 KHz datastream
#endif

@class CDCyrWheelView;

class Adafruit_NeoPixel {
private:
    CDCyrWheelView *_cyrWheelView;
    const uint16_t _numberOfLEDs;
    uint8_t *_pixels; // GRB
    const uint16_t _numBytes;      // Size of 'pixels' buffer below; this is numLEDs*3, but storing it
    int _brightness;
public:
    // Constructor: number of LEDs, pin number, LED type
    Adafruit_NeoPixel(uint16_t numberOfLEDs, uint8_t pinNumber=6, uint8_t t=NEO_GRB + NEO_KHZ800);
    ~Adafruit_NeoPixel();
    
    void begin();
    void show();
    
    void setPixelColor(uint16_t n, uint8_t r, uint8_t g, uint8_t b);
    void setPixelColor(uint16_t n, uint32_t c);
    void setBrightness(uint8_t);
    uint8_t *getPixels() const;
    uint16_t numPixels(void) const;
    static uint32_t Color(uint8_t r, uint8_t g, uint8_t b);
    uint32_t getPixelColor(uint16_t n) const;
    void setCyrWheelView(CDCyrWheelView *view);
    
private:
    
    
};


#endif /* defined(__CyrWheelPatternEditor__Adafruit_NeoPixel__) */
