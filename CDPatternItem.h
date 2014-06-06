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


@interface CDPatternItem : NSManagedObject<NSPasteboardWriting, NSPasteboardReading, NSCoding>

@property (nonatomic, retain) NSData *imageData;
@property (nonatomic) LEDPatternType patternType;
@property (nonatomic) double duration; // in seconds
@property (nonatomic) int32_t repeatCount;
@property (nonatomic) uint32_t encodedColor;
@property (nonatomic) CDPatternEndCondition patternEndCondition;
@property (nonatomic) int16_t shouldSetBrightnessByRotationalVelocity;

@property (nonatomic, readonly) BOOL patternTypeRequiresImageData; // synthesized for bindings
@property (nonatomic, readonly) BOOL durationEnabled; // synthesized for bindings
@property (nonatomic, readonly) BOOL repeatCountEnabled; // synthesized for bindings
@property (nonatomic, readonly) BOOL needsColor; // synthesized for bindings

+ (instancetype)newItemInContext:(NSManagedObjectContext *)context;

+ (void)setCurrentContext:(NSManagedObjectContext *)context;

- (NSData *)getImageDataWithEncoding:(CDPatternEncodingType)encodingType;
- (void)copyTo:(CDPatternItem *)item;


@end 
