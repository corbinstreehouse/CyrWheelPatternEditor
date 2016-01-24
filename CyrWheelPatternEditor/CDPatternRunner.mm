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

#define USE_TIMER 1

@interface CDPatternRunner() {
@private
    CWPatternSequenceManager _sequenceManager;
    NSManagedObjectContext *_context;
    NSPersistentStoreCoordinator *_coordinator;
}
@end


@implementation CDPatternRunner

static void _wheelChangedHandler(CDWheelChangeReason changeReason, void *data) {
    CDPatternRunner *doc = (__bridge CDPatternRunner *)data;
    [doc _wheelChanged:changeReason];
}

- (id)initWithPatternDirectoryURL:(NSURL *)patternDirectoryURLX {
    self = [super init];
    _sequenceManager.init();
    _sequenceManager.pause(); // Start out paused
    _sequenceManager.setWheelChangeHandler(_wheelChangedHandler, (__bridge void*)self);
    self.patternDirectoryURL = patternDirectoryURLX;
    _sequenceManager.setPatternDirectoryURL(patternDirectoryURLX);
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
#if USE_TIMER
// One timer to rul them all
NSTimer *g_timer = nil;
#else
static NSThread *g_runningThread = nil;
#endif

static OSSpinLock g_runningPatternsLock = OS_SPINLOCK_INIT;
static NSMutableSet *g_runningPatterns = [NSMutableSet set];

#if !USE_TIMER

// Called on a background thread
+ (void)_processPatterns {
    //        // Speed of the teensy...96000000 == 96Mhz 14 loops per usec.. according to source
    static const NSTimeInterval durationForTick = 1.0/120.0;
    NSTimeInterval lastTick = [NSDate timeIntervalSinceReferenceDate];
    
    while (1) {
        bool isDone = false;
        OSSpinLockLock(&g_runningPatternsLock);
        if (g_runningPatterns.count == 0) {
            // dead; let us die..
            g_runningThread = nil;
            isDone = true;
        }
        OSSpinLockUnlock(&g_runningPatternsLock);
 
        if (!isDone) {
            // See if we should tick..
            NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
            if (now - lastTick >= durationForTick) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self _tickAllPatternRunners];
                });
                lastTick = now;
            }
        }
    }
}
#endif

+ (void)_tickAllPatternRunners {
#if USE_TIMER
    if (g_runningPatterns.count == 0) {
        [g_timer invalidate];
        g_timer = nil;
        return;
    }
#endif
    // no lock needed because it is only ever modified on the foreground thread
    for (CDPatternRunner *runner in g_runningPatterns) {
        [runner _tick:nil];
    }
}

- (void)_makeTimerIfNeeded {
#if USE_TIMER
    if (g_timer == nil) {
        NSTimeInterval time = 1.0/60.0;
        g_timer = [NSTimer timerWithTimeInterval:time target:[self class] selector:@selector(_tickAllPatternRunners) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:g_timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop mainRunLoop] addTimer:g_timer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop mainRunLoop] addTimer:g_timer forMode:NSEventTrackingRunLoopMode];
    }
#endif
    OSSpinLockLock(&g_runningPatternsLock);

    [g_runningPatterns addObject:self];
#if !USE_TIMER
    if (g_runningThread == nil) {
        g_runningThread = [[NSThread alloc] initWithTarget:[self class] selector:@selector(_processPatterns) object:nil];
        g_runningThread.qualityOfService = NSQualityOfServiceUserInteractive;
        [g_runningThread start];
    }
#endif
    OSSpinLockUnlock(&g_runningPatternsLock);
    
}

@synthesize patternTimePassed;
@synthesize patternTimePassedFromFirstTimedPattern;
@synthesize currentPatternItem;
@synthesize currentPatternSequence;

- (void)_tick:(NSTimer *)sender {
    if (!_sequenceManager.isPaused()) {
        _sequenceManager.process();
        // ms -> s
        self.patternTimePassed = _sequenceManager.getPatternTimePassed() / 1000.0;
        self.patternTimePassedFromFirstTimedPattern = _sequenceManager.getPatternTimePassedFromFirstTimedPattern() / 1000.0;
    }
}

- (void)_stopTimerIfNeeded {
    OSSpinLockLock(&g_runningPatternsLock);
    [g_runningPatterns removeObject:self];
    OSSpinLockUnlock(&g_runningPatternsLock);
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

@synthesize patternDirectoryURL;

@dynamic baseURL;
- (void)setBaseURL:(NSURL *)url {
    _sequenceManager.setBaseURL(url);
}

- (NSURL *)baseURL {
    return _sequenceManager.getBaseURL();
}

- (void)setCurrentSequenceName:(NSString *)name {
#warning this doesn't work yet..
//    _sequenceManager.setCurrentSequenceWithName(name.UTF8String);
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

- (void)moveToTheStart {
    _sequenceManager.restartCurrentSequence();
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

- (void)loadFromData:(NSData *)data {
    FatFile fileInMemory = FatFile();
    fileInMemory.setData(data);
    _sequenceManager.loadSequenceInMemoryFromFatFile(&fileInMemory);
    fileInMemory.close();
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
