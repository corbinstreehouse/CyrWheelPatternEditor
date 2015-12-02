//
//  CDPatternSequence.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/30/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDPatternItem;

// Each document represents one pattern sequence to be played back.. each can be stored as a file.

// TODO: rename to "CDSequenceGroup"??
@interface CDPatternSequence : NSManagedObject

@property (nonatomic) NSString *name; // The filename when I use this to upload a new item...etc

@property (nonatomic) int32_t pixelCount; // TODO: remove this option
@property (nonatomic, retain) NSOrderedSet<CDPatternItem *> *children;
@property (nonatomic) BOOL ignoreSingleClickButtonForTimedPatterns;
@end

extern NSString *CDPatternChildrenKey;

@interface CDPatternSequence (CoreDataGeneratedAccessors)

+ (instancetype)newPatternSequenceInContext:(NSManagedObjectContext *)context;

- (void)insertObject:(CDPatternItem *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(CDPatternItem *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;
- (void)addChildrenObject:(CDPatternItem *)value;
- (void)removeChildrenObject:(CDPatternItem *)value;
- (void)addChildren:(NSOrderedSet *)values;
- (void)removeChildren:(NSOrderedSet *)values;
@end
