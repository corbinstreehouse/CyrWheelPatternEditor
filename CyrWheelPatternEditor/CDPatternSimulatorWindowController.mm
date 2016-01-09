//
//  CDPatternSimulatorWindowController.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSimulatorWindowController.h"
#import "CDPatternSimSequenceViewController.h"

@interface CDPatternSimulatorWindowController () {
@private
    CDPatternSimSequenceViewController *_simViewController;
}

@end

@implementation CDPatternSimulatorWindowController

- (id)init {
    self = [super initWithWindowNibName:[self className] owner:self];
    return self;
}

- (CDPatternSimulatorDocument *)document {
    return (CDPatternSimulatorDocument *)super.document;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    _simViewController = [CDPatternSimSequenceViewController new];
    _simViewController.patternRunner = self.document.patternRunner;
    self.window.contentView = _simViewController.view;
    [self.document start]; // Start running...
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self.document start];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self.document stop];
}

@end
