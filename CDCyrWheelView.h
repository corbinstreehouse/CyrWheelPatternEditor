//
//  CDCyrWheelView.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/13/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CDCyrWheelView : NSView

@property NSInteger numberOfLEDs;

- (void)setPixelColor:(NSColor *)color atIndex:(NSInteger)index;
- (NSColor *)getPixelColorAtIndex:(NSInteger)index;


@end
