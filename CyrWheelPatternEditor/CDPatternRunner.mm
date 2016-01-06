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

- (id)init {
    self = [super init];
    _sequenceManager.init();
    return self;
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
    // TODO: a callback when the item changes for us to hook into!
//    CDPatternItemHeader *oldHeader = _sequenceManager.getCurrentPatternItemHeader();
    _sequenceManager.process();
//    CDPatternItemHeader *newHeader = _sequenceManager.getCurrentPatternItemHeader();
//    if (oldHeader != newHeader) {
//        [self willChangeValueForKey:@"patternTypeName"];
//        [self didChangeValueForKey:@"patternTypeName"];
//    }
//    // will this be too expensive to do?
//    [self willChangeValueForKey:@"patternTimePassed"];
//    [self didChangeValueForKey:@"patternTimePassed"];
//    [self willChangeValueForKey:@"patternTimePassedFromFirstTimedPattern"];
//    [self didChangeValueForKey:@"patternTimePassedFromFirstTimedPattern"];
    
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
    [self _loadPatternSequence];
}

- (void)priorSequence {
    _sequenceManager.loadPriorSequence();
    [self _loadPatternSequence];
}


@end
