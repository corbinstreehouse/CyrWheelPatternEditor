//
//  CDPatternRunner.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/5/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

#import "CDPatternRunner.h"

#import "CDPatternItem.h"
#import "CDPatternSequence.h"
#import "CDCyrWheelView.h"

#import "CWPatternSequenceManager.h"
#import "SdFat.h"


@interface CDPatternRunner() {
@private
    CWPatternSequenceManager _sequenceManager;
    NSTimer *_timer;
    NSManagedObjectContext *_context;
    NSPersistentStoreCoordinator *_coordinator;
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
    [self _loadCurrentSequence];
    return self;
}

- (void)dealloc {
    if (self.currentPatternSequence) {
        [_context deleteObject:self.currentPatternSequence];
        self.currentPatternSequence = nil;
    }
}

- (void)_wheelChanged:(CDWheelChangeReason)changeReason {
    switch (changeReason) {
        case CDWheelChangeReasonPatternChanged: {
            [self _loadCurrentPatternItem];
            break;
        }
        case CDWheelChangeReasonSequenceChanged: {
            [self _loadCurrentSequence];
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
@synthesize currentPatternItem;
@synthesize currentPatternSequence;

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

@dynamic baseURL;
- (void)setBaseURL:(NSURL *)url {
    _sequenceManager.setBaseURL(url);
}

- (NSURL *)baseURL {
    return _sequenceManager.getBaseURL();
}

- (void)setCurrentSequenceName:(NSString *)name {
    _sequenceManager.setCurrentSequenceWithName(name.UTF8String);
}

- (void)priorPatternItem {
    _sequenceManager.priorPatternItem();
}

- (void)nextPatternItem {
    _sequenceManager.nextPatternItem();
}

- (void)loadNextSequence {
    _sequenceManager.loadNextSequence();
}

- (void)priorSequence {
    _sequenceManager.loadPriorSequence();
}

- (void)loadCurrentSequence {
    _sequenceManager.loadCurrentSequence();
}

- (void)performButtonClick {
    _sequenceManager.buttonClick();
}

+ (NSManagedObjectModel *)_sharedManagedObjectModel {
    static NSManagedObjectModel *model;
    if (model == nil) {
        model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
    }
    return model;
}

- (NSString *)_currentSequenceName {
    char fullFilenamePath[MAX_PATH];
    if (_sequenceManager.getCurrentPatternFileName(fullFilenamePath, MAX_PATH)) {
        return [NSString stringWithCString:fullFilenamePath encoding:NSASCIIStringEncoding];
    } else {
        return @"Default Sequence";
    }
}

- (void)_loadCurrentSequence {
    if (_context == nil) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[self class] _sharedManagedObjectModel]];
        _context.persistentStoreCoordinator = _coordinator;
    }
    NSManagedObjectContext *context = _context;
    [[context undoManager] disableUndoRegistration];
    // Convert the sequenceManager to the pattern sequence
    if (self.currentPatternSequence) {
        [context deleteObject:self.currentPatternSequence];
    }
    CDPatternSequence *patternSequence = [CDPatternSequence newPatternSequenceInContext:context];
    patternSequence.name = [self _currentSequenceName];
    
    NSMutableOrderedSet *newChildren = [NSMutableOrderedSet new];
    for (uint32_t i = 0; i < _sequenceManager.getNumberOfPatternItems(); i++) {
        CDPatternItemHeader *header = _sequenceManager.getPatternItemHeaderAtIndex(i);
        CDPatternItem *item;
        item = [CDPatternItem newItemInContext:context];
        item.patternType = header->patternType;
        item.duration = header->duration / 1000; // Header stores it in MS
        item.patternEndCondition = header->patternEndCondition;
        item.patternDuration = header->patternDuration;
        item.patternOptions = header->patternOptions.raw;
        item.encodedColor = header->color;
        // data not needed...yet??
        //        if (header->data) {
        //            NSData *data = [[NSData alloc] initWithBytes:(const void *)header->data length:header->dataLength];
        //            item.imageData = data;
        //        }
        [newChildren addObject:item];
    }
    patternSequence.children = newChildren;
    self.currentPatternSequence = patternSequence;
    
    [self _loadCurrentPatternItem];
    [[context undoManager] enableUndoRegistration];
    
}

- (void)_loadCurrentPatternItem {
    NSInteger index = _sequenceManager.getCurrentPatternItemIndex();
    if (index != -1) {
        self.currentPatternItem = self.currentPatternSequence.children[index];
    } else {
        self.currentPatternItem = nil;
    }
}

- (void)setCyrWheelView:(CDCyrWheelView *)view {
    _sequenceManager.setCyrWheelView(view);
}

@end
