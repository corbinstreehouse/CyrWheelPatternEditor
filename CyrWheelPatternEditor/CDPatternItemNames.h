//
//  CDPatternItemNames.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/3/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LEDPatternType.h"

NS_ASSUME_NONNULL_BEGIN

@interface CDPatternItemNames: NSObject

+ (NSString *)nameForPatternType:(LEDPatternType)type;

@end

extern NSString *g_patternTypeNames[LEDPatternTypeCount+1];

NS_ASSUME_NONNULL_END