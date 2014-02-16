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
	if (_colors) {
        NSRect bounds = self.bounds;
        // translate our origin to the center
        NSAffineTransform *t = [NSAffineTransform transform];
        [t translateXBy:floor(NSWidth(bounds) / 2.0) yBy:floor(NSHeight(bounds) / 2.0)];
        
        NSInteger x = self.bounds.origin.x;
        for (NSInteger i = 0; i < _colors.count; i++) {
            NSColor *color = [self getPixelColorAtIndex:i];
            [color set];
            NSRectFill(NSMakeRect(x, 0, LED_SIZE, LED_SIZE));
            x += LED_SIZE + LED_SPACING;
        }
    } else {
        [NSColor.redColor set];
        NSFrameRect(self.bounds);
    }
}

@end
