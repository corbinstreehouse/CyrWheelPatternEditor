//
//  CDPatternSimulatorDocument.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDPatternSequence.h"

@class CDCyrWheelView;

@interface CDPatternSimulatorDocument : NSPersistentDocument {
@private
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    NSURL *_baseURL;
}

@property(retain, readonly) CDPatternSequence *patternSequence;
@property(retain, readonly) NSString *sequenceName;
@property(retain, readonly) NSString *patternTypeName;
@property(readonly) NSTimeInterval patternDuration;
@property(readonly) NSTimeInterval patternRepeatDuration;
//@property(readonly) NSTimeInterval patternRepeatCount;

- (NSTimeInterval)patternTimePassedFromFirstTimedPattern;
@property(readonly) NSTimeInterval patternTimePassed;

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError;

- (void)priorSequence;
- (void)loadNextSequence;
- (void)performButtonClick;
- (void)start;
- (void)stop;
- (BOOL)isRunning;
- (void)setCyrWheelView:(CDCyrWheelView *)view;

- (void)play;
- (void)pause;

- (void)reload;
@end
