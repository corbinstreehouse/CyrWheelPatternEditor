//
//  CDCyrWheelConnection.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/1/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDCyrWheelConnection.h"
#import "CDCyrWheelPattern.h"

static const char *CDWheelCommandToPath[] = {
    "command/next_pattern", //CDCyrWheelCommandNextPattern,
    "command/prior_pattern", //CDCyrWheelCommandPriorPattern,
    "command/next_sequence", // CDCyrWheelCommandNextSequence,
    "command/prior_sequence", // CDCyrWheelCommandPriorSequence,
    "command/restart_sequence", //CDCyrWheelCommandRestartSequence,
    "command/start_calibration", // CDCyrWheelCommandStartCalibrating,
    "command/end_calibration", //CDCyrWheelCommandEndCalibrating,
    "command/cancel_calibration", //CDCyrWheelCommandEndCalibrating,
    "command/start_saving_gyro_data", // CDCyrWheelCommandStartSavingGyroData,
    "command/end_saving_gyro_data", // CDCyrWheelCommandEndSavingTyroData,
};

@interface CDCyrWheelConnection() {
@private
    
}


@end

@implementation CDCyrWheelConnection

- (id)init {
    self = super.init;
    return self;
}


- (void)playSequence:(CDCyrWheelSequence *)sequence {

}

- (void)deleteSequence:(CDCyrWheelSequence *)sequence {
}

- (void)setDynamicPatternItem:(CDCyrWheelPattern *)pattern {
    
}


@end
