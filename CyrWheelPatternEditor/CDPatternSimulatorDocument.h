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
@property(retain, readonly) NSString *patternTypeName;
@property(readonly) NSTimeInterval patternDuration;


- (void)loadNextSequence;
- (void)performButtonClick;
- (void)start;
- (void)stop;
- (BOOL)isRunning;

@end
