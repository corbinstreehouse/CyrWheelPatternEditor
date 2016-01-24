//
//  CDPatternItem.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternItem.h"
#import "CDEncodedColorTransformer.h"
#import "LEDPatterns.h"
#import "CDPatternItemNames.h"

@implementation CDPatternItem

#define PATTERN_ITEM_PASTEBOARD_TYPE @"com.corbinstreehouse.patternitem"

@dynamic imageFilename, patternType, duration, patternEndCondition, /*repeatCount,*/ durationEnabled, encodedColor, needsColor, shouldSetBrightnessByRotationalVelocity, patternOptions, patternDuration, patternTypeNeedsPatternDuration, displayName;


+ (instancetype)newItemInContext:(NSManagedObjectContext *)context {
    CDPatternItem *result = [NSEntityDescription insertNewObjectForEntityForName:[self className] inManagedObjectContext:context];
    result.duration = 3;
    result.patternSpeed = 0.5; // Sets the patternDuration
    result.patternEndCondition = CDPatternEndConditionAfterDuration;
    result.encodedColor = [CDEncodedColorTransformer intFromColor:NSColor.blueColor];
    return result;
}

- (void)copyTo:(CDPatternItem *)item {
    NSArray *attributeNameArray = [[NSArray alloc] initWithArray:self.entity.attributesByName.allKeys];
    for (NSString *attributeName in attributeNameArray) {
        [item setValue:[self valueForKey:attributeName] forKey:attributeName];
    }
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

- (BOOL)durationEnabled {
    return YES; // self.patternType != CDDurationTypeUntilButtonClick;
}

+ (NSSet *)keyPathsForValuesAffectingDurationEnabled {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingNeedsColor {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingPatternTypeNeedsPatternDuration {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingPatternSpeedEnabled {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingDisplayName {
    return [NSSet setWithObjects:@"patternType", @"imageFilename", nil];
}

+ (NSSet *)keyPathsForValuesAffectingPatternSpeed {
    return [NSSet setWithObject:@"patternDuration"];
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

//- (NSMutableData *)_encodeRepAsRGB:(NSBitmapImageRep *)imageRep {
//    NSMutableData *result = [NSMutableData new];
//    // pre-allocate cuz we know the size
//    NSInteger length = sizeof(uint8) * 3 * imageRep.pixelsWide * imageRep.pixelsHigh;
//    [result setLength:length];
//    uint8 *bytes = (uint8 *)result.mutableBytes;
//    // Go from top to bottom, and scan horizontal lines. That is the easiest thing to do for all images. How we interpret the data is up to the kind (although, that might affect encoding..)
//    for (NSInteger y = 0; y < imageRep.pixelsHigh; y++) {
//        for (NSInteger x = 0; x < imageRep.pixelsWide; x++) {
//            NSColor *color = [imageRep colorAtX:x y:y]; // convert to NSDeviceRGB?? or calibrated RBG? Otherwise, this will throw...
//            // Write out the pixels.. RGB..ignore alpha
//            CGFloat r, g, b, a;
//            [color getRed:&r green:&g blue:&b alpha:&a];
//            *bytes = r*255;
//            bytes++;
//            *bytes = g*255;
//            bytes++;
//            *bytes = b*255;
//            bytes++;
//        }
//    }
//    return result;
//}

- (BOOL)patternTypeNeedsPatternDuration {
    return LEDPatterns::PatternNeedsDuration(self.patternType);
}

- (NSString *)displayName {
    // The bitmap image types show the name of the file
    if (self.patternType == LEDPatternTypeImageReferencedBitmap || self.patternType == LEDPatternTypeBitmap) {
        return self.imageFilename;
    } else {
        return g_patternTypeNames[self.patternType];
    }
}

// For the speed, I abitrarily pick  half a second as the time for it to do "one tick" of its pattern, and the speed (or duration on how long the pattern runs before repeating) is based off of that. 100% should represent the "fastest" the pattern can go, and 0% represent the slowest...which just means a longer time.
/*
 Speed:     0%          50%         100%
            ----------------------------
 Duration:  2s          1s        .01s (or wahtever)
 
 */
@dynamic patternSpeed;


static double _minPatternDurationForPatternType(LEDPatternType type) {
    switch (type) {
        case LEDPatternTypeImageReferencedBitmap:
        case LEDPatternTypeBitmap: {
            return .001; // This is the "fastest" we can go
        }
        case LEDPatternTypeBlink: {
            return 0.2; // Let blink go faster..
        }
        case LEDPatternTypeTheaterChase:
            return .01;
        default: {
            return 0.3;
        }
    }
}

static double _maxPatternDurationForPatternType(LEDPatternType type) {
    switch (type) {
        case LEDPatternTypeImageReferencedBitmap:
        case LEDPatternTypeBitmap: {
            return 0.5; // Each tick will be half a second
        }
        case LEDPatternTypeTheaterChase:
            return 2;
        default: {
            return 3; // 3 Seconds for each tick of a rainbow at the slowest
        }
    }
}

static double _speedRangeForPatternType(LEDPatternType type) {
    return _maxPatternDurationForPatternType(type) - _minPatternDurationForPatternType(type);
}

#define A (-6.0)
- (void)setPatternSpeed:(double)patternSpeed {
    // Faster speed means a shorter duration
    if (patternSpeed <= 0) {
        // Slow speed means longest time..
        self.patternDuration = _maxPatternDurationForPatternType(self.patternType);
    } else if (patternSpeed >= 1.0) {
        // Linearly process the extra speed down to 0??
        self.patternDuration = _minPatternDurationForPatternType(self.patternType);
    } else {
        double percentage;
        double speedRange = _speedRangeForPatternType(self.patternType);
        if (speedRange < 1.0) {
            // quadratic
            //    y=(x-1)^2
    //        double percentage = (patternSpeed-1)*(patternSpeed-1); // gives a percentage value
            // y = e^(-4x)
            percentage = exp(A*patternSpeed);
        } else {
            // linear
            percentage = 1.0 - patternSpeed;
        }
        // add in the min
        self.patternDuration = _minPatternDurationForPatternType(self.patternType) + percentage * speedRange;
    }
}

- (double)patternSpeed {
    double patternDuration = self.patternDuration;
    // Long duration is a slow speed
    if (patternDuration >= _maxPatternDurationForPatternType(self.patternType)) {
        return 0;
    }
    // Short duration is the fastest speed
    if (patternDuration <= _minPatternDurationForPatternType(self.patternType)) {
        return 1.0;
    }
    
    // Somewhere in the middle.... quadratic function, do the inverse of: y=(x-1)^2: x = sqrt(y) + 1
    double baseDuration = self.patternDuration - _minPatternDurationForPatternType(self.patternType);
    
    double percentage;
    double speedRange = _speedRangeForPatternType(self.patternType);
    if (speedRange < 1.0) {
        percentage = log(baseDuration) / A;
    } else {
        percentage = patternDuration / speedRange;
        percentage = 1.0 - percentage;
    }
    return percentage;
}

@dynamic patternSpeedEnabled;

- (BOOL)patternSpeedEnabled {
    if (LEDPatterns::PatternDurationShouldBeEqualToSegmentDuration(self.patternType)) {
        return NO;
    }

    return LEDPatterns::PatternNeedsDuration(self.patternType);
}


@end
