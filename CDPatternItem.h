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


@interface CDPatternItem : NSManagedObject

@property (nonatomic, retain) NSData *imageData;
@property (nonatomic) CDPatternType patternType;
@property (nonatomic) int32_t duration;
@property (nonatomic) CDDurationType durationType;
@property (nonatomic, readonly) BOOL patternTypeRequiresImageData;

+ (instancetype)newItemInContext:(NSManagedObjectContext *)context;

- (NSData *)getImageDataWithEncoding:(CDPatternEncodingType)encodingType;


@end 
