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


@interface CDPatternItem : NSManagedObject<NSPasteboardWriting/*, NSPasteboardReading*/>

@property (nonatomic, retain) NSData *imageData;
@property (nonatomic) CDPatternType patternType;
@property (nonatomic) double duration; // in seconds
@property (nonatomic) int32_t repeatCount;
@property (nonatomic) int32_t encodedColor;
@property (nonatomic) CDPatternEndCondition patternEndCondition;

@property (nonatomic, readonly) BOOL patternTypeRequiresImageData; // synthesized for bindings
@property (nonatomic, readonly) BOOL durationEnabled; // synthesized for bindings
@property (nonatomic, readonly) BOOL repeatCountEnabled; // synthesized for bindings
@property (nonatomic, readonly) BOOL needsColor; // synthesized for bindings

+ (instancetype)newItemInContext:(NSManagedObjectContext *)context;

- (NSData *)getImageDataWithEncoding:(CDPatternEncodingType)encodingType;


@end 
