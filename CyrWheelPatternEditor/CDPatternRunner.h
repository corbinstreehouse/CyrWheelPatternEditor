//
//  CDPatternRunner.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LEDPatternType.h"

@class CDCyrWheelView, CDPatternSequence, CDPatternItem;

NS_ASSUME_NONNULL_BEGIN

@interface CDPatternRunner : NSObject

- (instancetype)initWithPatternDirectoryURL:(NSURL *)patternDirectoryURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)play;
- (void)pause;

- (void)loadCurrentSequence; // "reload"
- (void)loadNextSequence;
- (void)priorSequence;
- (void)nextPatternItem;
- (void)priorPatternItem;
- (void)rewind; // Like prior, but more like rewind to reset the current if needed, or go back if paused or near the start
- (void)performButtonClick;

- (void)moveToTheStart;

// Load squence from data in memory.. or
- (void)loadFromData:(NSData *)data;
// Load a preview item
- (void)loadDynamicPatternType:(LEDPatternType)type patternSpeed:(double)speed patternColor:(NSColor *)color;
- (void)loadDynamicBitmapPatternTypeWithFilename:(NSString *)filename patternSpeed:(double)speed bitmapOptions:(LEDBitmapPatternOptions)bitmapOptions;
- (void)setBlackAndPause;

@property(readonly, getter=isPaused) BOOL paused;

// KVO compliant

// NOTE: these time values are old...I'm using them in the simulator; playheadTimePosition could now be used
@property NSTimeInterval patternTimePassed;
@property NSTimeInterval patternTimePassedFromFirstTimedPattern;

@property NSTimeInterval playheadTimePosition; // CDPatternRunnerPlayheadTimePositionKey

@property (nullable) CDPatternItem *currentPatternItem;
@property (readonly, nullable) CDPatternSequence *currentPatternSequence; // Not settable from outside (TODO: make readonly here)

@property (retain, nullable) NSURL *baseURL; // optional
@property (retain) NSURL *patternDirectoryURL; // required!

- (void)setCurrentSequenceName:(NSString *)name; // Call after setBaseURL is called
- (void)setCyrWheelView:(nullable CDCyrWheelView *)view;


@end

extern NSString * const CDPatternRunnerPlayheadTimePositionKey;

NS_ASSUME_NONNULL_END