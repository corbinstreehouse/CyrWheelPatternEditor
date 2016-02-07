//
//  CDTimeFormatter.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 9/25/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDTimeValueTransformer.h"

@implementation CDTimeValueTransformer


+ (Class)transformedValueClass {
    return [NSString class];
};    // class of the "output" objects, as returned by transformedValue:

+ (BOOL)allowsReverseTransformation {
    return NO;
}

static const NSUInteger SECONDS_PER_MINUTE = 60;
static const NSUInteger MINUTES_PER_HOUR = 60;
static const NSUInteger SECONDS_PER_HOUR = 3600;
static const NSUInteger HOURS_PER_DAY = 24;

- (id)transformedValue:(id)value {
    
    NSTimeInterval time = [value doubleValue];
    NSUInteger wholeSeconds = (NSUInteger)time;
    NSUInteger milliseconds = (NSUInteger)(100 * (time - wholeSeconds));
    
    NSUInteger hours = (wholeSeconds / SECONDS_PER_HOUR) % HOURS_PER_DAY;
    NSUInteger minutes = (wholeSeconds / SECONDS_PER_MINUTE) % MINUTES_PER_HOUR;
    NSUInteger seconds = wholeSeconds % SECONDS_PER_MINUTE;
    
    NSString *result;
    if (hours > 0) {
         result = [NSString stringWithFormat:@"%.1ld:%.2ld:%.2ld:%.2ld", hours, minutes, seconds, milliseconds];
    } else {
        result = [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld", minutes, seconds, milliseconds];
    }
    return result;
}


@end


@implementation CDBoolTransformer


+ (Class)transformedValueClass {
    return [NSString class];
};    // class of the "output" objects, as returned by transformedValue:

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value boolValue]) {
        return @"Yes";
    } else {
        return @"No";
    }
}



@end