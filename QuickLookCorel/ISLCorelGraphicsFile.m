//
//  ISLCorelGraphicsFile.m
//  QuickLookCorel
//
//  Created by Dmitry Remesov on 18.12.13.
//  Copyright (c) 2013 iSoftLab. All rights reserved.
//

#import "ISLCorelGraphicsFile.h"
#import <ZipKit/ZKDataArchive.h>
#import <ZipKit/ZKCDHeader.h>
#import <AppKit/AppKit.h>

@interface ISLCorelGraphicsFile ()
@property (copy) NSURL *fileURL;
@end

@implementation ISLCorelGraphicsFile

- (id)initWithURL:(NSURL *)url
{
    if ((self = [super init])) {
        NSError *error = nil;
        self.fileURL = url;
        NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
        if (!fh) {
            NSLog(@"%@: error opening %@: %@", [self className], url, error);
            self = nil;
        } else {
            @try {
                uint32_t magic = NSSwapLittleIntToHost(*((uint32_t*)[[fh readDataOfLength:4] bytes]));
                if (magic == kISLCorelGraphicsFileRIFF || magic == kISLCorelGraphicsFileZip) {
                    _fileType = magic;
                } else {
                    _fileType = 0;
                    NSLog(@"%@: %@ is of unknown type %x", [self className], url, magic);
                }
            }
            @catch (NSException *ex) {
                NSLog(@"%@: exception reading %@: %@", [self className], url, ex);
            }
            [fh closeFile];
        }
    }
    return self;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)dealloc
{
    self.fileURL = nil;
}

- (CGImageRef)thumbnailCGImage
{
    switch (_fileType) {
        case kISLCorelGraphicsFileZip:
            return [self thumbnailImageFromZip];
            
        case kISLCorelGraphicsFileRIFF:
            return [self previewImageFromRIFF];

        default:
            break;
    }
    return nil;
}

- (CGImageRef)thumbnailImageFromZip
{
    ZKDataArchive *archive = [ZKDataArchive archiveWithArchivePath:self.fileURL.path];
    if (archive) {
        for (NSObject *item in archive.centralDirectory) {
            if ([item isKindOfClass:[ZKCDHeader class]] &&
                [[(ZKCDHeader*)item filename] caseInsensitiveCompare:@"metadata/thumbnails/thumbnail.bmp"] == 0) {
                NSDictionary *attrs = nil;
                return [[[NSBitmapImageRep alloc] initWithData:[archive inflateFile:(ZKCDHeader *)item attributes:&attrs]] CGImage];
            }
        }
    }
    return nil;
}

- (CGImageRef)previewImageFromRIFF
{
    ISLRiffChunk *chunk = [[ISLRiffChunk alloc] initWithData:[NSData dataWithContentsOfURL:self.fileURL]];
    
    NSLog(@"Loaded RIFF %@", chunk);
    return nil;
}
@end
