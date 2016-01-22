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
#import "CDPatternSimulatorDocument.h"
#import "CDPatternSimSequenceViewController.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import "CyrWheelPatternEditor-Swift.h"

static NSString *CDPatternTableViewPBoardType = @"CDPatternTableViewPBoardType";

@interface CDPatternEditorWindowController ()<NSTableViewDataSource, NSTableViewDelegate> {
@private
    NSMutableArray *_patternViewControllers;
    __weak NSTableView *_tableView;
    NSIndexSet *_draggedRowIndexes;
    BOOL _observingChildren;
    CDPatternSimSequenceViewController *_simViewController;
}
    
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSView *topView;

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

- (void)_refreshPreview {
    // Create the runner here...
    if (_simViewController.patternRunner == nil) {
        _simViewController.patternRunner = [[CDPatternRunner alloc] initWithPatternDirectoryURL:[CDAppDelegate appDelegate].patternDirectoryURL];
    }
    
    NSData *data = [self._patternSequence exportAsData];
    [_simViewController.patternRunner loadFromData:data];
    if (_simViewController.patternRunner.paused) {
        [_simViewController.patternRunner play];
    }
}

- (void)_setupSimView {
    _simViewController = [CDPatternSimSequenceViewController new];
    NSView *view = _simViewController.view;
    view.frame = self.topView.bounds;
    view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.topView addSubview:view];
}

- (void)dealloc {
    if (_observingChildren) {
        [self._patternSequence removeObserver:self forKeyPath:CDPatternChildrenKey];
    }
}

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
    _patternViewControllers = [NSMutableArray new];
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
    [self _setupSimView];
}

- (void)_patternItemChanged:(id)sender {
    NSInteger row = [self.tableView rowForView:(NSView *)sender];
    if (row != -1) {
        NSMutableIndexSet *indexes = [[self.tableView selectedRowIndexes] mutableCopy];
        if ([indexes containsIndex:row]) {
            [indexes removeIndex:row];
            if (indexes.count > 0) {
                // Mimic the property change in everyhting
                /// TODO: use a notification so I can watch it and do the right thing for all selected rows
                CDPatternSequence *patternSequence = [self _patternSequence];
                CDPatternItem *mainItem = [[patternSequence children] objectAtIndex:row];
                
                NSArray *children = [[patternSequence children] objectsAtIndexes:indexes];
                for (CDPatternItem *item in children) {
                    item.patternType = mainItem.patternType;
                }
            }
        }
    }
}

- (void)_observeValueForChildrenChangeOfObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSKeyValueChange changeKind = (NSKeyValueChange)[[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
    switch (changeKind) {
        case NSKeyValueChangeSetting: {
            [self _resetPatternViewControllers];
            break;
        }
        case NSKeyValueChangeInsertion: {
//            if (_draggedRowIndexes != nil) break; // Done manually in the drag operation
            NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
            if (indexes) {
                NSMutableArray *emptyObjects = [NSMutableArray new];
                for (NSInteger i = 0; i < indexes.count; i++) {
                    [emptyObjects addObject:[NSNull null]];
                }
                [_patternViewControllers insertObjects:emptyObjects atIndexes:indexes];
//                [NSAnimationContext beginGrouping];
//                [NSAnimationContext.currentContext setDuration:.3];
                [_tableView insertRowsAtIndexes:indexes withAnimation:NSTableViewAnimationEffectFade];
                [self _insertItemsInTimlineViewAtIndexes:indexes];
//                [NSAnimationContext endGrouping];
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

                [self _removeItemsInTimlineViewAtIndexes:indexes];
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
                NSMutableArray *emptyObjects = [NSMutableArray new];
                for (NSInteger i = 0; i < indexes.count; i++) {
                    [emptyObjects addObject:[NSNull null]];
                }
                [_patternViewControllers insertObjects:emptyObjects atIndexes:indexes];
                [_tableView reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                [self _removeItemsInTimlineViewAtIndexes:indexes];
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
}

// TODO: batch versions for timeline view
- (void)_removeItemsInTimlineViewAtIndexes:(NSIndexSet *)indexes {
}

- (void)_insertItemsInTimlineViewAtIndexes:(NSIndexSet *)indexes {
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:CDPatternChildrenKey]) {
        [self _observeValueForChildrenChangeOfObject:object change:change context:context];
    } else {
        NSAssert(NO, @"bad observation");
    }
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
    [self.document addNewPatternItem];
    [_tableView scrollRowToVisible:_tableView.numberOfRows - 1];
}

- (void)_removeSelectedItem {
    NSInteger selectedRow = _tableView.selectedRow;
    if (selectedRow != -1) {
        [_tableView beginUpdates];
        NSIndexSet *indexesToDelete = [_tableView selectedRowIndexes];

        [self.document removePatternItemsAtIndexes:indexesToDelete];
        
        [_tableView endUpdates];
        selectedRow--;
        if (selectedRow >= 0 && selectedRow < _tableView.numberOfRows) {
            [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        }
    }
}

- (IBAction)sgmntControlClick:(NSSegmentedControl *)sender {
    if ([sender selectedSegment] == 0) {
        [self _addItem];
    } else {
        [self _removeSelectedItem];
    }
}

- (void)_exportDataToURL:(NSURL *)url {
    NSError *error = nil;
    if (![self._patternSequence exportToURL:url error:&error]) {
        NSAssert(error != nil, @"failures should generate an error");
        [self.window presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
    }
}

- (IBAction)btnRefreshPreviewClick:(id)sender {
    [self _refreshPreview];
}


- (IBAction)btnExportClick:(id)sender {
    NSSavePanel *sp = [NSSavePanel savePanel];
    sp.allowedFileTypes = @[@"pat"];
    sp.allowsOtherFileTypes = NO;
    sp.title = @"Export pattern to an SD card";
    [sp beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            [self _exportDataToURL:sp.URL];
        }
    }];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    if ([anItem action] == @selector(copy:) || anItem.action == @selector(cut:)) {
        return self.tableView.selectedRowIndexes.count > 0;
    } else if (anItem.action == @selector(paste:)) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        if ([pasteboard.types containsObject:CDPatternTableViewPBoardType]) {
            return YES;
        } else {
            return NO;
        }

    } else {
        return NO;
    }
//    else if (anItem.action == @selector(paste:)) {
//        
//    }
}

- (IBAction)copy:(id)sender {
    if (self.tableView.selectedRowIndexes.count > 0) {
        NSData *data = [self _dataForItemsAtIndexes:self.tableView.selectedRowIndexes];
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard declareTypes:@[CDPatternTableViewPBoardType] owner:self];
        [pasteboard setData:data forType:CDPatternTableViewPBoardType];
    }
}

- (NSData *)_dataForItemsAtIndexes:(NSIndexSet *)indexes {
    CDPatternSequence *patternSequence = [self _patternSequence];
    NSArray *selectedChildren = [patternSequence.children objectsAtIndexes:indexes];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selectedChildren];
    return data;
}

- (void)_insertItemsWithData:(NSData *)data atStartingIndex:(NSInteger)row {
    [CDPatternItem setCurrentContext:self.managedObjectContext];
    NSArray *newItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [CDPatternItem setCurrentContext:nil];
    CDPatternSequence *patternSequence = [self _patternSequence];
    NSMutableIndexSet *targetIndexes = [NSMutableIndexSet new];
    [targetIndexes addIndexesInRange:NSMakeRange(row, newItems.count)];
    [patternSequence insertChildren:newItems atIndexes:targetIndexes];

}

- (IBAction)paste:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSData *data = [pasteboard dataForType:CDPatternTableViewPBoardType];
    if (data) {
        NSInteger row = self.tableView.selectedRow;
        if (row == -1) {
            row = self.tableView.numberOfRows;
        } else  {
            row = self.tableView.selectedRowIndexes.lastIndex + 1; // one past the last
        }
        [self _insertItemsWithData:data atStartingIndex:row];
    }
}

- (IBAction)cut:(id)sender {
    if (self.tableView.selectedRowIndexes.count > 0) {
        [self copy:sender];
        [self delete:sender];
    }
}

- (IBAction)delete:(id)sender {
    if (self.tableView.selectedRowIndexes.count > 0) {
        [_tableView beginUpdates];
        [[self _patternSequence] removeChildrenAtIndexes:self.tableView.selectedRowIndexes];
        [_tableView endUpdates];
    }
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
        NSData *data = [self _dataForItemsAtIndexes:_draggedRowIndexes];
        [self _insertItemsWithData:data atStartingIndex:row];
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

// Timeline view testing..


@end
