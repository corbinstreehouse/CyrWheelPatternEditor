//
//  CDCyrWheelConnection.h
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/1/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//





// TODO: kill this file

#import <Foundation/Foundation.h>
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



- (void)sendCommand:(CDCyrWheelCommand)command;

- (void)uploadNewSequence:(CDCyrWheelSequence *)sequence;

//- (void)getSequencesWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)playSequence:(CDCyrWheelSequence *)sequence;
- (void)addSequence:(CDCyrWheelSequence *)sequence;
- (void)deleteSequence:(CDCyrWheelSequence *)sequence;

// Changes to a "dynamic" sequence and starts playing this pattern that was picked until another pattern is chosen
- (void)setPatternItem:(CDCyrWheelPattern *)pattern;

@end
