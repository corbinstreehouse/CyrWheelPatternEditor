//
//  CDWheelManagerWindowController.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/1/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDWheelManagerWindowController.h"
#import "CDWheelManagerViewController.h"

@interface CDWheelManagerWindowController ()

@end

@implementation CDWheelManagerWindowController

@synthesize mainViewController;

-(id)init {
    return [self initWithWindowNibName:[self className]];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
    // TODO: make sure i'm not creating a cycle..
    self.mainViewController = nil;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    self.mainViewController = [CDWheelManagerViewController new];
    self.window.contentView = self.mainViewController.view;
    self.window.title = self.mainViewController.title;
}

@end
