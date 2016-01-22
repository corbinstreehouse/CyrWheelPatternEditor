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

- (instancetype)initWithPatternDirectoryURL:(NSURL *)patternDirectoryURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)play;
- (void)pause;

- (void)loadCurrentSequence; // "reload"
- (void)loadNextSequence;
- (void)priorSequence;
- (void)nextPatternItem;
- (void)priorPatternItem;
- (void)performButtonClick;

- (void)moveToTheStart;

- (void)loadFromData:(NSData *)data;

@property(readonly, getter=isPaused) BOOL paused;

// KVO compliant
@property NSTimeInterval patternTimePassed;
@property NSTimeInterval patternTimePassedFromFirstTimedPattern;
@property (nullable) CDPatternItem *currentPatternItem;
@property (nullable) CDPatternSequence *currentPatternSequence;

@property (retain, nullable) NSURL *baseURL; // optional
@property (retain) NSURL *patternDirectoryURL; // required!

- (void)setCurrentSequenceName:(NSString *)name; // Call after setBaseURL is called
- (void)setCyrWheelView:(nullable CDCyrWheelView *)view;


@end

NS_ASSUME_NONNULL_END