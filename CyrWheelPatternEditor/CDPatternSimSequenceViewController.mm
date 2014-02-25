//
//  CDPatternSimSequenceViewController.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/10/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSimSequenceViewController.h"
#import "CDCyrWheelView.h"
#import "CDLEDStripPatterns.h"
#import "CDPatternSimulatorDocument.h"

@interface CDPatternSimSequenceViewController () {
@private
    BOOL _running;
}

@property (weak) IBOutlet CDCyrWheelView *cyrWheelView;

@end

@implementation CDPatternSimSequenceViewController

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
    
    // TODO: corbin - some better way of hooking up a non-singleton NeoPixel class to the cyr wheel view it is controlling. If I had it operating not on globals I could easily abstract it..
    // I also have to figure out how to make it operate on the currently active view.
    g_strip.setCyrWheelView(_cyrWheelView);
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

@end
