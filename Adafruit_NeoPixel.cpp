//
//  Adafruit_NeoPixel.cpp
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/12/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#include "Adafruit_NeoPixel.h"

#import "CDCyrWheelView.h"


Adafruit_NeoPixel::Adafruit_NeoPixel(uint16_t numberOfLEDs, uint8_t p, uint8_t t) : _numberOfLEDs(numberOfLEDs) {

}

Adafruit_NeoPixel::~Adafruit_NeoPixel() {
    
}

void Adafruit_NeoPixel::begin() {
    
}

void Adafruit_NeoPixel::show() {
    [_cyrWheelView setNeedsDisplay:YES];
}

void Adafruit_NeoPixel::setPixelColor(uint16_t n, uint8_t r, uint8_t g, uint8_t b) {
    NSCAssert(n < _numberOfLEDs, @"bounds check");
    NSCAssert(_cyrWheelView != nil, @"cyr wheel view needs to be around");
    NSColor *color = [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
    [_cyrWheelView setPixelColor:color atIndex:n];
    
}

void Adafruit_NeoPixel::setPixelColor(uint16_t index, uint32_t color) {
    uint8_t r = color >> 16;
    uint8_t g = color >> 8;
    uint8_t b = color;
    setPixelColor(index, r, g, b);
}

void Adafruit_NeoPixel::setBrightness(uint8_t) {
    // TODO: corbin implement if i need/want
}

uint32_t Adafruit_NeoPixel::getPixelColor(uint16_t n) const {
    NSColor *color = [_cyrWheelView getPixelColorAtIndex:n];
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return Color(r*255, g*255, b*255);
}

uint32_t Adafruit_NeoPixel::Color(uint8_t r, uint8_t g, uint8_t b) {
    return ((uint32_t)r << 16) | ((uint32_t)g <<  8) | b;
}

uint8_t *Adafruit_NeoPixel::getPixels() const {
    // Bah, corbin, implement
#warning implement
    return 0;
}

uint16_t Adafruit_NeoPixel::numPixels() const {
    return _numberOfLEDs;
}

void Adafruit_NeoPixel::setCyrWheelView(CDCyrWheelView *view) {
    _cyrWheelView = view;
    _cyrWheelView.numberOfLEDs = _numberOfLEDs;
}


