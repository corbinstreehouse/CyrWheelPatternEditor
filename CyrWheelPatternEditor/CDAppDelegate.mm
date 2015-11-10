//
//  CDAppDelegate.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDAppDelegate.h"
#import "CDPatternSimulatorWindowController.h"
#import "CDWheelManagerWindowController.h"

@interface CDAppDelegate()

@property (retain) CDWheelManagerWindowController *managerWindowController;

@end

@implementation CDAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // TODO: better state restoration..
    self.managerWindowController = [CDWheelManagerWindowController new];
    [self.managerWindowController.window orderFront:nil];
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
}



@end
