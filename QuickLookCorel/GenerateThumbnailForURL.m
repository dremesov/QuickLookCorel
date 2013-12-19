#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ISLCorelGraphicsFile.h"

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef cfurl, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    if (QLThumbnailRequestIsCancelled(thumbnail))
        return noErr;
    
    @autoreleasepool {
        NSURL *url = (__bridge NSURL*)cfurl;
        ISLCorelGraphicsFile *cgFile = [[ISLCorelGraphicsFile alloc] initWithURL:url];
        if (cgFile.fileType) {
            CGImageRef img = [cgFile thumbnailCGImage];
            if (img) {
                CGContextRef ctx = QLThumbnailRequestCreateContext(thumbnail, maxSize, YES, nil);
                if (ctx) {
                    CGContextDrawImage(ctx, NSMakeRect(0, 0, maxSize.width, maxSize.height), img);
                    QLThumbnailRequestFlushContext(thumbnail, ctx);
                    CFRelease(ctx);
                }
            }
        }
        cgFile = nil;
    }
    
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
