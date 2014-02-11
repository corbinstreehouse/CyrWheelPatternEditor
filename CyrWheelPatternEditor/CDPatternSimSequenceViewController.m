//
//  CDPatternSimSequenceViewController.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/10/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternSimSequenceViewController.h"

@interface CDPatternSimSequenceViewController ()

@end

@implementation CDPatternSimSequenceViewController

- (id)init {
    self = [super initWithNibName:[self className] bundle:nil];
    return self;
}

- (IBAction)btnNextSequenceClicked:(id)sender {
    self.nextSequenceHandler();
}

@end
