//
//  ISLRiffChunk.m
//  QuickLookCorel
//
//  Created by Dmitry Remesov on 19.12.13.
//  Copyright (c) 2013 iSoftLab. All rights reserved.
//

#import "ISLRiffChunk.h"
#import <zlib.h>

@interface ISLRiffChunk ()

@property (readwrite,strong) NSData* data;
@property (readwrite,strong) NSData* inflatedData;
@property (readwrite,strong) NSData* fullData;
@property (readwrite,strong) NSData* blockSizes;

@end

@interface NSData (ZlibAdditions)
- (NSData *) zaInflate;
- (NSData *) zaDeflate;
@end

@implementation NSData (ZLibAdditions)

- (NSData *) zaInflate
{
	NSUInteger full_length = [self length];
	NSUInteger half_length = full_length / 2;
    
	NSMutableData *inflatedData = [NSMutableData dataWithLength:full_length + half_length];
	BOOL done = NO;
	int status;
    
	z_stream strm;
    
	strm.next_in = (Bytef *)[self bytes];
	strm.avail_in = (unsigned int)[self length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
    
	if (inflateInit2(&strm, MAX_WBITS) != Z_OK) return nil;
	while (!done) {
		if (strm.total_out >= [inflatedData length])
			[inflatedData increaseLengthBy:half_length];
		strm.next_out = [inflatedData mutableBytes] + strm.total_out;
		strm.avail_out = (unsigned int)([inflatedData length] - strm.total_out);
		status = inflate(&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) break;
	}
	if (inflateEnd(&strm) == Z_OK && done)
		[inflatedData setLength:strm.total_out];
	else
		inflatedData = nil;
	return inflatedData;
}

- (NSData *) zaDeflate
{
	z_stream strm;
    
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in = (Bytef *)[self bytes];
	strm.avail_in = (unsigned int)[self length];
    
	NSMutableData *deflatedData = [NSMutableData dataWithLength:16384];
	if (deflateInit2(&strm, Z_BEST_COMPRESSION, Z_DEFLATED, MAX_WBITS, 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
	do {
		if (strm.total_out >= [deflatedData length])
			[deflatedData increaseLengthBy:16384];
		strm.next_out = [deflatedData mutableBytes] + strm.total_out;
		strm.avail_out = (unsigned int)([deflatedData length] - strm.total_out);
		deflate(&strm, Z_FINISH);
	} while (strm.avail_out == 0);
	deflateEnd(&strm);
	[deflatedData setLength:strm.total_out];
    
	return deflatedData;
}

@end

@implementation NSString (FourCCConverter)

+ (NSString*)stringWithFourCC:(FourCharCode)fcc
{
#if __LITTLE_ENDIAN__
    return [NSString stringWithFormat:@"%c%c%c%c", ((char*)(&fcc))[0], ((char*)(&fcc))[1], ((char*)(&fcc))[2], ((char*)(&fcc))[3]];
#else
    return [NSString stringWithFormat:@"%c%c%c%c", ((char*)(&fcc))[3], ((char*)(&fcc))[2], ((char*)(&fcc))[1], ((char*)(&fcc))[0]];
#endif
}

@end

@implementation ISLRiffChunk

@synthesize subChunks = _subChunks;

- (NSArray*)subChunks
{
    return _subChunks ? [_subChunks copy] : @[];
}

- (BOOL)isCompressed
{
    return (_inflatedData != nil);
}

#pragma pack(push, 1)
typedef struct __tag_CompressedListChunkHeader {
    uint32_t compressedSize;
    uint32_t uncompressedSize;
    uint32_t blockSizesArraySize;
    uint32_t _unused1;
    uint32_t signature[2];
} ISLRiffCompressedListChunkHeader;
#pragma pack(pop)

- (id)initWithData:(NSData *)data andBlockSizes:(NSData *)blockSizes
{
    if ((self = [super init])) {
        self.blockSizes = blockSizes;
        self.fullData = data;
        NSUInteger dataLength = [data length];
        uint32_t chunkDataLength = 0;
        
        if (dataLength >= sizeof(_fourCC) + sizeof(chunkDataLength)) {
            [data getBytes:&_fourCC length:sizeof(_fourCC)];
            [data getBytes:&chunkDataLength range:NSMakeRange(sizeof(_fourCC), sizeof(chunkDataLength))];
            _fourCC = NSSwapLittleIntToHost(_fourCC);
            chunkDataLength = NSSwapLittleIntToHost(chunkDataLength);
            if (_blockSizes && chunkDataLength < [_blockSizes length]/sizeof(uint32_t))
                chunkDataLength = NSSwapLittleIntToHost(((uint32_t*)[_blockSizes bytes])[chunkDataLength]);
            
            if (dataLength >= sizeof(_fourCC) + sizeof(chunkDataLength) + chunkDataLength) {
                NSUInteger offset = sizeof(_fourCC) + sizeof(chunkDataLength);
                
                if (_fourCC == kISLRiffChunkMagicRIFF || _fourCC == kISLRiffChunkMagicLIST) {
                    [data getBytes:&_identifier range:NSMakeRange(offset, sizeof(_identifier))];
                    _identifier = NSSwapLittleIntToHost(_identifier);
                    _hasIdentifier = YES;
                    offset += sizeof(_identifier);
                    chunkDataLength -= sizeof(_identifier);
                    _subChunks = [[NSMutableArray alloc] init];
                }
                
                self.data = [NSData dataWithBytesNoCopy:(void*)([data bytes] + offset)
                                                 length:chunkDataLength
                                           freeWhenDone:NO];
                
                if (_fourCC == kISLRiffChunkMagicLIST && _identifier == FOURCC('c', 'm', 'p', 'r')) {
                    ISLRiffCompressedListChunkHeader *cmprHeader = (ISLRiffCompressedListChunkHeader*)[_data bytes];
                    cmprHeader->compressedSize = NSSwapLittleIntToHost(cmprHeader->compressedSize);
                    cmprHeader->uncompressedSize = NSSwapLittleIntToHost(cmprHeader->uncompressedSize);
                    cmprHeader->blockSizesArraySize = NSSwapLittleIntToHost(cmprHeader->blockSizesArraySize);
                    cmprHeader->signature[0] = NSSwapLittleIntToHost(cmprHeader->signature[0]);
                    cmprHeader->signature[1] = NSSwapLittleIntToHost(cmprHeader->signature[1]);
                    
                    if (cmprHeader->signature[0] == FOURCC('C', 'P', 'n', 'g') &&
                        cmprHeader->signature[1] == FOURCC(1, 0, 4, 0)) {

                        self.inflatedData = [[NSData dataWithBytesNoCopy:(void *)(cmprHeader + 1)
                                                                  length:cmprHeader->compressedSize - sizeof(cmprHeader->signature)
                                                            freeWhenDone:NO] zaInflate];
                        
                        NSData *bsArray = [[NSData dataWithBytesNoCopy:(void *)(cmprHeader + 1) + cmprHeader->compressedSize
                                                                length:cmprHeader->blockSizesArraySize - sizeof(cmprHeader->signature)
                                                          freeWhenDone:NO] zaInflate];
                        
                        if ([_inflatedData length]) {
                            for (NSUInteger offs = 0, len = [_inflatedData length]; offs < len;) {
                                ISLRiffChunk *newChunk = [[ISLRiffChunk alloc] initWithData:[NSData dataWithBytesNoCopy:(void*)([_inflatedData bytes] + offs)
                                                                                                                 length:len - offs
                                                                                                           freeWhenDone:NO]
                                                                              andBlockSizes:bsArray];
                                if (newChunk) {
                                    [(NSMutableArray*)_subChunks addObject:newChunk];
                                    offs += [newChunk.data length] + ([newChunk.data length] & 1) + 2*sizeof(_fourCC) + (newChunk.hasIdentifier ? sizeof(_identifier) : 0);
                                }
                            }
                        }
                    }
                } else if (_fourCC == kISLRiffChunkMagicLIST && _identifier == FOURCC('s', 't', 'l', 't')) {
                    NSLog(@"Found stlt");
                } else if (_subChunks) {
                    for (offset = 0; offset < chunkDataLength;) {
                        ISLRiffChunk *newChunk = [[ISLRiffChunk alloc] initWithData:[NSData dataWithBytesNoCopy:(void*)([_data bytes] + offset)
                                                                                                         length:chunkDataLength - offset
                                                                                                   freeWhenDone:NO]
                                                                      andBlockSizes:self.blockSizes];
                        if (newChunk) {
                            [(NSMutableArray*)_subChunks addObject:newChunk];
                            offset += [newChunk.data length] + ([newChunk.data length] & 1) + sizeof(_fourCC) + sizeof(chunkDataLength) + (newChunk.hasIdentifier ? sizeof(_identifier) : 0);
                        }
                    }
                }
            } else {
                self.fullData = nil;
                @throw [NSException exceptionWithName:NSRangeException
                                               reason:[NSString stringWithFormat:@"Data object %@ ... (size = %lu) is incorrect",
                                                       [NSData dataWithBytesNoCopy:(void*)[data bytes] length:32 freeWhenDone:NO],
                                                       (unsigned long)[data length]]
                                             userInfo:nil];
            }
        } else {
            self.fullData = nil;
            @throw [NSException exceptionWithName:NSRangeException
                                           reason:[NSString stringWithFormat:@"Data object %@ ... (size = %lu) is smaller than expected",
                                                   [NSData dataWithBytesNoCopy:(void*)[data bytes] length:32 freeWhenDone:NO],
                                                   (unsigned long)[data length]]
                                         userInfo:nil];
        }
        
    }
    return self;
}

- (id)initWithData:(NSData*)data
{
    return [self initWithData:data andBlockSizes:nil];
}

@end
