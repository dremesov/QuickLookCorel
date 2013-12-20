//
//  ISLRiffChunk.h
//  QuickLookCorel
//
//  Created by Dmitry Remesov on 19.12.13.
//  Copyright (c) 2013 iSoftLab. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __LITTLE_ENDIAN__
#define FOURCC(c1,c2,c3,c4) (((uint32_t)(c4) << 24) | ((uint32_t)(c3) << 16) | ((uint32_t)(c2) << 8) | ((uint32_t)(c1)))
#else
#define FOURCC(c1,c2,c3,c4) (((uint32_t)(c1) << 24) | ((uint32_t)(c2) << 16) | ((uint32_t)(c3) << 8) | ((uint32_t)(c4)))
#endif

typedef enum __tag_RiffChunkMagic {
    kISLRiffChunkMagicRIFF = FOURCC('R', 'I', 'F', 'F'),
    kISLRiffChunkMagicLIST = FOURCC('L', 'I', 'S', 'T')
} ISLRiffChunkMagic;

@interface ISLRiffChunk : NSObject

@property (readonly,assign) FourCharCode fourCC;
@property (readonly,assign) FourCharCode identifier;
@property (readonly,strong) NSData* data;
@property (readonly,strong) NSData* inflatedData;
@property (readonly,strong) NSArray* subChunks;
@property (readonly,assign) BOOL hasSubChunks;
@property (readonly,assign) BOOL hasIdentifier;
@property (readonly,assign) BOOL isCompressed;

- (id)initWithData:(NSData*)data;

@end
