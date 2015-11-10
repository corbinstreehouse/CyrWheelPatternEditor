//
//  CDCyrWheelSequence.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/2/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDCyrWheelSequence.h"

@implementation CDCyrWheelSequence

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if ([other isKindOfClass:[CDCyrWheelSequence class]]) {
        return [self.name isEqualToString:((CDCyrWheelSequence *)other).name]; // stupid simple...
    } else {
        return [super isEqual:other];
    }
}

- (NSUInteger)hash {
    // warning..changing the name after it is in a dictionary will loose it!!
    return self.name.hash;
}

@end
