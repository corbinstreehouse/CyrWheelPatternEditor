//
//  CDWheelManagerViewController.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 10/31/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDWheelManagerViewController.h"
#import "CDCyrWheelConnection.h"
#import "CWPatternSequenceManager.h"
#import "CDCyrWheelPattern.h"

@interface NSTableView(hack)

- (void)applyPermutationsFromArray:(NSArray *)oldContents toArray:(NSArray *)newContents insertionAnimation:(NSTableViewAnimationOptions)insertAnimation removalAnimation:(NSTableViewAnimationOptions)removeAnimation NS_AVAILABLE_MAC(10_8);

@end

@interface CDWheelManagerViewController () <NSTableViewDataSource, NSTableViewDelegate> {
@private
    CDCyrWheelConnection *_wheelConnection;
    NSArray *_sequences;
}

@property(copy) NSString *wheelName;
@property BOOL loadingSequences;
@property BOOL uploadingFile;
@property(readonly) BOOL showingProgress;

@property (weak) IBOutlet NSTableView *_sequencesTableView;

@end

@implementation CDWheelManagerViewController

- (id)init {
    self = [self initWithNibName:[self className] bundle:nil];
    self.title = @"Cyr Wheel Manager";
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
    self.wheelName = nil;
    _wheelConnection = nil;
}

- (void)setView:(NSView *)view {
    [super setView:view];
    [self viewDidLoad];
}

- (void)viewDidLoad {
    // TODO: better abstraction to other wheels
    _wheelConnection = [CDCyrWheelConnection new];
    
    // TODO: load the table..
    [self _loadSequences];
}

- (void)_loadSequences {
//    if (self.loadingSequences) {
//        [_wheelConnection cancelAllObjectRequests]; // Try again...
//    }
    
    self.loadingSequences = YES;
//    [_wheelConnection getSequencesWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//        self.loadingSequences = NO;
//        NSArray *newSequences = mappingResult.array;
//        if (_sequences != nil || _sequences.count == 0) {
//            // Do some animations from what we had to the new stuff
//            NSArray *oldSequences = _sequences;
//            _sequences = newSequences;
//            [self._sequencesTableView applyPermutationsFromArray:oldSequences toArray:_sequences insertionAnimation:NSTableViewAnimationEffectFade removalAnimation:NSTableViewAnimationSlideUp];
//        } else {
//            // nothing shown..reload it all
//            _sequences = newSequences;
//            [self._sequencesTableView reloadData];
//        }
//        
//    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
//        self.loadingSequences = NO;
//        [NSApp presentError:error modalForWindow:self.view.window delegate:nil didPresentSelector:@selector(_didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
//    }];
}
- (IBAction)btnDynamicPatternClicked:(id)sender {
    CDCyrWheelPattern *p = [CDCyrWheelPattern new];
    p.patternEndCondition = CDPatternEndConditionOnButtonClick;
    p.patternType = LEDPatternTypeBlueFire;
    [_wheelConnection setPatternItem:p];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _sequences.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [_sequences objectAtIndex:row];
}

- (CDCyrWheelSequence *)_sequenceAtRow:(NSInteger)row {
    if (row != -1) {
        return [_sequences objectAtIndex:row];
    } else {
        return nil;
    }
}

- (IBAction)btnStartPatternFromTable:(id)sender {
    NSInteger row = [self._sequencesTableView rowForView:sender];
    if (row != -1) {
        CDCyrWheelSequence *sequence = [self _sequenceAtRow:row];
        [_wheelConnection playSequence:sequence];
    }
}

- (void)_deleteSequencesInIndexSet:(NSIndexSet *)indexes {
    if (indexes.count > 0) {
        NSArray *itemsToDelete = [_sequences objectsAtIndexes:indexes];

        // TODO: batch version
        for (CDCyrWheelSequence *sequence in itemsToDelete) {
            [_wheelConnection deleteSequence:sequence];
        }
        NSMutableArray *mutableCopy = [_sequences mutableCopy];
        [mutableCopy removeObjectsAtIndexes:indexes];
        [self._sequencesTableView removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationSlideUp];
        _sequences = mutableCopy;

        // Uh...todo...batch version and do load only if it fails..
        [self _loadSequences];
    }
}

- (IBAction)btnDeleteFromTableClicked:(id)sender {
    NSInteger row = [self._sequencesTableView rowForView:sender];
    if (row != -1) {
        [self _deleteSequencesInIndexSet:[NSIndexSet indexSetWithIndex:row]];
    }
}

- (IBAction)btnRefreshClicked:(id)sender {
    [self _loadSequences];
}

- (void)_didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo {
    
}

- (IBAction)btnAddRemoveClicked:(NSSegmentedControl *)sender {
    if ([sender selectedSegment] == 0) {
        [self _doAddWithSavePanel];
    } else {
        [self _deleteSelectedRows];
    }
}

- (void)_doAddWithSavePanel {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.title = @"Select a pattern sequence";
    openPanel.allowedFileTypes = @[[NSString stringWithUTF8String:PATTERN_FILE_EXTENSION_LC]];
    openPanel.allowsOtherFileTypes = false;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            [openPanel orderOut:nil];
            [self _uploadSequenceWithURL:openPanel.URL];
        }
    }];
}

@dynamic showingProgress;
- (BOOL)showingProgress {
    return self.uploadingFile || self.loadingSequences;
}

+ (NSSet *)keyPathsForValuesAffectingShowingProgress {
    return [NSSet setWithObjects:@"uploadingFile", @"loadingSequences", nil];
}

- (void)_uploadSequenceWithURL:(NSURL *)url {
    // Validate the name
    NSString *name = [url.relativePath lastPathComponent];
    name = [name uppercaseString];
    // Reformat it to 8.3
    NSString *baseName = [name stringByDeletingPathExtension];
    if (baseName.length > 8) {
        baseName = [baseName substringToIndex:7];
    }
    
    // Make sure it is unique
    NSInteger counter = 1;
    CDCyrWheelSequence *sequence = [CDCyrWheelSequence new];
    sequence.name = [NSString stringWithFormat:@"%@.%s", baseName, PATTERN_FILE_EXTENSION];
    
    // Wack off one more character so we can add a number
    if (baseName.length > 7) {
        baseName = [baseName substringToIndex:6];
    }
    
    // THIS WILL always overwrite the last item...oh well
    while ([_sequences containsObject:sequence] && counter < 10) {
        sequence.name = [NSString stringWithFormat:@"%@%ld.%s", baseName, counter, PATTERN_FILE_EXTENSION];
        counter++;
    }
    
    self.uploadingFile = YES;
//    [_wheelConnection uploadNewSequence:sequence atURL:url success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//        self.uploadingFile = NO;
//        [self _loadSequences];
//    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
//        self.uploadingFile = NO;
//        [self presentError:error modalForWindow:self.view.window delegate:nil didPresentSelector:@selector(_didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
//    }];
}


- (void)_deleteSelectedRows {
    [self _deleteSequencesInIndexSet:self._sequencesTableView.selectedRowIndexes];
}

- (IBAction)btnCommandClick:(NSButton *)sender {
    
    // TODO: disable buttons while we are sending the command?
    // or cancel all prior sends
    [_wheelConnection sendCommand:(CDCyrWheelCommand)sender.tag];
//    [_wheelConnection sendCommand:(CDCyrWheelCommand)sender.tag success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//        
//    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
//        [self presentError:error modalForWindow:self.view.window delegate:nil didPresentSelector:@selector(_didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
//    }];
}

@end
