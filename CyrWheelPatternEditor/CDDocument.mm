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
#import "CyrWheelPatternEditor-Swift.h"

NSString *CDCompiledSequenceTypeName = @"public.compiledcyrwheelsequence";

@interface NSArray(Hack)
- (id)firstObject; // in 10.9, retropublisehd
@end

@implementation CDDocument

@synthesize patternSequence = _patternSequence;

- (id)init {
    self = [super init];
    
//    self.managedObjectContext.persistentStoreCoordinator
    
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

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError *__autoreleasing *)error {
    
    NSMutableDictionary *options = nil;
    if (storeOptions != nil) {
        options = [storeOptions mutableCopy];
    } else {
        options = [NSMutableDictionary new];
    }
    
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
    // map explict stuff??
    
    BOOL result = [super configurePersistentStoreCoordinatorForURL:url
                                                            ofType:fileType
                                                modelConfiguration:configuration
                                                      storeOptions:options
                                                             error:error];
    return result;
}


- (CDPatternItem *)_makeDefaultItem {
    return [CDPatternItem newItemInContext:self.managedObjectContext];
}
//
//- (id)managedObjectModel
//{
//    static id sharedManagedObjectModel = nil;
//    
//    if (sharedManagedObjectModel == nil) {
////        NSBundle *bundle = [NSBundle mainBundle];
////        NSURL *url = [bundle URLForResource:@"CDDocument" withExtension:@"momd"];
////        sharedManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
//        sharedManagedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
//    }
//    
//    return sharedManagedObjectModel;
//}

- (CDPatternSequence *)_makePatternItem {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    [[managedObjectContext undoManager] disableUndoRegistration];
    CDPatternSequence *result = [NSEntityDescription insertNewObjectForEntityForName:[CDPatternSequence className] inManagedObjectContext:self.managedObjectContext];

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

- (CDPatternItem *)makeTemporaryPatternItem {
    CDPatternItem *patternItem = [CDPatternItem newItemInContext:self.managedObjectContext];
    // copy the last item, if we had one
    if (self.patternSequence.children.count > 0) {
        CDPatternItem *lastPatternItem = self.patternSequence.children.lastObject;
        [lastPatternItem copyTo:patternItem];
    }
    return patternItem;
}

- (void)removeTemporaryPatternItem:(CDPatternItem *)item {
    [self.managedObjectContext deleteObject:item];
}

- (CDPatternItem *)addNewPatternItem {
    CDPatternItem *patternItem = [self makeTemporaryPatternItem]; // We make it permenant
    [self addPatternItemToChildren:patternItem];
    return patternItem;
}

- (void)addPatternItemToChildren:(CDPatternItem *)patternItem {
    [self.patternSequence insertObject:patternItem inChildrenAtIndex:self.patternSequence.children.count];
}

- (void)removePatternItemsAtIndexes:(NSIndexSet *)indexesToDelete {
    if (indexesToDelete.count > 0) {
        CDPatternSequence *patternSequence = self.patternSequence;
        // grab the children first
        NSArray *selectedChildren = [patternSequence.children objectsAtIndexes:indexesToDelete];
        
        // remove them from the relationship
        [patternSequence removeChildrenAtIndexes:indexesToDelete];

        // delete them
        for (CDPatternItem *childToDelete in selectedChildren) {
            [self.managedObjectContext deleteObject:childToDelete];
        }
    }
    
    //        [self.managedObjectContext processPendingChanges];
    
    //        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:[CDPatternItem className] inManagedObjectContext:self.managedObjectContext];
    //        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    //        fetchRequest.entity = entityDesc;
    //        NSError *error = nil;
    //        NSArray *resultArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    //        NSLog(@"%ld", resultArray.count);
    
}


- (void)makeWindowControllers {
    NSWindowController *wc;
    // switch on the sim vs real thing on what we initially opened
    if ([[self fileType] isEqualToString:CDCompiledSequenceTypeName]) {
        wc = [CDPatternSimulatorWindowController new];
    } else {
        wc = [CDPatternEditorWindowController new];
        
        NSWindowController *wc2 = [((CDAppDelegate *)NSApp.delegate).mainStoryboard instantiateControllerWithIdentifier:@"CDPatternEditorWindowController2"];
        [self addWindowController:wc2];
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
