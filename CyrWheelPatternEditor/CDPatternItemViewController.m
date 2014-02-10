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
static const NSString *g_patternTypeNames[CDPatternTypeMax] =  {
    
    @"Rainbow",
    @"Rainbow 2",
    @"Color Wipe",
    @"Gradient",
    @"Pulse Gradient",

    @"Image Fade",

    @"Warm white shimmer",
    @"Random color walk",
    @"Traditional colors",
    @"Color explosion",
    @"Gradient 2",
    @"Bright Twinkle",
    @"Collission",
};



@interface CDPatternItemViewController () {
@private
    __weak CDPatternItem *_patternItem;
    
}

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

@dynamic patternItem;

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

// TODO: use appkit viewDidLoad when available
- (void)__viewDidLoad {
    [_popupPatternType removeAllItems];
    for (NSInteger i = 0; i < CDPatternTypeMax; i++) {
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
        if (result == NSOKButton) {
            [self _setImageWithURL:op.URL];
        }
    }];
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
