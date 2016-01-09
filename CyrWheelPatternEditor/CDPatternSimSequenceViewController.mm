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
#import "CDPatternRunner.h"

@interface CDPatternSimSequenceViewController () {
@private
    CDPatternRunner *_patternRunner;
}

@property (weak) IBOutlet CDCyrWheelView *cyrWheelView;

@end

@implementation CDPatternSimSequenceViewController

@dynamic patternRunner;

- (id)init {
    self = [super initWithNibName:[self className] bundle:nil];
    return self;
}

- (IBAction)btnNextSequenceClicked:(id)sender {
    [self.patternRunner loadNextSequence];
}

- (IBAction)btnPriorSequenceClicked:(id)sender {
    [self.patternRunner priorSequence];
}

- (void)loadView {
    [super loadView];
    [self.patternRunner setCyrWheelView:_cyrWheelView];
}

- (void)setPatternRunner:(CDPatternRunner *)patternRunner {
    if (_patternRunner) {
        [_patternRunner setCyrWheelView:nil];
    }
    _patternRunner = patternRunner;
    
    if (_patternRunner) {
        [_patternRunner setCyrWheelView:_cyrWheelView];
    }
}

- (CDPatternRunner *)patternRunner {
    return _patternRunner;
}

- (IBAction)btnStartStopClicked:(id)sender {
    if (self.patternRunner.isPaused) {
        [self.patternRunner play];
    } else {
        [self.patternRunner pause];
    }
}

- (IBAction)btnPlayClicked:(id)sender {
    [self btnStartStopClicked:sender];
}

@end
