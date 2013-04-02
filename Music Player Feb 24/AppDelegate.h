//
//  AppDelegate.h
//  Music Player Feb 24
//
//  Created by Heather Ransome on 2/24/13.
//  Copyright (c) 2013 Heather Ransome. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSSoundDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSTableView *myTable;
@property IBOutlet NSSearchField  *searchField;

@property (strong) NSSound *ourBeats;
@property (strong) NSTimer *timer;
@property (strong) NSArray *myMusicArray;
@property (strong) NSArray *searchResults;
@property (strong) NSArray *arrayToDisplay;
@property int currentIndex;

- (IBAction)playButton:(id)sender;
- (IBAction)pauseMusic:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)previousSong:(id)sender;
- (IBAction)updateSearchResults:(id)sender;

- (void)updateIndicator;
- (void)stopUpdatingIndicator;
- (void)playMusic;


@end
