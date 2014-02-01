//
//  CDPatternDataToImageTransformer.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/31/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternDataToImageTransformer.h"

@implementation CDPatternDataToImageTransformer

//+(BOOL)allowsReverseTransformation {
//    return YES;
//}


- (id)transformedValue:(id)value {
    if (value != nil) {
        NSAssert([value isKindOfClass:[NSData class]], @"class check");
        NSData *data = (NSData *)value;
        NSImage *image = [[NSImage alloc] initWithData:data];
        return image;
    } else {
        return nil;
    }
}

- (id)reverseTransformedValue:(id)value {
    if (value != nil) {
        return [value TIFFRepresentation];
    } else {
        return nil;
    }
}


@end
