//
//  CDPatternSimulatorWindowController.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSimulatorWindowController.h"
#import "CDPatternSimulatorViewController.h"

@interface CDPatternSimulatorWindowController () {
    CDPatternSimulatorViewController *_simViewController;
    
}

@end

@implementation CDPatternSimulatorWindowController

- (id)init {
    self = [super initWithWindowNibName:[self className] owner:self];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    _simViewController = [CDPatternSimulatorViewController new];
    self.window.contentView = _simViewController.view;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
