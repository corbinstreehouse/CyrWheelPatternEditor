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
#import "CyrWheelPatternEditor-Swift.h"

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

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    return NSPasteboardWritingPromised;
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

+ (NSSet *)keyPathsForValuesAffectingBitmapOptionsEnabled
{
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingBitmapOptionsShouldInterpolate {
    return [NSSet setWithObject:@"patternOptions"];
}

+ (NSSet *)keyPathsForValuesAffectingBitmapOptionsShouldStrechBitmap {
    return [NSSet setWithObject:@"patternOptions"];
}

+ (NSSet *)keyPathsForValuesAffectingNeedsColor {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingDisplayColor {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingPatternTypeNeedsPatternDuration {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingPatternSpeedEnabled {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingPatternTypeEnabled {
    return [NSSet setWithObject:@"patternType"];
}

+ (NSSet *)keyPathsForValuesAffectingDisplayName {
    return [NSSet setWithObjects:@"patternType", @"imageFilename", nil];
}

+ (NSSet *)keyPathsForValuesAffectingDisplayImage {
    return [NSSet setWithObjects:@"patternType", @"imageFilename", nil];
}

+ (NSSet *)keyPathsForValuesAffectingPatternSpeed {
    return [NSSet setWithObject:@"patternDuration"];
}

@dynamic patternTypeEnabled;

- (BOOL)patternTypeEnabled {
    if (self.patternType != LEDPatternTypeBitmap && self.patternType != LEDPatternTypeImageReferencedBitmap) {
        return YES;
    } else {
        return NO;
    }
}

BOOL CDPatternTypeNeedsColor(LEDPatternType patternType) {
    switch (patternType) {
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

- (BOOL)needsColor {
    return CDPatternTypeNeedsColor(self.patternType);
}

@dynamic displayColor;

- (void)setDisplayColor:(NSColor *)displayColor {
    self.encodedColor = [CDEncodedColorTransformer intFromColor:displayColor];
}

- (NSColor *)displayColor {
    if (self.needsColor) {
        return [CDEncodedColorTransformer colorFromInt:self.encodedColor];
    } else {
        return [NSColor blackColor]; // Looks better when "disabled"
    }
}

- (NSImage *)displayImage {
    // Only show it if we have an image type.
    if (self.patternType == LEDPatternTypeBitmap || self.patternType == LEDPatternTypeImageReferencedBitmap) {
        if (self.imageFilename != nil) {
            const NSURL *patternDir = [CDAppDelegate appDelegate].patternDirectoryURL;
            NSURL *imageURL = [patternDir URLByAppendingPathComponent:self.imageFilename];
            if (imageURL != nil) {
                // TODO: Async loading needed?
                return [[NSImage alloc] initByReferencingURL:imageURL];
            }
        }
    }
    return nil;
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


static double _minPatternTimeIntervalForPatternType(LEDPatternType type) {
    switch (type) {
        case LEDPatternTypeImageReferencedBitmap:
        case LEDPatternTypeBitmap: {
            return .001; // This is the "fastest" we can go
        }
        case LEDPatternTypeBlink: {
            return 0.2; // Let blink go faster..
        }
        case LEDPatternTypeRotatingBottomGlow: {
            return 0.1; // faster!
        }
        case LEDPatternTypeTheaterChase:
            return .01;
        default: {
            return 0.3;
        }
    }
}

static double _maxPatternTimeIntervalForPatternType(LEDPatternType type) {
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
    return _maxPatternTimeIntervalForPatternType(type) - _minPatternTimeIntervalForPatternType(type);
}
#define A (-6.0)

// In seconds
NSTimeInterval CDPatternTimeIntervalForPatternSpeed(double patternSpeed, LEDPatternType patternType) {
    // Faster speed means a shorter duration
    if (patternSpeed <= 0) {
        // Slow speed means longest time..
        return _maxPatternTimeIntervalForPatternType(patternType);
    } else if (patternSpeed >= 1.0) {
        // Linearly process the extra speed down to 0??
        return _minPatternTimeIntervalForPatternType(patternType);
    } else {
        double percentage;
        double speedRange = _speedRangeForPatternType(patternType);
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
        return _minPatternTimeIntervalForPatternType(patternType) + percentage * speedRange;
    }
}

uint32_t CDPatternDurationFromTimeInterval(NSTimeInterval patternDuration) {
    return round(patternDuration * 1000);
}

NSTimeInterval CDPatternTimeIntervalForDuration(uint32_t duration) {
    return (NSTimeInterval)duration / 1000.0;
}

uint32_t CDPatternDurationForPatternSpeed(double patternSpeed, LEDPatternType patternType) {
    return CDPatternDurationFromTimeInterval(CDPatternTimeIntervalForPatternSpeed(patternSpeed, patternType));
}

double CDPatternItemGetSpeedFromDuration(uint32_t patternDurationX, LEDPatternType patternType) {
    NSTimeInterval patternTimeInterval = CDPatternTimeIntervalForDuration(patternDurationX);
    // Long duration is a slow speed
    if (patternTimeInterval >= _maxPatternTimeIntervalForPatternType(patternType)) {
        return 0;
    }
    // Short duration is the fastest speed
    if (patternTimeInterval <= _minPatternTimeIntervalForPatternType(patternType)) {
        return 1.0;
    }
    
    // Somewhere in the middle.... quadratic function, do the inverse of: y=(x-1)^2: x = sqrt(y) + 1
    double baseDuration = patternTimeInterval - _minPatternTimeIntervalForPatternType(patternType);
    
    double percentage;
    double speedRange = _speedRangeForPatternType(patternType);
    percentage = baseDuration / speedRange;
    if (speedRange < 1.0) {
        percentage = log(percentage) / A;
    } else {
        percentage = 1.0 - percentage;
    }
    return percentage;
}

static double CDPatternItemGetSpeedFromTimeInterval(NSTimeInterval timeInterval, LEDPatternType patternType) {
    return CDPatternItemGetSpeedFromDuration(CDPatternDurationFromTimeInterval(timeInterval), patternType);
}

- (void)setPatternSpeed:(double)patternSpeed {
    self.patternDuration = CDPatternTimeIntervalForPatternSpeed(patternSpeed, self.patternType);
}

- (double)patternSpeed {
    // To make it confusing, patternDurationo is a time interval!
    return CDPatternItemGetSpeedFromTimeInterval(self.patternDuration, self.patternType);
}

@dynamic patternSpeedEnabled;

- (BOOL)patternSpeedEnabled {
    return CDPatternItemGetSpeedEnabled(self.patternType);
}

BOOL CDPatternItemGetSpeedEnabled(LEDPatternType patternType) {
    if (LEDPatterns::PatternDurationShouldBeEqualToSegmentDuration(patternType)) {
        return NO;
    }
    
    return LEDPatterns::PatternNeedsDuration(patternType);
}

+ (NSString *)pasteboardType {
    return PATTERN_ITEM_PASTEBOARD_TYPE;
}

@synthesize bitmapOptionsShouldInterpolate;
@synthesize bitmapOptionsShouldStrechBitmap;
@synthesize bitmapOptionsEnabled;

- (BOOL)bitmapOptionsEnabled {
    return self.patternType == LEDPatternTypeBitmap || self.patternType == LEDPatternTypeImageReferencedBitmap;
}

- (BOOL)bitmapOptionsShouldStrechBitmap {
    return LEDPatternOptions(self.patternOptions).bitmapOptions.shouldStrechBitmap;
}

- (void)setBitmapOptionsShouldStrechBitmap:(BOOL)value {
    LEDPatternOptions options = self.patternOptions;
    options.bitmapOptions.shouldStrechBitmap = value;
    self.patternOptions = options.raw;
}

-(void)setBitmapOptionsShouldInterpolate:(BOOL)value {
    LEDPatternOptions options = self.patternOptions;
    options.bitmapOptions.shouldInterpolate = value;
    self.patternOptions = options.raw;
}

- (BOOL)bitmapOptionsShouldInterpolate {
    return LEDPatternOptions(self.patternOptions).bitmapOptions.shouldInterpolate;
}


@end

uint32_t CDPatternItemHeaderGetFilenameLength(const CDPatternItemHeader *header) {
    return header->filenameLength;
}
