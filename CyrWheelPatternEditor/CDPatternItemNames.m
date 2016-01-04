//
//  CDPatternItemNames.m
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 1/3/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

#import "CDPatternItemNames.h"

@implementation CDPatternItemNames

+ (NSString *)nameForPatternType:(LEDPatternType)type {
    return g_patternTypeNames[type];
    
}

@end



// Mapping from the type to the string we display. Yeah, not localized
NSString *g_patternTypeNames[LEDPatternTypeMax+1] =  {
    
    @"Rotating Rainbow",
    @"Mini Rotating Rainbows",
    
    @"Fade Out",
    @"Fade In",
    @"Color Wipe",
    @"Do nothing",
    
    @"Theater Chase",
    
    @"Gradient",
    @"Pulse Gradient",
    @"Random Gradients",
    
    @"Image Linear Fade",
    @"Image Strip",
    
    @"Warm white shimmer",
    @"Random color walk",
    @"Traditional colors",
    @"Color explosion",
    @"Gradient 2",
    @"White Bright Twinkle",
    @"White and Red Twinkle",
    @"Red and Green Twinkle",
    @"Multi-color Twinkle",
    
    @"Collission",
    
    @"Sine Wave",
    
    @"Bottom Glow",
    @"Rotating Bottom Glow",
    
    @"Solid Color",
    
    @"Solid Rainbow",
    @"Rainbow with spaces",
    
    @"Blink",
    
    @"Fire",
    @"Blue Fire",
    
    @"Flag Effect",
    
    @"Crossfade",
    
    @"SinWave Effect",
    
    @"Funky Clouds",
    
    @"Life (Full)",
    @"Life (Dynamic)",
    
    @"Bounce",
    @"Rainbow Fire",
    @"Lava Fire",
    @"LEDPatternTypeBitmap",
    
    @"All Off"
};


