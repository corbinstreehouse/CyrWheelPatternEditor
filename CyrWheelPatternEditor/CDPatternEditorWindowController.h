//
//  CDPatternEditorWindowController.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CDDocument;

@interface CDPatternEditorWindowController : NSWindowController<NSTableViewDataSource, NSTableViewDelegate>

- (CDDocument *)document;

@end
