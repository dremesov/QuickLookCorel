//
//  ISLCorelGraphicsFile.h
//  QuickLookCorel
//
//  Created by Dmitry Remesov on 18.12.13.
//  Copyright (c) 2013 iSoftLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISLRiffChunk.h"

typedef enum _tag_ISLCorelGraphicsFileType {
    kISLCorelGraphicsFileRIFF = kISLRiffChunkMagicRIFF,
    kISLCorelGraphicsFileZip = FOURCC('P','K',3,4)
} ISLCorelGraphicsFileType;

@interface ISLCorelGraphicsFile : NSObject

@property (readonly) ISLCorelGraphicsFileType fileType;

- (id)initWithURL:(NSURL*)url;
- (CGImageRef)thumbnailCGImage;
- (CGImageRef)previewCGImage;

@end
