//
//  CDPatternEditTableView.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/1/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternEditTableView.h"

@implementation CDPatternEditTableView

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event {
    return YES; // no delay
}

- (void)keyDown:(NSEvent *)theEvent {
    // handle delete
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if (key == NSDeleteCharacter && self.selectedRow != -1) {
        [NSApp sendAction:@selector(delete:) to:nil from:self];
    }
    
    [super keyDown:theEvent];
}

@end
