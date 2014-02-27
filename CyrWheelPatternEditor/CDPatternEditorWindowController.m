//
//  CDPatternEditorWindowController.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternEditorWindowController.h"
#import "CDPatternItem.h"
#import "CDDocument.h"
#import "CDPatternData.h"
#import "CDPatternSequence.h"
#import "CDPatternItemViewController.h"

static NSString *CDPatternTableViewPBoardType = @"CDPatternTableViewPBoardType";

@interface CDPatternEditorWindowController () {
@private
    NSMutableArray *_patternViewControllers;
    __weak NSTableView *_tableView;
    NSIndexSet *_draggedRowIndexes;
    BOOL _observingChildren;
}
    
@property (weak) IBOutlet NSImageView *imgViewPreview;
@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation CDPatternEditorWindowController

- (id)init {
    self = [super initWithWindowNibName:[self className] owner:self];
    return self;
}
    
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    
    
    
    
    return self;
}

//- (void)dealloc {
//    if (_observingChildren) {
//        [self._patternSequence removeObserver:self forKeyPath:CDPatternChildrenKey];
//    }
////    [super dealloc]; // ARC silly
//}

- (CDDocument *)document {
    return (CDDocument *)super.document;
}

- (void)setDocument:(NSDocument *)document {
    if (document != self.document) {
        if (_observingChildren) {
            [self._patternSequence removeObserver:self forKeyPath:CDPatternChildrenKey];
        }
        [super setDocument:document];
    }
}

- (CDPatternItemViewController *)_patternViewControllerAtIndex:(NSInteger)index {
    id currentObject = [_patternViewControllers objectAtIndex:index];
    CDPatternItemViewController *result;
    if (currentObject == [NSNull null]) {
        CDPatternItem *item = [self._patternSequence.children objectAtIndex:index];
        result = [CDPatternItemViewController new];
        result.patternItem = item;
        [_patternViewControllers replaceObjectAtIndex:index withObject:result];
    } else {
        result = (CDPatternItemViewController *)currentObject;
    }
    return result;
}

