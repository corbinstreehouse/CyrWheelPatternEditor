//
//  CDCyrWheelPattern.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/10/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDPatternData.h"

// wraps CDPatternItemHeader
@interface CDCyrWheelPattern : NSObject

@property CDPatternEndCondition patternEndCondition;
@property LEDPatternType patternType;
@property CRGB color;

@end
