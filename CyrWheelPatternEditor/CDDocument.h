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

- (CDPatternItem *)addNewPatternItem;
- (void)removePatternItemsAtIndexes:(NSIndexSet *)indexes;

@end

extern NSString *CDCompiledSequenceTypeName;

NS_ASSUME_NONNULL_END