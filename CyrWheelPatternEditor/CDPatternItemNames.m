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
    if (type >= 0 && type <= LEDPatternTypeCount) {
        return g_patternTypeNames[type];
    } else {
        NSAssert(NO, @"bad type requested!");
        return @"";
    }
}

@end



// Mapping from the type to the string we display. Yeah, not localized
NSString *g_patternTypeNames[LEDPatternTypeCount+1] =  {
    
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
    
    @"Image Type",
    @"Image Type 2 (UNUSED)",
    
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
    @"Bottom Glow - Rotating",
    
    @"Solid Color",
    
    @"Solid Rainbow",
    @"Rainbow with spaces",
    
    @"Blink",
    
    @"Fire",
    @"Blue Fire",
    
    @"Flag Effect",
    
    @"Crossfade [Transition]",
    
    @"Sine Wave Effect",
    
    @"Funky Clouds",
    
    @"Life (Full)",
    @"Life (Dynamic)",
    
    @"Bounce",
    @"Rainbow Fire",
    @"Lava Fire",
    @"LEDPatternTypeBitmap",
    @"Fade In - Fade Out",
    @"LEDPatternTypeCount" // Should be hidden
};


