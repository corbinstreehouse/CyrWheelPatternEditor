//
//  CDPatternItem.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternItem.h"


@implementation CDPatternItem

@dynamic imageData, patternType, duration, durationType;


+ (instancetype)newItemInContext:(NSManagedObjectContext *)context {
    CDPatternItem *result = [NSEntityDescription insertNewObjectForEntityForName:[self className] inManagedObjectContext:context];
    result.duration = 3;
    result.durationType = CDDurationTypeSeconds;
    return result;
}

//- (CDPatternItem *)copyInContext:(NSManagedObjectContext *)context{
//    NSString *entityName = [[source entity] name];
//    
//    //create new object in data store
//    NSManagedObject *cloned = [NSEntityDescription
//                               insertNewObjectForEntityForName:entityName
//                               inManagedObjectContext:context];
//    
//    //loop through all attributes and assign then to the clone
//    NSDictionary *attributes = [[NSEntityDescription
//                                 entityForName:entityName
//                                 inManagedObjectContext:context] attributesByName];
//    
//    for (NSString *attr in attributes) {
//        [cloned setValue:[source valueForKey:attr] forKey:attr];
//    }
//    
//    //Loop through all relationships, and clone them.
//    NSDictionary *relationships = [[NSEntityDescription
//                                    entityForName:entityName
//                                    inManagedObjectContext:context] relationshipsByName];
//    for (NSRelationshipDescription *rel in relationships){
//        NSString *keyName = [NSString stringWithFormat:@"%@",rel];
//        //get a set of all objects in the relationship
//        NSMutableSet *sourceSet = [source mutableSetValueForKey:keyName];
//        NSMutableSet *clonedSet = [cloned mutableSetValueForKey:keyName];
//        NSEnumerator *e = [sourceSet objectEnumerator];
//        NSManagedObject *relatedObject;
//        while ( relatedObject = [e nextObject]){
//            //Clone it, and add clone to set
//            NSManagedObject *clonedRelatedObject = [ManagedObjectCloner clone:relatedObject
//                                                                    inContext:context];
//            [clonedSet addObject:clonedRelatedObject];
//        }
//        
//    }
//    
//    return cloned;
//}

- (BOOL)patternTypeRequiresImageData {
    return self.patternType == CDPatternTypeImageFade; // only type so far..
}

- (BOOL)durationTypeRequiresDuration {
    return self.durationType != CDDurationTypeUntilButtonClick;
}

+ (NSSet *)keyPathsForValuesAffectingPatternTypeRequiresImageData {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingDurationTypeRequiresDuration {
    return [NSSet setWithObjects:@"durationType", nil];
}

- (NSMutableData *)_encodeRepAsRGB:(NSBitmapImageRep *)imageRep {
    NSMutableData *result = [NSMutableData new];
    // pre-allocate cuz we know the size
    NSInteger length = sizeof(uint8) * 3 * imageRep.pixelsWide * imageRep.pixelsHigh;
    [result setLength:length];
    uint8 *bytes = (uint8 *)result.mutableBytes;
    // Go from top to bottom, and scan horizontal lines. That is the easiest thing to do for all images. How we interpret the data is up to the kind (although, that might affect encoding..)
    for (NSInteger y = 0; y < imageRep.pixelsHigh; y++) {
        for (NSInteger x = 0; x < imageRep.pixelsWide; x++) {
            NSColor *color = [imageRep colorAtX:x y:y]; // convert to NSDeviceRGB?? or calibrated RBG? Otherwise, this will throw...
            // Write out the pixels.. RGB..ignore alpha
            CGFloat r, g, b, a;
            [color getRed:&r green:&g blue:&b alpha:&a];
            *bytes = r*255;
            bytes++;
            *bytes = g*255;
            bytes++;
            *bytes = b*255;
            bytes++;
        }
    }
    return result;
}

- (NSData *)getImageDataWithEncoding:(CDPatternEncodingType)encodingType {
    NSAssert(encodingType == CDPatternEncodingTypeRGB24, @"only rgb");
    // encoding type ignored...
    NSData *rawData = self.imageData;
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:rawData];
    NSMutableData *rgbData = [self _encodeRepAsRGB:imageRep];
    return rgbData;
}


@end
