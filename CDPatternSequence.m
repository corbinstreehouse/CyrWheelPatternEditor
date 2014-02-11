//
//  CDPatternSequence.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/30/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSequence.h"
#import "CDPatternItem.h"

NSString *CDPatternChildrenKey = @"children";

@implementation CDPatternSequence

@dynamic pixelCount;
@dynamic children;

+ (instancetype)newPatternSequenceInContext:(NSManagedObjectContext *)context {
    CDPatternSequence *result = [NSEntityDescription insertNewObjectForEntityForName:[self className] inManagedObjectContext:context];
    return result;
}

// apparently not implemented in core data.
// http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors

- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}


- (void)insertObject:(CDPatternItem *)value inChildrenAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}
@end
