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

@synthesize patternItem = _patternItem;

- (CDPatternItem *)_loadPatternItem {
    CDPatternItem *result = nil;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"PatternItem" inManagedObjectContext:self.managedObjectContext];
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

//- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
//    return @"cyrwheel";
//}

- (CDPatternItem *)_makePatternItem {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    [[managedObjectContext undoManager] disableUndoRegistration];
    CDPatternItem *result = [NSEntityDescription insertNewObjectForEntityForName:@"PatternItem" inManagedObjectContext:self.managedObjectContext];
    [managedObjectContext processPendingChanges];
    [[managedObjectContext undoManager] enableUndoRegistration];
    return result;
}

- (id)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    self = [super initWithType:typeName error:outError];
    return self;
}

- (CDPatternItem *)patternItem {
    if (_patternItem  == nil) {
        _patternItem = [self _loadPatternItem];
        if (_patternItem == nil) {
            _patternItem = [self _makePatternItem];
        }
    }
    return _patternItem;
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
