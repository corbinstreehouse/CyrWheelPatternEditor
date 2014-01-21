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

@property (nonatomic, retain) NSData *image;
@property (nonatomic) CDPatternType patternType;
@property (nonatomic) int64_t pixelCount;
@property (nonatomic) NSTimeInterval duration; // seconds

@end 
