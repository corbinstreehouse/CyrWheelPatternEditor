//
//  CDDocument.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDPatternItem.h"
#import "CDPatternSequence.h"

@interface CDDocument : NSPersistentDocument

@property(retain, readonly) CDPatternSequence *patternSequence;

@end
