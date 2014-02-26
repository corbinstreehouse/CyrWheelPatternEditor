//
//  Adafruit_NeoPixel.cpp
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/12/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#include "Adafruit_NeoPixel.h"

#import "CDCyrWheelView.h"


Adafruit_NeoPixel::Adafruit_NeoPixel(uint16_t numberOfLEDs, uint8_t p, uint8_t t) : _numberOfLEDs(numberOfLEDs), _numBytes(numberOfLEDs*3), _brightness(0) {
    _pixels = (uint8_t *)malloc(_numBytes);
    memset(_pixels, 0, _numBytes);
}

Adafruit_NeoPixel::~Adafruit_NeoPixel() {
    if (_pixels) {
        free(_pixels);
    }
}

void Adafruit_NeoPixel::begin() {
    
}

void Adafruit_NeoPixel::show() {
    for (int i = 0; i < _numberOfLEDs; i++) {
        uint16_t offset = i * 3;
        // GRB hardcoded
        uint8_t g = _pixels[offset];
        uint8_t r = _pixels[offset+1];
        uint8_t b = _pixels[offset+2];
        NSColor *color = [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
        [_cyrWheelView setPixelColor:color atIndex:i];
    }
    [_cyrWheelView setNeedsDisplay:YES];
//#warning corbin force display not so great... slows stuff down considerably..
//    [_cyrWheelView displayIfNeeded];
}

void Adafruit_NeoPixel::setPixelColor(uint16_t n, uint8_t r, uint8_t g, uint8_t b) {
    this->setPixelColor(n, Color(r, g, b));
}

void Adafruit_NeoPixel::setPixelColor(uint16_t n, uint32_t c) {
    NSCAssert(n < _numberOfLEDs, @"bounds check");
    uint8_t r = (uint8_t)(c >> 16);
    uint8_t g = (uint8_t)(c >>  8);
    uint8_t b = (uint8_t)c;
    if (_brightness) { // See notes in setBrightness()
        r = (r * _brightness) >> 8;
        g = (g * _brightness) >> 8;
        b = (b * _brightness) >> 8;
    }
    uint8_t *p = &_pixels[n * 3];
    *p++ = g;
    *p++ = r;
    *p = b;
}

void Adafruit_NeoPixel::setBrightness(uint8_t) {
    // TODO: corbin implement if i need/want
}

uint32_t Adafruit_NeoPixel::getPixelColor(uint16_t n) const {
    if (n < _numberOfLEDs) {
        uint16_t ofs = n * 3;
        return (uint32_t)(_pixels[ofs + 2]) | // b
            ((uint32_t)(_pixels[ofs    ]) <<  8) | // g
            ((uint32_t)(_pixels[ofs + 1]) << 16); // r
    } else {
        return 0;
    }
}

uint32_t Adafruit_NeoPixel::Color(uint8_t r, uint8_t g, uint8_t b) {
    return ((uint32_t)r << 16) | ((uint32_t)g <<  8) | b;
}

uint8_t *Adafruit_NeoPixel::getPixels() const {
    return _pixels;
}

uint16_t Adafruit_NeoPixel::numPixels() const {
    return _numberOfLEDs;
}

void Adafruit_NeoPixel::setCyrWheelView(CDCyrWheelView *view) {
    _cyrWheelView = view;
    _cyrWheelView.numberOfLEDs = _numberOfLEDs;
}


