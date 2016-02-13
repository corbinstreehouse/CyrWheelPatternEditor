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

NS_ASSUME_NONNULL_BEGIN

@interface CDDocument : NSPersistentDocument

@property(retain, readonly) CDPatternSequence *patternSequence;

// Created and added to children
- (CDPatternItem *)addNewPatternItem;

// Temporary items must be removed from the manage object context after it is done being used, or added as a child.
- (CDPatternItem *)makeTemporaryPatternItem;
- (void)removeTemporaryPatternItem:(CDPatternItem *)item;
- (void)addPatternItemToChildren:(CDPatternItem *)item;
- (void)removePatternItemsAtIndexes:(NSIndexSet *)indexes;
- (NSData *)exportToData;

@end

extern NSString *CDCompiledSequenceTypeName;

NS_ASSUME_NONNULL_END