//
//  CDCyrWheelSequence.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/2/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>

/* This is a sequence (a group of patterns) on the wheel; I was thinking of using CDPatternSequence, but this is much easier and can add more dynamic information. It effectively is an objc wrapper around CDPatternSequenceHeader. */
@interface CDCyrWheelSequence : NSObject

// It might be nice to have other properties too..but having them here would involve opening all the files and reading the data on startup. I'm not sure I want to do that...
@property (copy) NSString *name;
@property (copy) NSString *action;
@property BOOL editable;

@end
