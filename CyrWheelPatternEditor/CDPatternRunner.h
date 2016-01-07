//
//  CDPatternRunner.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDPatternItem.h"

@interface CDPatternRunner : NSObject

- (void)play;
- (void)pause;

@property(readonly, getter=isPaused) BOOL paused;

// KVO compliant
@property NSTimeInterval patternTimePassed;
@property NSTimeInterval patternTimePassedFromFirstTimedPattern;
@property CDPatternItem *currentPatternItem;

- (void)setBaseURL:(NSURL *)url; // optional
- (void)setCurrentSequenceName:(NSString *)name; // Call after setBaseURL is called

- (void)nextPatternItem;


@end
