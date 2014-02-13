//
//  Adafruit_NeoPixel.cpp
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/12/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#include "Adafruit_NeoPixel.h"


Adafruit_NeoPixel::Adafruit_NeoPixel(uint16_t n, uint8_t p, uint8_t t) {

}

Adafruit_NeoPixel::~Adafruit_NeoPixel() {
    
}

void Adafruit_NeoPixel::begin() {
    
}

void Adafruit_NeoPixel::show() {
    
}

void Adafruit_NeoPixel::setPixelColor(uint16_t n, uint8_t r, uint8_t g, uint8_t b) {
    
}

void Adafruit_NeoPixel::setPixelColor(uint16_t n, uint32_t c) {
    
}

void Adafruit_NeoPixel::setBrightness(uint8_t) {
    
}

uint32_t Adafruit_NeoPixel::getPixelColor(uint16_t n) const {
    return 0;
}

uint32_t Adafruit_NeoPixel::Color(uint8_t r, uint8_t g, uint8_t b) {
    return ((uint32_t)r << 16) | ((uint32_t)g <<  8) | b;
}

uint8_t *Adafruit_NeoPixel::getPixels() const {
    return 0;
}

uint16_t Adafruit_NeoPixel::numPixels(void) const {
    return 0;
}


