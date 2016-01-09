//
//  CDPatternSimSequenceViewController.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/10/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDPatternSequence.h"

@class CDPatternSimulatorDocument;
@class CDPatternRunner;

@interface CDPatternSimSequenceViewController : NSViewController

@property CDPatternRunner *patternRunner; 

@end
