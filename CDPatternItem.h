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

NS_ASSUME_NONNULL_BEGIN

@class NSPasteboard;

@interface CDPatternItem : NSManagedObject<NSPasteboardWriting, NSPasteboardReading, NSCoding, CDTimelineItem>

@property (nullable, nonatomic, copy) NSString *imageFilename; // The relative filename
@property (nonatomic) LEDPatternType patternType;
@property (nonatomic) double duration; // in seconds
@property (nonatomic) uint32_t encodedColor;
@property (nonatomic) CDPatternEndCondition patternEndCondition;
@property (nonatomic) uint32_t shouldSetBrightnessByRotationalVelocity; // Move to options in some way?

@property (nonatomic) double patternDuration; // in seconds; only needs to be set if patternTypeNeedsPatternDuration = YES. aka: NSTimeInterval
@property (nonatomic) uint32_t/*LEDPatternOptions*/ patternOptions; // 32-bit struct (for now..)

@property (nonatomic, readonly) BOOL durationEnabled; // synthesized for bindings
@property (nonatomic, readonly) BOOL needsColor; // synthesized for bindings
@property (nonatomic, readonly) BOOL patternTypeNeedsPatternDuration; // corbin, eliminate?
@property (nonatomic, readonly) BOOL patternSpeedEnabled;

@property (nonatomic, readonly) NSString *displayName;

+ (instancetype)newItemInContext:(NSManagedObjectContext *)context;

// Used when unarchiving for copy/paste
+ (void)setCurrentContext:(nullable NSManagedObjectContext *)context;

+ (NSString *)pasteboardType;

- (void)copyTo:(CDPatternItem *)item;

@property (nonatomic) double patternSpeed; // A float value from 0.0 to 1.0 (100%) (or higher is okay) to determine the speed of which the pattern runs, which is just affects the patternDuration

@property (nonatomic, copy) NSColor *displayColor;
@property (nullable, nonatomic, readonly, copy) NSImage *displayImage;

@property (nonatomic, readonly) BOOL patternTypeEnabled; // UI binding fgor certain types that can't be changed after creation

@end

// In seconds
NSTimeInterval _CDPatternDurationForPatternSpeed(double patternSpeed, LEDPatternType patternType);

// In ms as a uint32
uint32_t _CDPatternDurationFromTimeInterval(NSTimeInterval timeInterval);

NS_ASSUME_NONNULL_END