- (void)_resetPatternViewControllers {
    _patternViewControllers = NSMutableArray.new;
    for (NSInteger i = 0; i < self._patternSequence.children.count; i++) {
        [_patternViewControllers addObject:[NSNull null]]; // placeholder
    }
    [_tableView reloadData];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self _resetPatternViewControllers];

    // Watch for changes
    _observingChildren = YES;
    [self._patternSequence addObserver:self forKeyPath:CDPatternChildrenKey options:0 context:nil];
    
    [_tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [_tableView registerForDraggedTypes:[NSArray arrayWithObjects:CDPatternTableViewPBoardType, nil]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSAssert([keyPath isEqualToString:CDPatternChildrenKey], @"children only");
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    switch (changeKind) {
        case NSKeyValueChangeSetting: {
            [self _resetPatternViewControllers];
            break;
        }
        case NSKeyValueChangeInsertion: {
//            if (_draggedRowIndexes != nil) break; // Done manually in the drag operation
            NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
            if (indexes) {
                NSMutableArray *emptyObjects = NSMutableArray.new;
                for (NSInteger i = 0; i < indexes.count; i++) {
                    [emptyObjects addObject:[NSNull null]];
                }
                [_patternViewControllers insertObjects:emptyObjects atIndexes:indexes];
                [NSAnimationContext beginGrouping];
                [NSAnimationContext.currentContext setDuration:5];
                [_tableView insertRowsAtIndexes:indexes withAnimation:NSTableViewAnimationEffectFade];
                [NSAnimationContext endGrouping];
            } else {
                [self _resetPatternViewControllers];
            }
            break;
        }
        case NSKeyValueChangeRemoval: {
//            if (_draggedRowIndexes != nil) break; // Done manually in the drag operation
            NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
            if (indexes) {
                [_patternViewControllers removeObjectsAtIndexes:indexes];
                
                [_tableView removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationEffectFade];
            } else {
                [self _resetPatternViewControllers];
            }
            break;
        }
        case NSKeyValueChangeReplacement: {
            NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
            if (indexes) {
                [_patternViewControllers removeObjectsAtIndexes:indexes];
                // replace w/null
                NSMutableArray *emptyObjects = NSMutableArray.new;
                for (NSInteger i = 0; i < indexes.count; i++) {
                    [emptyObjects addObject:[NSNull null]];
                }
                [_patternViewControllers insertObjects:emptyObjects atIndexes:indexes];
                [_tableView reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            } else {
                [self _resetPatternViewControllers];
            }
            break;
        }
        default: {
            NSAssert(NO, @"internal error: change not known");
            break;
        }
    }

    [_tableView reloadData];
}

- (NSManagedObjectContext *)managedObjectContext {
    return self.document.managedObjectContext;
}

- (CDPatternSequence *)_patternSequence {
    return self.document.patternSequence;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _patternViewControllers.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CDPatternItemViewController *vc = [self _patternViewControllerAtIndex:row];
    // don't set the identifier so it isn't reused...
    return vc.view;
}

- (void)_addItem {
    CDPatternItem *patternItem = [CDPatternItem newItemInContext:self.managedObjectContext];
//    [self._patternSequence addChildrenObject:patternItem];
    [self._patternSequence insertObject:patternItem inChildrenAtIndex:self._patternSequence.children.count];
    [_tableView scrollRowToVisible:_tableView.numberOfRows - 1];
    
}

- (void)_removeSelectedItem {
    NSInteger selectedRow = _tableView.selectedRow;
    if (selectedRow != -1) {
        [_tableView beginUpdates];
        CDPatternSequence *patternSequence = [self _patternSequence];
        NSIndexSet *indexesToDelete = [_tableView selectedRowIndexes];
        // grab the children first
        NSArray *selectedChildren = [patternSequence.children objectsAtIndexes:indexesToDelete];

        // remove them from the relationship
        [patternSequence removeChildrenAtIndexes:indexesToDelete];
        [_tableView endUpdates];
        selectedRow--;
        if (selectedRow >= 0 && selectedRow < _tableView.numberOfRows) {
            [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        }

        // delete them
        for (CDPatternItem *childToDelete in selectedChildren) {
            [self.managedObjectContext deleteObject:childToDelete];
        }

//        [self.managedObjectContext processPendingChanges];
        
//        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:[CDPatternItem className] inManagedObjectContext:self.managedObjectContext];
//        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//        fetchRequest.entity = entityDesc;
//        NSError *error = nil;
//        NSArray *resultArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
//        NSLog(@"%ld", resultArray.count);

    }
}

- (IBAction)sgmntControlClick:(NSSegmentedControl *)sender {
    if ([sender selectedSegment] == 0) {
        [self _addItem];
    } else {
        [self _removeSelectedItem];
    }
}

- (void)_writeHeaderToData:(NSMutableData *)data {
    CDPatternSequenceHeader header;
    header.marker[0] = 'S';
    header.marker[1] = 'Q';
    header.marker[2] = 'C';
    header.version = 0; // version 0
    header.pixelCount = self._patternSequence.pixelCount;
    header.patternCount = self._patternSequence.children.count;
    [data appendBytes:&header length:sizeof(header)];
}

- (BOOL)_writePatternItem:(CDPatternItem *)item toData:(NSMutableData *)data {
    CDPatternItemHeader itemHeader;
    bzero(&itemHeader, sizeof(CDPatternItemHeader));
    itemHeader.patternType = item.patternType;
    // Duration is stored in seconds but the header uses ms, and we round.
    itemHeader.duration = round(item.duration * 1000);
    itemHeader.patternEndCondition = item.patternEndCondition;
    itemHeader.intervalCount = item.repeatCount;
    itemHeader.color = item.encodedColor;

    BOOL result = YES;
    if (item.patternTypeRequiresImageData) {
        // item.imageData is the raw image format. We have to convert it to something easier to deal with....
        NSData *encodedData = [item getImageDataWithEncoding:CDPatternEncodingTypeRGB24]; // TODO: we could figure out which is smallest and use that encoded type
        
        NSUInteger dataLength = encodedData.length;
        if (dataLength > UINT32_MAX) {
            // sort of ugly way to show errors
            NSError *error = [NSError errorWithDomain:@"image or data size exceeds 16-bit size. time for me to up data sizes..." code:0 userInfo:nil];
            [self.window presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
            result = NO;
        } else {
            itemHeader.dataLength = (uint32_t)dataLength;
            [data appendBytes:&itemHeader length:sizeof(itemHeader)];
            // Write the data
            if (dataLength > 0) {
                [data appendData:encodedData];
            }
        }
    } else {
        itemHeader.dataLength = 0;
        [data appendBytes:&itemHeader length:sizeof(itemHeader)];
    }
    return result;
}

- (void)_writeDataToURL:(NSURL *)url {
    NSMutableData *data = [NSMutableData new];
    [self _writeHeaderToData:data];
    for (NSInteger i = 0; i < self._patternSequence.children.count; i++) {
        CDPatternItem *item = self._patternSequence.children[i];
        if (![self _writePatternItem:item toData:data]) {
            break;
        }
    }
    
    NSError *error = nil;
    if (![data writeToURL:url options:0 error:&error]) {
        NSAssert(error != nil, @"failures should generate an error");
        [self.window presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
    }
}

- (IBAction)btnExportClick:(id)sender {
    NSSavePanel *sp = [NSSavePanel savePanel];
    sp.allowedFileTypes = @[@"pat"];
    sp.allowsOtherFileTypes = NO;
    sp.title = @"Export pattern to an SD card";
    [sp beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            [self _writeDataToURL:sp.URL];
        }
    }];
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    // Just a placeholder of what row is being dragged
    NSPasteboardItem *result = [NSPasteboardItem new];

    return result;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    _draggedRowIndexes = nil;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
    _draggedRowIndexes = rowIndexes;
    [session.draggingPasteboard declareTypes:@[CDPatternTableViewPBoardType] owner:self];
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    if (dropOperation == NSTableViewDropOn) {
        return NSDragOperationNone; // Can'd drop on
    }
    if (_draggedRowIndexes) {
        if (info.draggingSourceOperationMask == NSDragOperationCopy) {
            return NSDragOperationCopy;
        } else {
            return NSDragOperationMove;
        }
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    if (info.draggingSourceOperationMask == NSDragOperationCopy) {
#warning implement copy..
        return YES;
    } else {
        [_tableView beginUpdates];
        
        
        CDPatternSequence *patternSequence = [self _patternSequence];
        NSArray *childrenToMove = [patternSequence.children objectsAtIndexes:_draggedRowIndexes];
        [patternSequence removeChildrenAtIndexes:_draggedRowIndexes];
        NSMutableIndexSet *targetIndexes = [NSMutableIndexSet new];
        NSInteger modifiedStartingRow = row - [_draggedRowIndexes countOfIndexesInRange:NSMakeRange(0, row)];
        for (NSInteger r = modifiedStartingRow; r < modifiedStartingRow + childrenToMove.count; r++) {
            [targetIndexes addIndex:r];
        }
        [patternSequence insertChildren:childrenToMove atIndexes:targetIndexes];

        
        [_tableView endUpdates];
        return YES;
    }
    
}

@end
