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
@dynamic children, ignoreSingleClickButtonForTimedPatterns;
@synthesize name;

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

- (void)_writeHeaderToData:(NSMutableData *)data {
    CDPatternSequenceHeader header;
    bzero(&header, sizeof(CDPatternSequenceHeader));
    header.marker[0] = 'S';
    header.marker[1] = 'Q';
    header.marker[2] = 'C';
    header.version = SEQUENCE_VERSION;
    header.pixelCount = self.pixelCount;
    header.patternCount = self.children.count;
    header.ignoreButtonForTimedPatterns = self.ignoreSingleClickButtonForTimedPatterns;
    NSAssert(sizeof(header) == 14, @"did I change the size of the header and forget to recompile this file?");
    [data appendBytes:&header length:sizeof(header)];
}

- (BOOL)_writePatternItem:(CDPatternItem *)item toData:(NSMutableData *)data error:(NSError **)errorPtr {
    *errorPtr = nil;
    CDPatternItemHeader itemHeader;
    bzero(&itemHeader, sizeof(CDPatternItemHeader));
    itemHeader.patternType = item.patternType;
    // Duration is stored in seconds but the header uses ms, and we round.
    itemHeader.duration = round(item.duration * 1000);
    itemHeader.patternDuration = round(item.patternDuration * 1000);
    itemHeader.patternOptions = item.patternOptions;
    itemHeader.patternEndCondition = item.patternEndCondition;
    //    itemHeader.intervalCount = item.repeatCount;
    itemHeader.shouldSetBrightnessByRotationalVelocity = item.shouldSetBrightnessByRotationalVelocity ? 1 : 0;
    itemHeader.color = item.encodedColor;
    
    BOOL result = YES;
    if (item.patternTypeRequiresImageData) {
        // item.imageData is the raw image format. We have to convert it to something easier to deal with....
        NSData *encodedData = [item getImageDataWithEncoding:CDPatternEncodingTypeRGB24]; // TODO: we could figure out which is smallest and use that encoded type
        
        NSUInteger dataLength = encodedData.length;
        if (dataLength > UINT32_MAX) {
            // sort of ugly way to show errors
            *errorPtr = [NSError errorWithDomain:@"image or data size exceeds 32 bits in size. time for me to up data sizes..." code:0 userInfo:nil];
            result = NO;
        } else {
            itemHeader.dataLength = (uint32_t)dataLength;
            [data appendBytes:&itemHeader length:sizeof(itemHeader)];
            // Write the data
            if (dataLength > 0) {
                [data appendData:encodedData];
            }
        }
    } else {
        itemHeader.dataLength = 0;
        [data appendBytes:&itemHeader length:sizeof(itemHeader)];
    }
    return result;
}

- (BOOL)exportToURL:(NSURL *)url error:(NSError **)errorPtr {
    BOOL result = YES;
    NSMutableData *data = [NSMutableData new];
    [self _writeHeaderToData:data];
    for (NSInteger i = 0; i < self.children.count; i++) {
        CDPatternItem *item = self.children[i];
        if (![self _writePatternItem:item toData:data error:errorPtr]) {
            result = NO;
            break;
        }
    }
    
    if (result) {
        result = [data writeToURL:url options:0 error:errorPtr];
    }
    return result;
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
