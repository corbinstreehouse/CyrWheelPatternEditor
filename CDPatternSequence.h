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
NS_ASSUME_NONNULL_BEGIN

// TODO: rename to "CDSequenceGroup"??
@interface CDPatternSequence : NSManagedObject

@property (nonatomic) NSString *name; // The base part of the filename; it is only set when I'm using the simulator portion to display what we are running, and isn't stored in the model

@property (nullable, retain) NSOrderedSet<CDPatternItem *> *children; // Unfortunately maybe nullable // nonatomic, but stupid
@property (nonatomic) BOOL ignoreSingleClickButtonForTimedPatterns;
@end

extern NSString *CDPatternChildrenKey;

@interface CDPatternSequence (CoreDataGeneratedAccessors)

+ (instancetype)newPatternSequenceInContext:(NSManagedObjectContext *)context;

- (void)insertObject:(CDPatternItem *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray<CDPatternItem *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(CDPatternItem *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;
- (void)addChildrenObject:(CDPatternItem *)value;
- (void)removeChildrenObject:(CDPatternItem *)value;
- (void)addChildren:(NSOrderedSet<CDPatternItem *> *)values;
- (void)removeChildren:(NSOrderedSet<CDPatternItem *> *)values;

- (BOOL)exportToURL:(NSURL *)url error:(NSError **)errorPtr;
- (NSData *)exportAsData;
- (NSData *)exportSingleItemAsData:(CDPatternItem *)item;

@end

NS_ASSUME_NONNULL_END
