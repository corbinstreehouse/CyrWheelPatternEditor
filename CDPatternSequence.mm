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

- (void)insertChildren:(NSArray *)values atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet insertObjects:values atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}


/*

- (void)insertObject:(<#Type#> *)value in<#Property#>AtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}

- (void)removeObjectFrom<#Property#>AtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}


- (void)remove<#Property#>AtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}

- (void)replaceObjectIn<#Property#>AtIndex:(NSUInteger)idx withObject:(<#Type#> *)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}

- (void)replace<#Property#>AtIndexes:(NSIndexSet *)indexes with<#Property#>:(NSArray *)values {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:values];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
}

- (void)add<#Property#>Object:(<#Type#> *)value {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    NSUInteger idx = [tmpOrderedSet count];
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    [tmpOrderedSet addObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)remove<#Property#>Object:(<#Type#> *)value {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    NSUInteger idx = [tmpOrderedSet indexOfObject:value];
    if (idx != NSNotFound) {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
        [tmpOrderedSet removeObject:value];
        [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    }
}

- (void)add<#Property#>:(NSOrderedSet *)values {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
        [tmpOrderedSet addObjectsFromArray:[values array]];
        [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    }
}

- (void)remove<#Property#>:(NSOrderedSet *)values {
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:CDPatternChildrenKey]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        [self setPrimitiveValue:tmpOrderedSet forKey:CDPatternChildrenKey];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:CDPatternChildrenKey];
    }
}
 */

@end
