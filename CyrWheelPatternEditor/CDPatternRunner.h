//
//  CDPatternRunner.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CDCyrWheelView, CDPatternSequence, CDPatternItem;

NS_ASSUME_NONNULL_BEGIN

@interface CDPatternRunner : NSObject

- (void)play;
- (void)pause;

- (void)loadCurrentSequence; // "reload"
- (void)loadNextSequence;
- (void)priorSequence;
- (void)nextPatternItem;
- (void)priorPatternItem;
- (void)performButtonClick;

@property(readonly, getter=isPaused) BOOL paused;

// KVO compliant
@property NSTimeInterval patternTimePassed;
@property NSTimeInterval patternTimePassedFromFirstTimedPattern;
@property (nullable) CDPatternItem *currentPatternItem;
@property (nullable) CDPatternSequence *currentPatternSequence;

@property (nullable) NSURL *baseURL; // optional
- (void)setCurrentSequenceName:(NSString *)name; // Call after setBaseURL is called
- (void)setCyrWheelView:(nullable CDCyrWheelView *)view;


@end

NS_ASSUME_NONNULL_END