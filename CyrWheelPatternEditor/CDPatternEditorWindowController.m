//
//  CDPatternEditorWindowController.m
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/16/14 .
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import "CDPatternEditorWindowController.h"
#import "CDPatternItem.h"
#import "CDDocument.h"
#import "CDPatternData.h"

@interface CDPatternEditorWindowController () {
    
}
    
@property (weak) IBOutlet NSImageView *imgViewPreview;


@end

@implementation CDPatternEditorWindowController

- (id)init {
    self = [super initWithWindowNibName:[self className] owner:self];
    return self;
}
    
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    
    
    
    
    return self;
}

- (CDDocument *)document {
    return (CDDocument *)super.document;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSAssert(self.document.patternItem != nil, @"pattern item");
    NSData *imageData = self.document.patternItem.image;
    if (imageData) {
        NSImage *image = [[NSImage alloc] initWithData:imageData];
        [self _setPatternImage:image];
    }
}

- (void)_setPatternImage:(NSImage *)image {
    self.imgViewPreview.image = image;
}

- (void)_setImageWithURL:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    self.document.patternItem.image = data; // save the original data
    NSImage *image = [[NSImage alloc] initWithData:data];
    // TODO: maybe save a reference to the image so it can be edited externally too??
    [self _setPatternImage:image];
}
    
- (IBAction)btnLoadImageClicked:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    op.allowedFileTypes = @[@"public.image"]; // [NSImage imageFileTypes] ?
    op.allowsMultipleSelection = NO;
    op.allowsOtherFileTypes = NO;
    [op beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            [self _setImageWithURL:op.URL];
        }
    }];
}

- (NSMutableData *)_encodeRepAsRGB:(NSBitmapImageRep *)imageRep {
    NSMutableData *result = [NSMutableData new];
    // pre-allocate cuz we know the size
    NSInteger length = sizeof(uint8) * 3 * imageRep.pixelsWide * imageRep.pixelsHigh;
    [result setLength:length];
    uint8 *bytes = (uint8 *)result.mutableBytes;
    // Go from top to bottom, and scan horizontal lines. That is the easiest thing to do for all images. How we interpret the data is up to the kind (although, that might affect encoding..)
    for (NSInteger y = 0; y < imageRep.pixelsHigh; y++) {
        for (NSInteger x = 0; x < imageRep.pixelsWide; x++) {
            NSColor *color = [imageRep colorAtX:x y:y]; // convert to NSDeviceRGB?? or calibrated RBG? Otherwise, this will throw...
            // Write out the pixels.. RGB..ignore alpha
            CGFloat r, g, b, a;
            [color getRed:&r green:&g blue:&b alpha:&a];
            *bytes = r*255;
            bytes++;
            *bytes = g*255;
            bytes++;
            *bytes = b*255;
            bytes++;
        }
    }
    return result;
}

static inline uint16_t _NSTimeIntervalToMS(NSTimeInterval duration) {
    return ceil(duration * 1000);
}

- (void)_encodDataForPatternItem:(CDPatternItem *)item handler:(void (^)(NSMutableData *encodedImageData, CDPatternDataHeader *header, NSError *error))handler {
    // Probably not fast...but it doesn't matter...
    // Convert to a bitmap image rep to walk over the pixels..
    NSData *tiffData = item.image;
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    NSMutableData *data = [self _encodeRepAsRGB:imageRep];
    // TODO: encode in other ways...find the smallest, use that.
    
    CDPatternDataHeader pd;
    // hardcoded maxes based on what i used in the structre
    if (data.length > UINT32_MAX/* || imageRep.pixelsHigh > UINT16_MAX || imageRep.pixelsWide > UINT16_MAX*/) {
        NSError *error = [NSError errorWithDomain:@"image or data size exceeds 16-bit size. time for me to up data sizes..." code:0 userInfo:nil];
        handler(nil, nil, error);
    } else {
        // Append the rest the stuff we care about
        // The format is CDPatternData.....but backwards
        pd.patternType = item.patternType;
        pd.dataLength = (uint32_t)data.length;
        // pixels are what size the app designed it in; it may not be applicable..
        pd.pixels = (uint32_t)item.pixelCount;
        pd.duration = _NSTimeIntervalToMS(item.duration);
        handler(data, &pd, nil);
        //[data appendBytes:&pd length:sizeof(pd)];
    }
}

static inline NSString *intToStr(long integer) {
    return [NSString stringWithFormat:@"%ld", integer];
}

// Sort of ugly...
- (NSString *)_headerStringForData:(NSData *)data patternHeader:(CDPatternDataHeader *)header {
    NSMutableString *bytesAsString = [[NSMutableString alloc] init];
    /* // 10.9
     __block NSInteger col = 0;
     __block NSInteger count = 0;
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        for (NSInteger i = byteRange.location; i < NSMaxRange(byteRange); i++) {
            col++;
            count++;
            uint8 *iPtr = (uint8 *)bytes;
            if (col >= 50*3) {
                col = 0;
                [bytesAsString appendFormat:@"%d,\n", iPtr[i]];
            } else if (col % 3 == 0) {
                [bytesAsString appendFormat:@"\t%d, ", iPtr[i]];
            } else {
                [bytesAsString appendFormat:@"%d, ", iPtr[i]];
            }
        }
    }];
     NSAssert(header->dataLength == count, @"count check");
     */
    
    NSInteger col = 0;
    uint8 *iPtr = (uint8 *)data.bytes;
    for (NSInteger i = 0; i < data.length; i++) {
        if (col >= 10*3) {
            col = 0;
            [bytesAsString appendFormat:@"\n%d,", iPtr[i]];
        } else if (col % 3 == 0) {
            [bytesAsString appendFormat:@"\t%d,", iPtr[i]];
        } else {
            [bytesAsString appendFormat:@"%d,", iPtr[i]];
        }
        col++;
    }
    
    
    // TODO: URL from resources: /corbin/Projects/Ardu  ino/LEDDigitalCyrWheel/LEDDigitalCyrWheel/CDExportedImage_Template.h
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"CDExportedImage_Template" withExtension:@".h"];
    NSMutableString *template = [NSMutableString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    
    /*    {
     %DATA%
     },
     // CDPatternDataHeader
     {
     %PATTERN_TYPE%,
     %DURATION%,
     %PIXELS%,
     %LENGTH%
     }
     };

     */
    
    [template replaceOccurrencesOfString:@"%PATTERN_TYPE%" withString:intToStr(header->patternType) options:0 range:NSMakeRange(0, template.length)];
    [template replaceOccurrencesOfString:@"%DURATION%" withString:intToStr(header->duration) options:0 range:NSMakeRange(0, template.length)];
    [template replaceOccurrencesOfString:@"%PIXELS%" withString:intToStr(header->pixels) options:0 range:NSMakeRange(0, template.length)];
    [template replaceOccurrencesOfString:@"%LENGTH%" withString:intToStr(header->dataLength) options:0 range:NSMakeRange(0, template.length)];
    [template replaceOccurrencesOfString:@"%DATA%" withString:bytesAsString options:0 range:NSMakeRange(0, template.length)];
    return template;
}

- (IBAction)_btnSaveDataClicked:(id)sender {
    [self _encodDataForPatternItem:self.document.patternItem handler:^(NSMutableData *encodedImageData, CDPatternDataHeader *header, NSError *error) {
        if (error) {
            [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
        } else {
            NSString *str = [self _headerStringForData:encodedImageData patternHeader:header];
            NSLog(@"%@", str);
        }
    }];
}

@end
