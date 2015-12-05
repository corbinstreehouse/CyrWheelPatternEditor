//
//  CDPatternSimSequenceViewController.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/10/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSimSequenceViewController.h"
#import "CDCyrWheelView.h"
#import "CDPatternSimulatorDocument.h"

@interface CDPatternSimSequenceViewController () {
    BOOL _loaded;
    CDPatternSimulatorDocument *_document;
}

@property (weak) IBOutlet CDCyrWheelView *cyrWheelView;

@end

@implementation CDPatternSimSequenceViewController

@synthesize document = _document;

- (id)init {
    self = [super initWithNibName:[self className] bundle:nil];
    return self;
}

- (IBAction)btnNextSequenceClicked:(id)sender {
    [self.document loadNextSequence];
}

- (void)loadView {
    [super loadView];
    // view did load
    _loaded = YES;
    
    // TODO: corbin - some better way of hooking up a non-singleton NeoPixel class to the cyr wheel view it is controlling. If I had it operating not on globals I could easily abstract it..
    // I also have to figure out how to make it operate on the currently active view.
    /// is the doc set at this point?
    [self.document setCyrWheelView:_cyrWheelView];
}

- (void)setDocument:(CDPatternSimulatorDocument *)document {
    _document = document;
    if (_loaded) {
        [self.document setCyrWheelView:_cyrWheelView];
    }
}

- (IBAction)btnStartStopClicked:(id)sender {
    if (self.document.isRunning) {
        [self.document stop];
    } else {
        [self.document start];
    }
}

- (IBAction)btnClickSimClicked:(id)sender {
    [self.document performButtonClick];
}
- (IBAction)btnPlayClicked:(id)sender {
    [_document play];
}
- (IBAction)btnPauseClicked:(id)sender {
    [_document pause];
}

@end
