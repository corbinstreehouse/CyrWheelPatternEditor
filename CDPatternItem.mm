//
//  CDPatternItem.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternItem.h"
#import "CDEncodedColorTransformer.h"


@implementation CDPatternItem

#define PATTERN_ITEM_PASTEBOARD_TYPE @"com.corbinstreehouse.patternitem"

@dynamic imageData, patternType, duration, patternEndCondition, repeatCount, durationEnabled, repeatCountEnabled, encodedColor, needsColor, shouldSetBrightnessByRotationalVelocity;


+ (instancetype)newItemInContext:(NSManagedObjectContext *)context {
    CDPatternItem *result = [NSEntityDescription insertNewObjectForEntityForName:[self className] inManagedObjectContext:context];
    result.duration = 3;
    result.repeatCount = 1;
    result.patternEndCondition = CDPatternEndConditionOnButtonClick;
    result.encodedColor = [CDEncodedColorTransformer intFromColor:NSColor.blueColor];
    return result;
}

- (void)copyTo:(CDPatternItem *)item {
    NSArray *attributeNameArray = [[NSArray alloc] initWithArray:self.entity.attributesByName.allKeys];
    for (NSString *attributeName in attributeNameArray) {
        [item setValue:[self valueForKey:attributeName] forKey:attributeName];
    }

//    item.duration = self.duration;
//    item.imageData = self.imageData;
//    item.repeatCount = self.repeatCount;
//    item.patternEndCondition = self.patternEndCondition;
//    item.encodedColor = self.encodedColor;
//    item.patternType = self.patternType;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    NSArray *attributeNameArray = [[NSArray alloc] initWithArray:self.entity.attributesByName.allKeys];
    for (NSString *attributeName in attributeNameArray) {
        [aCoder encodeObject:[self valueForKey:attributeName] forKey:attributeName];
    }
}

static NSManagedObjectContext *g_currentContext = nil;

+ (void)setCurrentContext:(NSManagedObjectContext *)context {
    g_currentContext = context;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSAssert(g_currentContext != nil, @"g_currentContext should be set");
    NSManagedObjectContext *context = g_currentContext;
    NSEntityDescription *description = [NSEntityDescription entityForName:[self className] inManagedObjectContext:context];
    
    self = [self initWithEntity:description insertIntoManagedObjectContext:context];

    NSArray *attributeNameArray = [[NSArray alloc] initWithArray:self.entity.attributesByName.allKeys];
    for (NSString * attributeName in attributeNameArray) {
        [self setValue:[aDecoder decodeObjectForKey:attributeName] forKey:attributeName];
    }
    
    return self;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return @[PATTERN_ITEM_PASTEBOARD_TYPE];
}

-(id)pasteboardPropertyListForType:(NSString *)type {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return @[PATTERN_ITEM_PASTEBOARD_TYPE];
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    return [NSKeyedUnarchiver unarchiveObjectWithData:propertyList];
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
    return self.patternType == LEDPatternTypeImageLinearFade || self.patternType == LEDPatternTypeImageEntireStrip;
}

- (BOOL)repeatCountEnabled {
    return self.patternEndCondition == CDPatternEndConditionAfterRepeatCount;
}

- (BOOL)durationEnabled {
    return YES; // self.patternType != CDDurationTypeUntilButtonClick;
}

+ (NSSet *)keyPathsForValuesAffectingPatternTypeRequiresImageData {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingDurationEnabled {
    return [NSSet setWithObjects:@"patternType", nil];
}

+ (NSSet *)keyPathsForValuesAffectingRepeatCountEnabled {
    return [NSSet setWithObjects:@"patternEndCondition", nil];
}

+ (NSSet *)keyPathsForValuesAffectingNeedsColor {
    return [NSSet setWithObject:@"patternType"];
}

- (BOOL)needsColor {
    switch (self.patternType) {
        case LEDPatternTypeColorWipe:
        case LEDPatternTypeFadeIn:
        case LEDPatternTypeTheaterChase:
        case LEDPatternTypeGradient:
        case LEDPatternTypeBottomGlow:
        case LEDPatternTypeWave:
        case LEDPatternTypeRotatingBottomGlow:
        case LEDPatternTypeSolidColor:
            return YES;
        default:
            return NO;
    }
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
