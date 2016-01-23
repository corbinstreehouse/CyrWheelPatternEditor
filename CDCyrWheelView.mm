//
//  CDCyrWheelView.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/13/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDCyrWheelView.h"

#define LED_SIZE 5
#define LED_SPACING 2

@interface CDCyrWheelView() {
@private
    NSMutableArray *_colors;
}

@end

@implementation CDCyrWheelView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)isOpaque {
    return YES;
}

@synthesize numberOfLEDs = _numberOfLEDs;

- (void)setPixelColor:(NSColor *)color atIndex:(NSInteger)index {
    NSAssert(index >= 0 && index < _numberOfLEDs, @"count check");
    if (_colors == nil || _colors.count != _numberOfLEDs) {
        _colors = [NSMutableArray new];
        for (NSInteger i = 0; i < _numberOfLEDs; i++) {
            [_colors addObject:NSNull.null];
        }
    }
    _colors[index] = color;
}

- (NSColor *)getPixelColorAtIndex:(NSInteger)index {
    if (_colors[index] == NSNull.null) {
        return [NSColor blackColor];
    } else {
        return _colors[index];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    [NSColor.blackColor set];
    NSRectFill(self.bounds);

    NSInteger numberOfPixels = _colors.count;
	if (numberOfPixels > 0) {
        
        CGFloat halfWidth = floor(NSWidth(bounds) / 2.0);
        CGFloat halfHeight = floor(NSHeight(bounds) / 2.0);
        // translate our origin to the center
        NSAffineTransform *t = [NSAffineTransform transform];
        [t translateXBy:halfWidth yBy:halfHeight];
        [t concat];

        // Figure out the angle increment per pixel for 2*pi circumfrance
        double incPerPixel = 2.0*M_PI / numberOfPixels;

        // Radius is smaller of the widht or height
        CGFloat radius = MIN(halfWidth, halfHeight) - LED_SIZE;
        
        for (NSInteger i = 0; i < numberOfPixels; i++) {
            // Go clockwise from pi/2 (top); but normally, incrementing along a circle is counter-clockwise, so we subtract the increment per pixel to go backwards from the top origin
            CGFloat currentAngle = M_PI_2 - (incPerPixel*i);
            
            // cos(angle) = x/radius
            // sin(angle) = y/radius
            CGFloat x = cos(currentAngle) * radius;
            CGFloat y = sin(currentAngle) * radius;
            // x,y is the center; back off by half the led size
            x -= LED_SIZE/2.0;
            y -= LED_SIZE/2.0;
            // should hidpi align..but bah
            x = round(x);
            y = round(y);
            
            NSColor *color = [self getPixelColorAtIndex:i];
            [color set];
            NSRectFill(NSMakeRect(x, y, LED_SIZE, LED_SIZE));
        }
    } else {
//        [NSColor.redColor set];
//        NSFrameRect(self.bounds);
    }
}

@end
