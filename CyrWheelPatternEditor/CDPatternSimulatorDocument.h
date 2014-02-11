//
//  CDPatternSimulatorDocument.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDPatternSequence.h"

@interface CDPatternSimulatorDocument : NSPersistentDocument

@property(retain, readonly) CDPatternSequence *patternSequence;
@property(retain, readonly) NSString *sequenceName;

- (void)loadNextSequence;

@end
