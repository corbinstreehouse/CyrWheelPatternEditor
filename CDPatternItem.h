//
//  CDPatternItem.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDPatternData.h"
#import "CDTimelineItem.h"
#import "LEDPatternType.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface CDPatternItem : NSManagedObject<NSPasteboardWriting, NSPasteboardReading, NSCoding, CDTimelineItem>

@property (nonatomic, copy) NSString *imageFilename; // The relative filename
@property (nonatomic) LEDPatternType patternType;
@property (nonatomic) double duration; // in seconds
@property (nonatomic) uint32_t encodedColor;
@property (nonatomic) CDPatternEndCondition patternEndCondition;
@property (nonatomic) int16_t shouldSetBrightnessByRotationalVelocity;

@property (nonatomic) double patternDuration; // in seconds; only needs to be set if patternTypeNeedsPatternDuration = YES
@property (nonatomic) uint32_t /*LEDPatternOptions*/ patternOptions; // 32-bit

@property (nonatomic, readonly) BOOL durationEnabled; // synthesized for bindings
@property (nonatomic, readonly) BOOL needsColor; // synthesized for bindings
@property (nonatomic, readonly) BOOL patternTypeNeedsPatternDuration; // corbin, eliminate?
@property (nonatomic, readonly) BOOL patternSpeedEnabled;

@property (nonatomic, readonly) NSString *displayName;

+ (instancetype)newItemInContext:(NSManagedObjectContext *)context;

+ (void)setCurrentContext:(NSManagedObjectContext *)context;

- (void)copyTo:(CDPatternItem *)item;

@property (nonatomic) double patternSpeed; // A float value from 0.0 to 1.0 (100%) (or higher is okay) to determine the speed of which the pattern runs, which is just affects the patternDuration


@end 

