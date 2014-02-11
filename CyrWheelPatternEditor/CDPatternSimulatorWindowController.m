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

- (void)_update {
    _simViewController.patternSequence = self.document.patternSequence;
    _simViewController.sequenceName = self.document.sequenceName;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    _simViewController = [CDPatternSimSequenceViewController new];
    self.window.contentView = _simViewController.view;
    [self _update];
    __weak CDPatternSimulatorWindowController *weakSelf = self;
    _simViewController.nextSequenceHandler = ^() {
        [weakSelf.document loadNextSequence];
        [weakSelf _update];
    };
}

@end
