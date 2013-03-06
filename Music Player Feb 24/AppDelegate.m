//
//  AppDelegate.m
//  Music Player Feb 24
//
//  Created by Heather Ransome on 2/24/13.
//  Copyright (c) 2013 Heather Ransome. All rights reserved.
//


// TO DO: Fix indicator to reset for multiple songs

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // ------Hrmm
    // Create a File Manager to call the method on 
    //NSFileManager *myManager = [[NSFileManager alloc] init]; // Don't need, class method that gives you a shared one
    // Creat a place to store it
    //NSArray *myArray = [NSArray array];
    // This should search the folder and stash all the paths (of the file names) in the array
    self.myArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Users/heather/Desktop/music" error:nil];
    
    // ------Now what do I want to do?
    // ------Play each song, one at a time
    // ------Eventually: play whatever song is selected
    /*for (int i = 0; i < [myArray count]; i++) {
        // Not sure i want to do this
    }*/

    // Setup NSSound with File
    //self.ourBeats = [[NSSound alloc] initWithContentsOfFile:@"/Users/heather/Desktop/music/01 White Elephant.mp3" byReference:YES];
    //NSString *startOfString = @"/Users/heather/Desktop/music/";
    //int currentIndex = 1;
    //NSString *testString = [startOfString stringByAppendingPathComponent:[self.myArray objectAtIndex:currentIndex]];
    //self.ourBeats = [[NSSound alloc] initWithContentsOfFile:testString byReference:YES];
    self.currentIndex = 1;
    [self setUpSong:self.currentIndex];
    
    // Set delegate for NSSound (declare <NSSoundDelegate> in AppDelegate.h)
    [self.ourBeats setDelegate:self];
    // Now go implement sound:didFinishPlaying:
    
    // Force progress indicator to "determinate"
    [self.indicator setIndeterminate:FALSE];
    
}

- (void)setUpSong:(int)cIndex {
    
    // Setup NSSound with File
    NSString *startOfString = @"/Users/heather/Desktop/music/";
    NSString *testString = [startOfString stringByAppendingPathComponent:[self.myArray objectAtIndex:cIndex]];
    self.ourBeats = [[NSSound alloc] initWithContentsOfFile:testString byReference:YES];
    
}

- (IBAction)playMusic:(id)sender {
    
    // Tell it to play if it's not already
    if (![self.ourBeats resume]) {
        [self.ourBeats play];
    }
    
    // Set up the timer for the progress indicator
    if (!self.timer) {
        
        // Set the max value so syncs with length of individual song
        [self.indicator setMaxValue:[self.ourBeats duration]];
        
        // Set the timer to continually update the progress indicator
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(updateIndicator)
                                                    userInfo:nil
                                                     repeats:YES];
        
    }
    
    // ------Going to need a play next
    // ------if !isPlaying, then play next song
    
    return;
}

- (IBAction)pauseMusic:(id)sender {
    
    [self.ourBeats pause];
    
    // Tell the timer to stfu and go away
    [self.timer invalidate];
    self.timer = nil;
    
    return;
}

- (void)updateIndicator {
    
    // Increment by 1 second since max is set to duration
    // so 1 second is 1% of the song
    [self.indicator incrementBy:1.0];
    
    return;
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
    
    // If YES then song finished, play next song & stop Timer
    // If NO song didn't finish, still need to stop Timer
    
    // Stop timer first
    [self.timer invalidate];
    self.timer = nil;
    
    // Play next song
    if (aBool) {
        [self setUpSong:self.currentIndex + 1];
        [self playMusic:nil];
    }
    
}

@end
