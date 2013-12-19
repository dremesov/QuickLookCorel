//
//  ISLCorelGraphicsFile.h
//  QuickLookCorel
//
//  Created by Dmitry Remesov on 18.12.13.
//  Copyright (c) 2013 iSoftLab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _tag_ISLCorelGraphicsFileType {
    kISLCorelGraphicsFileRIFF = 0x52494646, // 'RIFF'
    kISLCorelGraphicsFileZip = 0x504b0304   // 'PK\x03\x04'
} ISLCorelGraphicsFileType;

@interface ISLCorelGraphicsFile : NSObject

@property (readonly) ISLCorelGraphicsFileType fileType;

- (id)initWithURL:(NSURL*)url;
- (CGImageRef)thumbnailCGImage;

@end
