//
//  AppDelegate.m
//  Music Player Feb 24
//
//  Created by Heather Ransome on 2/24/13.
//  Copyright (c) 2013 Heather Ransome. All rights reserved.
//

// TO DO: TABLE VIEW
// TO DO: SEARCH

// ------What to do if it hits end of array?
// ------Options: Nuke Indicator? Loop back to beginning?

// ------Caution: bools for checking end and beginning of array
// ------for nextSong and previousSong

// What does one normally expect a music player to search for?
// Just music folder? All of music on computer?
// I expect it to stop when reaches end of directory while playing
// but to loop if I hit previous/next buttons

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // Proper searching of a directory
    // Reference: http://stackoverflow.com/questions/5814463/get-the-type-of-a-file-in-cocoa
    // Alternative: can use NSMetaQuery (ie Spotlight) to search all of computer
    //              instead of just /Music folder
    
    // Use NSHomeDirectory to get the Music Directory
    NSString *musicDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Music"];
    // Create a File Manager
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    // Create a Directory Enumerator using the above
    NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:musicDir];
    
    // Look through the Directory Enumerator
    // And store what we want in a Mutable Array
    NSString *file;
    NSMutableArray *musicArray = [NSMutableArray array];
    while (file = [dirEnum nextObject]) {
        
        // This is where we need the UTI business
        // so can look for more than just "mp3", all audio files
        CFStringRef fileExtension = (__bridge CFStringRef) [file pathExtension];
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
        
        // If it's an audio file, stache it in our array
        if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
            [musicArray addObject:file];
        }
        
        CFRelease(fileUTI);
    }
        
    // This should search the folder and stash all the paths (of the file names) in the array
    //self.myArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Users/heather/Desktop/music" error:nil];
    self.myArray = musicArray;
    
    // Setup first song
    self.currentIndex = 0;
    [self setUpSong:self.currentIndex];
    
    // Set delegate for NSSound (declare <NSSoundDelegate> in AppDelegate.h)
    //[self.ourBeats setDelegate:self]; // This is duplicate (setUpSong does this now)
    // Now go implement sound:didFinishPlaying:
    
    // Force progress indicator to "determinate"
    [self.indicator setIndeterminate:FALSE];
    
}

- (void)setUpSong:(int)cIndex {
    
    // Set current index (due to play next/previous/continue)
    // Check for Ends
    if (cIndex == [self.myArray count]) {
        // We have hit the end, time to go back to zero
        self.currentIndex = 0;
    } else if (cIndex < 0) {
        // We've return to the beginning, time to go to the end
        self.currentIndex = [self.myArray count] - 1;
    } else {
        [self setCurrentIndex:cIndex];
    }
    
    // Setup NSSound with File
    // NSString *startOfString = @"/Users/heather/Desktop/music/";
    NSString *startOfString = [NSHomeDirectory() stringByAppendingPathComponent:  @"Music"];
    NSString *wholeString = [startOfString stringByAppendingPathComponent:[self.myArray objectAtIndex:self.currentIndex]];
    self.ourBeats = [[NSSound alloc] initWithContentsOfFile:wholeString byReference:YES];
    
    // Set delegate, needs to be set for each new song
    [self.ourBeats setDelegate:self];
    
}

- (IBAction)playMusic:(id)sender {
    
    // Tell it to play if it hasn't already been told
    if (![self.ourBeats resume]) {
        [self.ourBeats play];
    }
    
    // Set up the timer for the progress indicator
    if (!self.timer) {
        
        // Set the max value so syncs with length of individual song
        [self.indicator setMaxValue:[self.ourBeats duration]];
        
        // RESET current value (for when moves onto next song)
        [self.indicator setDoubleValue:0];
        
        // Set the timer to continually update the progress indicator
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(updateIndicator)
                                                    userInfo:nil
                                                     repeats:YES];
        
    }
    
    return;
}

- (IBAction)pauseMusic:(id)sender {
    
    [self.ourBeats pause];
    
    // Tell the timer to stfu and go away
    [self stopUpdatingIndicator];
    
    return;
}

- (IBAction)nextSong:(id)sender {
    
    // Stop current song & the indicator
    [self.ourBeats stop];
    [self stopUpdatingIndicator];
    
    // Play next song (if not last object)
    [self setUpSong:self.currentIndex + 1];
    [self playMusic:nil];
    
    /*if (self.currentIndex != ([self.myArray count] - 1)) { // NEED TO FIX
        [self setUpSong:self.currentIndex + 1];
        [self playMusic:nil];
    }*/
    
}

- (IBAction)previousSong:(id)sender {
    
    // Stop current song & the indicator
    [self.ourBeats stop];
    [self stopUpdatingIndicator];
    
    // Play next song (if not last object)
    [self setUpSong:self.currentIndex - 1];
    [self playMusic:nil];
    
    /*if (self.currentIndex != 0) {
        [self setUpSong:self.currentIndex - 1];
        [self playMusic:nil];
    }*/
    
}

- (void)updateIndicator {
    
    // Increment by 1 second since max is set to duration
    // so 1 second is 1% of the song
    [self.indicator incrementBy:1.0];
    
    return;
}

- (void)stopUpdatingIndicator {
    
    // Stop and nuke timer
    [self.timer invalidate];
    self.timer = nil;
    
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
    
    // Logic:
    // If YES then song finished, stop Timer & play next song
    // If NO song didn't finish, still need to stop Timer
    
    // Stop timer first
    [self stopUpdatingIndicator];
    
    // Play next song
    
    // not last object
    // && (self.currentIndex != ([self.myArray count] - 1))
    if (aBool) { // if YES
        [self setUpSong:self.currentIndex + 1];
        [self playMusic:nil]; // nil because IBAction
    }
    
    // Hide the bar when done playing
    if (aBool && (self.currentIndex == ([self.myArray count] - 1))) {
        [self.indicator setHidden:YES];
    }
}

@end
