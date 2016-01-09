//
//  CDPatternSimulatorDocument.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CDCyrWheelView, CDPatternRunner;

@interface CDPatternSimulatorDocument : NSPersistentDocument {
@private
//    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property(readonly) CDPatternRunner *patternRunner;

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError;

- (void)setCyrWheelView:(CDCyrWheelView *)view;

// These are now all cover methods for the patternRunner
- (void)priorSequence;
- (void)loadNextSequence;
- (void)performButtonClick;
- (void)start;
- (void)stop;
- (BOOL)isRunning;
@property(readonly, getter=isPlaying) BOOL playing; // TODO: bind to the value directly!

- (void)play;
- (void)pause;
- (void)reload;

@end
