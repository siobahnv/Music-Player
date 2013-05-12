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
// Check marked "Alternating Rows" in IB to get different color rows
@property IBOutlet NSSearchField  *searchField;
@property (weak) IBOutlet NSButton *shuffleButton;
@property (weak) IBOutlet NSTextField *totalSongs;

@property (strong) NSSound *ourBeats;
@property (strong) NSTimer *timer;
@property (strong) NSArray *myMusicArray; // Array of media items
@property (strong) NSArray *searchResults; // Made from myMusicArray, so Array of media items
@property (strong) NSArray *arrayToDisplay; // As above, Array of media items
@property int currentIndex;

@property int searchCategory;

- (IBAction)playButton:(id)sender;
- (IBAction)pauseMusic:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)previousSong:(id)sender;

- (IBAction)updateSearchResults:(id)sender;
- (IBAction)shuffleMusic:(id)sender;

- (IBAction)setSearchCategoryFrom:(NSMenuItem *)sender;
- (void)updateIndicator;

- (void)stopUpdatingIndicator;
- (void)playMusic;
- (void)updateTotalSongsButton;


@end
