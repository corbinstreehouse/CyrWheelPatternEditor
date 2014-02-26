//
//  CDPatternSimulatorDocument.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSimulatorDocument.h"
#import "CDPatternSimulatorWindowController.h"
#import "CDPatternItem.h"
#import "CDPatternItemViewController.h"

#import "CWPatternSequenceManager.h"
#import "SD.h"


@interface CDPatternSimulatorDocument() {
@private
    CWPatternSequenceManager _sequenceManager;
    NSTimer *_timer;
}
@end



// TODO: it would be better to combine the two documents into one that read both, and wrote just one kind.

@implementation CDPatternSimulatorDocument

- (id)init
{
    self = [super init];
    return self;
}

- (void)makeWindowControllers {
    CDPatternSimulatorWindowController *wc = [CDPatternSimulatorWindowController new];
    [self addWindowController:wc];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return YES;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    
    // drop the filename, and use the CWPatternSequenceManager to test loading
    NSURL *baseDirectory = [url URLByDeletingLastPathComponent];
    SDSetBaseDirectoryURL(baseDirectory);

    // Mainly use the same code as the hardware so I can test it
    _sequenceManager.init();
    [self _loadPatternSequence];

    return YES;
}

- (void)_loadPatternSequence {
    [self willChangeValueForKey:@"patternSequence"];
    NSManagedObjectContext *context = self.managedObjectContext;
    [[context undoManager] disableUndoRegistration];
    // Convert the sequenceManager to the pattern sequence
    if (_patternSequence) {
        [context deleteObject:_patternSequence];
    }
    _patternSequence = [CDPatternSequence newPatternSequenceInContext:context];
    _patternSequence.pixelCount = _sequenceManager.getPixelCount();
    NSMutableOrderedSet *newChildren = [NSMutableOrderedSet new];
    for (uint32_t i = 0; i < _sequenceManager.getNumberOfPatternItems(); i++) {
        CDPatternItemHeader *header = _sequenceManager.getPatternItemHeaderAtIndex(i);
        CDPatternItem *item = [CDPatternItem newItemInContext:context];
        item.patternType = header->patternType;
        item.duration = header->duration / 1000; // Header stores it in MS
        item.patternEndCondition = header->patternEndCondition;
        item.repeatCount = header->intervalCount;
        item.encodedColor = header->color;
        if (header->data) {
            NSData *data = [[NSData alloc] initWithBytes:(const void *)header->data length:header->dataLength];
            item.imageData = data;
        }
        [newChildren addObject:item];
    }
    _patternSequence.children = newChildren;
    [[context undoManager] enableUndoRegistration];
    [self didChangeValueForKey:@"patternSequence"];
}

+ (NSSet *)keyPathsForValuesAffectingSequenceName {
    return [NSSet setWithObject:@"patternSequence"];
}

+ (NSSet *)keyPathsForValuesAffectingPatternDuration {
    return [NSSet setWithObjects:@"patternTypeName", nil];
}

+ (NSSet *)keyPathsForValuesAffectingPatternTypeName {
    return [NSSet setWithObjects:@"patternSequence", nil];
}

+ (NSSet *)keyPathsForValuesAffectingRepeatCount {
    return [NSSet setWithObjects:@"patternTypeName", nil];
}

- (NSInteger)patternRepeatCount {
    CDPatternItemHeader *itemHeader = _sequenceManager.getCurrentPatternItemHeader();
    if (itemHeader) {
        return itemHeader->intervalCount;
    }
    return 0;
}

- (void)loadNextSequence {
    _sequenceManager.loadNextSequence();
    [self _loadPatternSequence];
}

- (NSString *)sequenceName {
    if (_sequenceManager.getNumberOfSequenceNames() > 0) {
        char *cstr = _sequenceManager.getSequenceNameAtIndex(_sequenceManager.getCurrentSequenceIndex());
        return [NSString stringWithCString:cstr encoding:NSASCIIStringEncoding];
    }
    return nil;
}

- (NSString *)patternTypeName {
    CDPatternItemHeader *itemHeader = _sequenceManager.getCurrentPatternItemHeader();
    if (itemHeader) {
        return g_patternTypeNames[itemHeader->patternType];
    }
    return @"<None>";
}

- (NSTimeInterval)patternDuration {
    CDPatternItemHeader *itemHeader = _sequenceManager.getCurrentPatternItemHeader();
    if (itemHeader) {
        // Header stores duration in MS
        return itemHeader->duration / 1000.0;
    } else {
        return 0;
    }
}

+ (BOOL)autosavesInPlace {
    return YES;
}

static CDPatternSimulatorDocument *g_activeDoc = nil;

- (void)start {
    if (g_activeDoc != self) {
        [g_activeDoc stop];
        g_activeDoc = self;
    }
    if (_timer == nil) {
        // Speed of the teensy...96000000 == 96Mhz 14 loops per usec.. according to source
        NSTimeInterval time = 14.0/1000000.0;
        _timer = [NSTimer timerWithTimeInterval:time target:self selector:@selector(_tick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stop {
    [_timer invalidate];
    _timer = nil;
    g_activeDoc = nil;
}

- (BOOL)isRunning {
    return _timer != nil;
}

- (void)_tick:(NSTimer *)sender {
    CDPatternItemHeader *oldHeader = _sequenceManager.getCurrentPatternItemHeader();
    _sequenceManager.process(false);
    CDPatternItemHeader *newHeader = _sequenceManager.getCurrentPatternItemHeader();
    if (oldHeader != newHeader) {
        [self willChangeValueForKey:@"patternTypeName"];
        [self didChangeValueForKey:@"patternTypeName"];
    }
}

- (void)performButtonClick {
    [self willChangeValueForKey:@"patternTypeName"];
    _sequenceManager.nextPatternItem();
    [self didChangeValueForKey:@"patternTypeName"];
}


@end
