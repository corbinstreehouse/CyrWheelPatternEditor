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
#import "CyrWheelPatternEditor-Swift.h"

//#import "CDPatternSequence.h"
//#import "CWPatternSequenceManager.h"
//#import "SdFat.h"
//#import "CDPatternItemNames.h"
#import "CDPatternRunner.h"

@interface CDPatternSimulatorDocument() {
}

@property(readwrite) CDPatternRunner *patternRunner;

@end



// TODO: it would be better to combine the two documents into one that read both, and wrote just one kind.

@implementation CDPatternSimulatorDocument

@synthesize patternRunner = _patternRunner;

- (id)init
{
    self = [super init];
    self.patternRunner = [[CDPatternRunner alloc] initWithPatternDirectoryURL:[CDAppDelegate appDelegate].patternDirectoryURL];
    return self;
}

//- (void)dealloc
//{
//    NSLog(@"...");
//}

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

- (void)setCyrWheelView:(CDCyrWheelView *)view {
    [self.patternRunner setCyrWheelView:view];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSAssert(self.patternRunner != nil, @"self.patternRunner should exist");
    // drop the filename, and use the CWPatternSequenceManager to test loading
    self.patternRunner.baseURL = [url URLByDeletingLastPathComponent];
    
    // Go through and find the sequence with the given name
    NSString *fileToFind = [url lastPathComponent];
    [self.patternRunner setCurrentSequenceName:fileToFind];
    
    return YES;
}

- (void)reload {
    [self.patternRunner loadCurrentSequence];
}

-(BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError *__autoreleasing *)error {
    
    NSMutableDictionary *options = nil;
    if (storeOptions != nil) {
        options = [storeOptions mutableCopy];
    } else {
        options = [NSMutableDictionary alloc];
    }
    
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    
    BOOL result = [super configurePersistentStoreCoordinatorForURL:url
                                                            ofType:fileType
                                                modelConfiguration:configuration
                                                      storeOptions:options
                                                             error:error];
    return result;
}


- (void)loadNextSequence {
    [self.patternRunner loadNextSequence];
}

- (void)priorSequence {
    [self.patternRunner priorSequence];
}

- (void)play {
    [self.patternRunner play];
}

- (void)pause {
    [self.patternRunner pause];
}

@dynamic playing;
- (BOOL)isPlaying {
    return !self.patternRunner.paused;
}

//- (NSString *)sequenceName {
//    char fullFilenamePath[MAX_PATH];
//    if (_sequenceManager.getCurrentPatternFileName(fullFilenamePath, MAX_PATH)) {
//        return [NSString stringWithCString:fullFilenamePath encoding:NSASCIIStringEncoding];
//    } else {
//        return @"Default Sequence";
//    }
//}
//
//- (NSString *)patternTypeName {
//    CDPatternItemHeader *itemHeader = _sequenceManager.getCurrentPatternItemHeader();
//    if (itemHeader) {
//        return g_patternTypeNames[itemHeader->patternType];
//    }
//    return @"<None>";
//}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)start {
    [self.patternRunner play];
}

- (void)stop {
    [self.patternRunner pause];
}

- (BOOL)isRunning {
    return !self.patternRunner.isPaused;
}

- (void)performButtonClick {
    [self.patternRunner nextPatternItem];
}


@end
