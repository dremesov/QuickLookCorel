//
//  ISLAppDelegate.h
//  RiffExplorer
//
//  Created by Dmitry Remesov on 21.12.13.
//  Copyright (c) 2013 iSoftLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISLRiffChunk.h"


@interface ISLAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate,NSTableViewDataSource,NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSOutlineView *outline;
@property (weak) IBOutlet NSTreeController *treeController;
@property (weak) IBOutlet NSTableView *table;

@property (strong) ISLRiffChunk *riff;
@property (strong) NSOpenPanel *openPanel;

@property (weak) ISLRiffChunk *selectedChunk;

@end
