//
//  CDEncodedColorTransformer.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/26/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDPatternData.h"

NS_ASSUME_NONNULL_BEGIN

@interface CDEncodedColorTransformer : NSValueTransformer

+ (NSColor *)colorFromInt:(int)integer;
+ (NSColor *)colorFromCRGBColor:(CRGB)color;
+ (int)intFromColor:(NSColor *)color;

@end

NS_ASSUME_NONNULL_END