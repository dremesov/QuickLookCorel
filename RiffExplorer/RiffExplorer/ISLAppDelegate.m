//
//  ISLAppDelegate.m
//  RiffExplorer
//
//  Created by Dmitry Remesov on 21.12.13.
//  Copyright (c) 2013 iSoftLab. All rights reserved.
//

#import "ISLAppDelegate.h"

@implementation ISLRiffChunk (NSTreeContollerAdditions)

- (BOOL)isLeaf
{
    return !self.hasIdentifier;
}

- (NSString*)displayName
{
    return [[NSString stringWithFourCC:self.fourCC]
            stringByAppendingString:(self.hasIdentifier
                                     ? [NSString stringWithFormat:@" (%@)", [NSString stringWithFourCC:self.identifier]]
                                     : @"" )];
}

@end


@implementation ISLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.openPanel = [NSOpenPanel openPanel];
    self.openPanel.canChooseFiles = YES;
    self.openPanel.canChooseDirectories = NO;
    self.openPanel.canCreateDirectories = NO;
    self.openPanel.allowsMultipleSelection = NO;
    self.openPanel.allowedFileTypes = @[@"cdr", @"wav", @"avi"];
    
    [self.treeController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.treeController && [keyPath isEqualToString:@"selection"]) {
        self.selectedChunk = [self.treeController.selectedObjects lastObject];
        if (self.selectedChunk)
            [self.table reloadData];
    }
}

- (void)openDocument:(id)sender
{
    [self.openPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            self.treeController.content = nil;
            self.treeController.childrenKeyPath = nil;
            self.treeController.countKeyPath = nil;
            self.treeController.leafKeyPath = nil;
            self.riff = nil;
            self.window.representedURL = nil;
            self.window.title = @"RiffExplorer";
            
            NSURL *fileURL = self.openPanel.URL;
            
            @try {
                self.riff = [[ISLRiffChunk alloc] initWithData:[NSData dataWithContentsOfURL:fileURL]];
                if (self.riff) {
                    self.treeController.childrenKeyPath = @"subChunks";
                    self.treeController.leafKeyPath = @"isLeaf";
                    self.treeController.content = self.riff;
                    self.window.representedURL = fileURL;
                    self.window.title = [fileURL.lastPathComponent stringByAppendingFormat:@" - %@", self.window.title];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"Could not open %@, exception %@", fileURL, exception);
            }
        }
    }];
}

- (void)dealloc
{
    self.openPanel = nil;
    self.treeController.content = nil;
    [self.treeController removeObserver:self forKeyPath:@"selection"];
    
    self.riff = nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    if (tableView == self.table && self.selectedChunk) {
        NSUInteger len = self.selectedChunk.data.length;
        return len/16 + (len%16 ? 1 : 0);
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.table && self.selectedChunk) {
        if ([tableColumn.identifier isEqualToString:@"Address"]) {
            return [NSString stringWithFormat:@"%08lx", rowIndex*16];
        } else if ([tableColumn.identifier isEqualToString:@"HEX"]) {
            NSUInteger len = self.selectedChunk.data.length;
            NSMutableString *result = [NSMutableString new];
            const unsigned char *dataPtr = (const unsigned char*)self.selectedChunk.data.bytes;
            for (NSUInteger offs = rowIndex*16; offs < (rowIndex+1)*16 && offs < len; ++offs) {
                if (result.length && !(offs%4))
                    [result appendString:@" "];
                [result appendFormat:@"%02x",(unsigned int)dataPtr[offs]];
            }
            return [result copy];
        } else if ([tableColumn.identifier isEqualToString:@"Text"]) {
            NSUInteger len = self.selectedChunk.data.length;
            NSMutableString *result = [NSMutableString new];
            const unsigned char *dataPtr = (const unsigned char*)self.selectedChunk.data.bytes;
            for (NSUInteger offs = rowIndex*16; offs < (rowIndex+1)*16 && offs < len; ++offs) {
                if (result.length && !(offs%4))
                    [result appendString:@" "];
                [result appendFormat:@"%c",isprint(dataPtr[offs]) ? dataPtr[offs] : ' '];
            }
            return [result copy];
        }
        
    }
    return nil;
}

@end
