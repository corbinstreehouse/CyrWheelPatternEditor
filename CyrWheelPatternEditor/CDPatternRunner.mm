//
//  CDPatternRunner.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

#import "CDPatternRunner.h"

#import "CWPatternSequenceManager.h"
#import "SdFat.h"


@interface CDPatternRunner() {
@private
    CWPatternSequenceManager _sequenceManager;
    NSTimer *_timer;
}
@end


@implementation CDPatternRunner

static void _wheelChangedHandler(CDWheelChangeReason changeReason, void *data) {
    CDPatternRunner *doc = (__bridge CDPatternRunner *)data;
    [doc _wheelChanged:changeReason];
}

- (id)init {
    self = [super init];
    _sequenceManager.init();
    _sequenceManager.setWheelChangeHandler(_wheelChangedHandler, (__bridge void*)self);
    return self;
}

- (void)_wheelChanged:(CDWheelChangeReason)changeReason {
    switch (changeReason) {
        case CDWheelChangeReasonPatternChanged: {
            
            break;
        }
        case CDWheelChangeReasonSequenceChanged: {
            break;
        }
        default:
            break;
    }
}

- (void)_makeTimerIfNeeded {
    if (_timer == nil) {
        // Speed of the teensy...96000000 == 96Mhz 14 loops per usec.. according to source
        NSTimeInterval time = 14.0/1000000.0;
        _timer = [NSTimer timerWithTimeInterval:time target:self selector:@selector(_tick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSModalPanelRunLoopMode];
    }
}

@synthesize patternTimePassed;
@synthesize patternTimePassedFromFirstTimedPattern;

- (void)_tick:(NSTimer *)sender {
    _sequenceManager.process();
    // ms -> s
    self.patternTimePassed = _sequenceManager.getPatternTimePassed() / 1000.0;
    self.patternTimePassedFromFirstTimedPattern = _sequenceManager.getPatternTimePassedFromFirstTimedPattern() / 1000.0;
}

- (void)_stopTimerIfNeeded {
    [_timer invalidate];
    _timer = nil;
}

- (void)play {
    [self _makeTimerIfNeeded];
    _sequenceManager.play();
}

- (void)pause {
    [self _stopTimerIfNeeded];
    _sequenceManager.pause();
}

@dynamic paused;
- (BOOL)isPaused {
    return _sequenceManager.isPaused();
}

- (void)setBaseURL:(NSURL *)url {
    _sequenceManager.setBaseURL(url);
}

- (void)setCurrentSequenceName:(NSString *)name {
    _sequenceManager.setCurrentSequenceWithName(name.UTF8String);
}

- (void)nextPatternItem {
    _sequenceManager.nextPatternItem();
}

- (void)loadNextSequence {
    _sequenceManager.loadNextSequence();
//    [self _loadPatternSequence];
}

- (void)priorSequence {
    _sequenceManager.loadPriorSequence();
//    [self _loadPatternSequence];
}


@end
