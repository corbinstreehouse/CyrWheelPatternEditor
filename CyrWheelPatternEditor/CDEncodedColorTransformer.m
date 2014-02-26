//
//  CDEncodedColorTransformer.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/26/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDEncodedColorTransformer.h"

@implementation CDEncodedColorTransformer

+ (NSColor *)colorFromInt:(int)rawValue {
    // 32-bit RGB encoding; same as Adafruit_NeoPixel.h
    uint8_t r = (uint8_t)(rawValue >> 16);
    uint8_t g = (uint8_t)(rawValue >> 8);
    uint8_t b = (uint8_t)rawValue;
    return [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}

+ (int)intFromColor:(NSColor *)color {
    NSColor *c = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    CGFloat r, g, b, a;
    [c getRed:&r green:&g blue:&b alpha:&a];
    uint8_t r8 = r*255;
    uint8_t g8 = g*255;
    uint8_t b8 = b*255;
    uint32_t resInt = r8 << 16 | g8 << 8 | b8;
    return resInt;
}

- (id)transformedValue:(id)value {
    if (value != nil) {
        NSAssert([value isKindOfClass:[NSNumber class]], @"class check");
        return [[self class] colorFromInt:[value intValue]];
    } else {
        return nil;
    }
}

- (id)reverseTransformedValue:(id)value {
    if (value != nil) {
        NSAssert([value isKindOfClass:[NSColor class]], @"should be a color");
        uint32_t resInt = [[self class] intFromColor:(NSColor *)value];
        return [NSNumber numberWithInt:resInt];
    } else {
        return nil;
    }
}




@end
