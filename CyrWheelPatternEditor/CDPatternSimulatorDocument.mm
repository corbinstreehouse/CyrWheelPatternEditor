//
//  CDPatternSimulatorDocument.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSimulatorDocument.h"
#import "CDPatternSimulatorWindowController.h"
#import "CWPatternSequenceManager.h"
#import "SD.h"

@interface CDPatternSimulatorDocument() {
@private
   CWPatternSequenceManager _sequenceManager;
    
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
    // drop the filename, and use the CWPatternSequenceManager
    NSURL *baseDirectory = [url URLByDeletingLastPathComponent];
    SDSetBaseDirectoryURL(baseDirectory);
    _sequenceManager.init();
    _sequenceManager.loadFirstSequence();
    
    
        
    
    
    
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
