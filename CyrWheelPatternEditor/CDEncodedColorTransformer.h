//
//  CDEncodedColorTransformer.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/26/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CDEncodedColorTransformer : NSValueTransformer

+ (NSColor *)colorFromInt:(int)integer;
+ (int)intFromColor:(NSColor *)color;

@end
