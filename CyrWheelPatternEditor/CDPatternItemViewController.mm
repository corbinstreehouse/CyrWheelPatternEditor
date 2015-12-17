//
//  CDPatternItemViewController.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/30/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternItemViewController.h"
#import "CDPatternData.h"


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



@interface CDPatternItemViewController () {
@private
    __weak CDPatternItem *_patternItem;
    
}

@property BOOL durationEnabled;

@property (weak) IBOutlet NSPopUpButton *popupPatternType;

@property (weak) IBOutlet NSTextField *txtfldDuration;
@property (weak) IBOutlet NSPopUpButton *popupDurationType;
@property (weak) IBOutlet NSImageView *imgViewPreview;

@end


@implementation CDPatternItemViewController

- (id)init {
    self = [super initWithNibName:[self className] bundle:nil];
    return self;
}

@dynamic patternItem, durationEnabled;

- (void)loadView {
    [super loadView];
    [self __viewDidLoad];
}

//- (id)objectValue {
//    return self.patternItem;
//}
//
//- (void)setObjectValue:(id)v {
//    NSAssert(NO, @"no no no");// not alllwee
//}

- (IBAction)didChangePatternItemProperty:(id)sender {
    [NSApp sendAction:@selector(_patternItemChanged:) to:nil from:self.view];
}

- (IBAction)didChangeDuration:(id)sender {
    
}

- (IBAction)didChangeVelocityBasedBrightness:(id)sender {
    
}

// TODO: use appkit viewDidLoad when available
- (void)__viewDidLoad {
    [_popupPatternType removeAllItems];
    for (NSInteger i = 0; i <= LEDPatternTypeMax; i++) {
        [_popupPatternType addItemWithTitle:(NSString *)g_patternTypeNames[i]];
        NSMenuItem *item = [_popupPatternType lastItem];
        item.tag = i;
    }
    // update the UI since we changed the content
    if (_patternItem) {
        [_popupPatternType selectItemWithTag:_patternItem.patternType];
    }
}

- (IBAction)btnLoadImageClicked:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    op.allowedFileTypes = @[@"public.image"]; // [NSImage imageFileTypes] ?
    op.allowsMultipleSelection = NO;
    op.allowsOtherFileTypes = NO;
    [op beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            [self _setImageWithURL:op.URL];
        }
    }];
}

- (BOOL)durationEnabled {
    return self.patternItem.patternEndCondition == CDPatternEndConditionAfterDuration;
}

+ (NSSet *)keyPathsForValuesAffectingDurationEnabled {
    return [NSSet setWithObject:@"patternItem.patternEndCondition"];
}

- (IBAction)btnClearImageClicked:(id)sender {
    self.patternItem.imageData = nil;
}

- (void)setPatternItem:(CDPatternItem *)patternItem {
    if (_patternItem != patternItem) {
        _patternItem = patternItem;
    }
}

- (CDPatternItem *)patternItem {
    return _patternItem;
}

- (void)_setImageWithURL:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    self.patternItem.imageData = data; // save the original data..compressed,whatever
}



@end
