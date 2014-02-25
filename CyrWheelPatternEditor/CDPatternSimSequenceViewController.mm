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
    CDPatternSimulatorDocument *_document;
}

@property (weak) IBOutlet CDCyrWheelView *cyrWheelView;

@end

@implementation CDPatternSimSequenceViewController

- (id)init {
    self = [super initWithNibName:[self className] bundle:nil];
    return self;
}

- (IBAction)btnNextSequenceClicked:(id)sender {
    if (self.nextSequenceHandler) {
        self.nextSequenceHandler();
    }
}

- (void)loadView {
    [super loadView];
    // view did load
    
    // TODO: corbin - some better way of hooking up a non-singleton NeoPixel class to the cyr wheel view it is controlling. If I had it operating not on globals I could easily abstract it..
    // I also have to figure out how to make it operate on the currently active view.
    g_strip.setCyrWheelView(_cyrWheelView);
}

- (IBAction)btnStartStopClicked:(id)sender {
    if (self.startStopHandler) {
        self.startStopHandler();
    }
}

@end
