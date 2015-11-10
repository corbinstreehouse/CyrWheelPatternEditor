//
//  CDCyrWheelConnection.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/1/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "CDCyrWheelSequence.h"
#import "CDCyrWheelPattern.h"

typedef enum {
    CDCyrWheelCommandNextPattern = 0,
    CDCyrWheelCommandPriorPattern,
    CDCyrWheelCommandNextSequence,
    CDCyrWheelCommandPriorSequence,
    CDCyrWheelCommandRestartSequence,
    CDCyrWheelCommandStartCalibrating,
    CDCyrWheelCommandEndCalibrating,
    CDCyrWheelCommandCancelCalibrating,
    CDCyrWheelCommandStartSavingGyroData,
    CDCyrWheelCommandEndSavingGyroData,
    
} CDCyrWheelCommand;

@interface CDCyrWheelConnection : NSObject

@property(copy) NSString *name; // The wheel name/server name we connect to. Can only be set once (currently)

@property(readonly, getter=isAlive) BOOL alive;

- (void)sendCommand:(CDCyrWheelCommand)command success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)uploadNewSequence:(CDCyrWheelSequence *)sequence atURL:(NSURL *)url success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)getSequencesWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)playSequence:(CDCyrWheelSequence *)sequence;
- (void)deleteSequence:(CDCyrWheelSequence *)sequence;

- (void)cancelAllObjectRequests;
- (void)setDynamicPatternItem:(CDCyrWheelPattern *)pattern;

@end
