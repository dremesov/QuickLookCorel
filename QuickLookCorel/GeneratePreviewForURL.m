#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ISLCorelGraphicsFile.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef cfurl, CFStringRef contentTypeUTI, CFDictionaryRef options)
{    
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    
    @autoreleasepool {
        NSURL *url = (__bridge NSURL*)cfurl;
        ISLCorelGraphicsFile *cgFile = [[ISLCorelGraphicsFile alloc] initWithURL:url];
        if (cgFile.fileType) {
            CGImageRef img = [cgFile previewCGImage];
            if (img) {
                CGSize imgSize = NSMakeSize(CGImageGetWidth(img), CGImageGetHeight(img));
                CGContextRef ctx = QLPreviewRequestCreateContext(preview, imgSize, YES, nil);
                if (ctx) {
                    CGContextDrawImage(ctx, NSMakeRect(0, 0, imgSize.width, imgSize.height), img);
                    QLPreviewRequestFlushContext(preview, ctx);
                    CFRelease(ctx);
                }
            }
        }
        cgFile = nil;
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
