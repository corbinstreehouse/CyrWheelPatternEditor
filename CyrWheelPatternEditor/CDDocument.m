//
//  CDDocument.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDDocument.h"
#import "CDPatternEditorWindowController.h"

@interface NSArray(Hack)
- (id)firstObject; // in 10.9, retropublisehd
@end

@implementation CDDocument

@synthesize patternSequence = _patternSequence;

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
    result.pixelCount = 330; // For my wheel...
    
    // create one child
    CDPatternItem *patternItem = [self _makeDefaultItem];
    [result addChildrenObject:patternItem];
    
    
    [managedObjectContext processPendingChanges];
    [[managedObjectContext undoManager] enableUndoRegistration];
    return result;
}

- (id)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    self = [super initWithType:typeName error:outError];
    return self;
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
    CDPatternEditorWindowController *wc = [CDPatternEditorWindowController new];
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



//- (void)reopenDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
//    
//    
//}


@end
