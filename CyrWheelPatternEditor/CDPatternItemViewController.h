//
//  CDPatternItemViewController.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/30/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDPatternItem.h"

@interface CDPatternItemViewController : NSViewController

// the thing we are editing
@property(weak) CDPatternItem *patternItem;

@end

@interface NSObject(ResponderStuff)
- (void)_patternItemChanged:(id)sender;
@end

extern NSString *g_patternTypeNames[LEDPatternTypeMax+1];