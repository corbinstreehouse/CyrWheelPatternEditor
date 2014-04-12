//
//  CDDocument.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDDocument.h"
#import "CDPatternEditorWindowController.h"
#import "CDPatternSimulatorWindowController.h"

static NSString *CDCompiledSequenceTypeName = @"public.compiledcyrwheelsequence";

@interface NSArray(Hack)
- (id)firstObject; // in 10.9, retropublisehd
@end

@implementation CDDocument

@synthesize patternSequence = _patternSequence;

- (id)init {
    self = [super init];
    return self;
}

- (CDPatternSequence *)_loadPatternItem {
    CDPatternSequence *result = nil;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:[CDPatternSequence className] inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entityDesc;
    NSError *error = nil;
    NSArray *resultArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (resultArray && resultArray.count > 0) {
        NSAssert(resultArray.count == 1, @"should have one item only");
        result = [resultArray firstObject];
    }
    return result;
}

- (CDPatternItem *)_makeDefaultItem {
    return [CDPatternItem newItemInContext:self.managedObjectContext];
}

- (CDPatternSequence *)_makePatternItem {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    [[managedObjectContext undoManager] disableUndoRegistration];
    CDPatternSequence *result = [NSEntityDescription insertNewObjectForEntityForName:[CDPatternSequence className] inManagedObjectContext:self.managedObjectContext];
    // default values
    result.pixelCount = 331; // For my wheel...
    
    // create one child
    CDPatternItem *patternItem = [self _makeDefaultItem];
    [result addChildrenObject:patternItem];
    
    
    [managedObjectContext processPendingChanges];
    [[managedObjectContext undoManager] enableUndoRegistration];
    return result;
}

- (CDPatternSequence *)patternSequence {
    if (_patternSequence  == nil) {
        _patternSequence = [self _loadPatternItem];
        if (_patternSequence == nil) {
            _patternSequence = [self _makePatternItem];
        }
    }
    return _patternSequence;
}

- (void)makeWindowControllers {
    NSWindowController *wc;
    // switch on the sim vs real thing on what we initially opened
    if ([[self fileType] isEqualToString:CDCompiledSequenceTypeName]) {
        wc = [CDPatternSimulatorWindowController new];
    } else {
        wc = [CDPatternEditorWindowController new];
    }
    [self addWindowController:wc];
}
    
- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace {
    return YES;
}

// experimental Bi support
//- (void)_loadCompiledSequenceFromData:(NSData *)data  error:(NSError *__autoreleasing *)error {
//
//}
//
//- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError *__autoreleasing *)error {
//    // If it is our compiled type, we are a readonly document and translate it to our item..
//    if ([typeName isEqualToString:CDCompiledSequenceTypeName]) {
//        NSData *data = [NSData dataWithContentsOfURL:absoluteURL options:0 error:error];
//        if (data) {
//            // Load stuff..
//            [self _loadCompiledSequenceFromData:data error:error];
//            return YES;
//        } else {
//            return NO;
//        }
//    } else {
//        // let coredata load
//        return [super readFromURL:absoluteURL ofType:typeName error:error];
//    }
//}
//
//- (id)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
//    if ([typeName isEqualToString:CDCompiledSequenceTypeName]) {
//        self = [self init];
//        [self setFileType:CDCompiledSequenceTypeName];
//        [self setFileURL:url];
//        [self readFromURL:url ofType:typeName error:outError];
//    } else {
//        self = [super initWithContentsOfURL:url ofType:typeName error:outError];
//    }
//    return self;
//}
//
//- (id)initForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError **)outError {
//    if ([typeName isEqualToString:CDCompiledSequenceTypeName]) {
//        self = [self initWithContentsOfURL:contentsURL ofType:typeName error:outError];
//    } else {
//        self = [super initForURL:urlOrNil withContentsOfURL:contentsURL ofType:typeName error:outError];
//    }
//    return self;
//}
//


@end
