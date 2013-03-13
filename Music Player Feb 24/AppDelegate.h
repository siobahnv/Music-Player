//
//  AppDelegate.h
//  Music Player Feb 24
//
//  Created by Heather Ransome on 2/24/13.
//  Copyright (c) 2013 Heather Ransome. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSSoundDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) NSSound *ourBeats;
@property (strong) IBOutlet NSProgressIndicator *indicator;
@property (strong) NSTimer *timer;
@property (strong) NSArray *myMusicArray;
@property int currentIndex;

- (IBAction)playMusic:(id)sender;
- (IBAction)pauseMusic:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)previousSong:(id)sender;

- (void)updateIndicator;
- (void)stopUpdatingIndicator;


@end
