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
@property (strong, nonatomic) ISLRiffChunk *riff;
@end

#pragma pack(push,1)
typedef struct tagBITMAPFILEHEADER {
    uint16_t    bfType;
    uint32_t    bfSize;
    uint32_t    bfReserved;
    uint32_t    bfOffBits;
} BITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER {
    uint32_t    biSize;
    int32_t     biWidth;
    int32_t     biHeight;
    uint16_t    biPlanes;
    uint16_t    biBitCount;
    uint32_t    biCompression;
    uint32_t    biSizeImage;
    int32_t     biXPelsPerMeter;
    int32_t     biYPelsPerMeter;
    uint32_t    biClrUsed;
    uint32_t    biClrImportant;
} BITMAPINFOHEADER;
#pragma pack(pop)

@implementation ISLCorelGraphicsFile

@synthesize riff = _riff;

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
                NSData *fileHeader = [fh readDataOfLength:12];
                uint32_t magic = NSSwapLittleIntToHost(*((uint32_t*)[fileHeader bytes]));
                uint32_t riffType = NSSwapLittleIntToHost(((uint32_t*)[fileHeader bytes])[2]);
                if ((magic == kISLCorelGraphicsFileRIFF &&
                     (riffType & FOURCC(0xff, 0xff, 0xff, 0)) == FOURCC('C', 'D', 'R', 0)) ||
                    magic == kISLCorelGraphicsFileZip) {
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

- (ISLRiffChunk*)riff
{
    if (!_riff && _fileURL && _fileType) {
        switch (_fileType) {
            case kISLCorelGraphicsFileRIFF:
                _riff = [[ISLRiffChunk alloc] initWithData:[NSData dataWithContentsOfURL:_fileURL]];
                break;

            case kISLCorelGraphicsFileZip:
                _riff = [[ISLRiffChunk alloc] initWithData:[self dataFromZip:@"content/riffData.cdr"]];
                break;
                
            default:
                break;
        }
    }
    return _riff;
}

- (CGImageRef)thumbnailCGImage
{
    switch (_fileType) {
        case kISLCorelGraphicsFileZip:
            return [[[NSBitmapImageRep alloc] initWithData:[self dataFromZip:@"metadata/thumbnails/thumbnail.bmp"]] CGImage];
            
        case kISLCorelGraphicsFileRIFF:
            if (self.riff) {
                for (ISLRiffChunk *chunk in self.riff.subChunks) {
                    if (chunk.fourCC == FOURCC('D', 'I', 'S', 'P')) {
                        NSMutableData *thumbnailData = [NSMutableData dataWithCapacity:sizeof(BITMAPFILEHEADER) + chunk.data.length - 4];
                        [thumbnailData increaseLengthBy:sizeof(BITMAPFILEHEADER)];
                        [thumbnailData appendData:[NSData dataWithBytesNoCopy:(void *)chunk.data.bytes + 4
                                                                       length:chunk.data.length - 4
                                                                 freeWhenDone:NO]];
                        
                        BITMAPFILEHEADER *bmFileHeader = (BITMAPFILEHEADER *)[thumbnailData bytes];
                        BITMAPINFOHEADER *bmpInfo = (BITMAPINFOHEADER *)(bmFileHeader + 1);
                        bmFileHeader->bfType = *(uint16_t*)"BM";
                        bmFileHeader->bfSize = NSSwapHostIntToLittle((uint32_t)thumbnailData.length);
                        bmFileHeader->bfOffBits = NSSwapHostIntToLittle((uint32_t)thumbnailData.length - NSSwapLittleIntToHost(bmpInfo->biSizeImage));

                        return [[[NSBitmapImageRep alloc] initWithData:thumbnailData] CGImage];
                    }
                }
                return [self previewCGImage];
            }
    }
    return nil;
}

- (NSData*)dataFromZip:(NSString*)fileName
{
    if (_fileType == kISLCorelGraphicsFileZip) {
        ZKDataArchive *archive = [ZKDataArchive archiveWithArchivePath:self.fileURL.path];
        if (archive) {
            for (NSObject *item in archive.centralDirectory) {
                if ([item isKindOfClass:[ZKCDHeader class]] &&
                    [[(ZKCDHeader*)item filename] caseInsensitiveCompare:fileName] == 0) {
                    NSDictionary *attrs = nil;
                    return [archive inflateFile:(ZKCDHeader *)item attributes:&attrs];
                }
            }
        }
    }
    return nil;
}

- (CGImageRef)previewCGImage
{
    if (self.riff)
        NSLog(@"Loaded RIFF %@", self.riff);
    
    return nil;
}
@end
