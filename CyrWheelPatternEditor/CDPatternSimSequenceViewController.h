//
//  CDPatternSimSequenceViewController.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/10/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDPatternSequence.h"

@interface CDPatternSimSequenceViewController : NSViewController

@property CDPatternSequence *patternSequence;
@property NSString *sequenceName;

@property(copy) void (^nextSequenceHandler)();
@property(copy) void (^startStopHandler)();

@end
