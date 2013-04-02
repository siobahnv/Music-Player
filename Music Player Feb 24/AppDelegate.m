//
//  AppDelegate.m
//  Music Player Feb 24
//
//  Created by Heather Ransome on 2/24/13.
//  Copyright (c) 2013 Heather Ransome. All rights reserved.
//

// TO DO: SEARCH
// What does one normally expect a music player to search for?
// Just music folder? All of music on computer?

// ------What to do if it hits end of array?
// ------Options: Nuke Indicator? Loop back to beginning?
// I expect it to stop when reaches end of directory while playing
// but to loop if I hit previous/next buttons

// TO DO (Optional): Shuffle Button (Random)
// TO DO (Optional): Total Count (easy peasy, [array count])


#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // Proper searching of a directory
    // Reference: http://stackoverflow.com/questions/5814463/get-the-type-of-a-file-in-cocoa
    // Alternative: can use NSMetaQuery (ie Spotlight) to search all of computer
    //              instead of just /Music folder
    
    // Use NSHomeDirectory/FileManager/DirectoryEnumerator to get the Music Directory
    // and all subfolders
    NSString *musicDir = [NSHomeDirectory() stringByAppendingPathComponent: @"Music"];
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:musicDir];
    
    // Look through the Directory Enumerator
    // And store what we want in a Mutable Array
    NSString *file;
    NSMutableArray *musicArray = [NSMutableArray array];
    while (file = [dirEnum nextObject]) {
        
        // This is where we need the UTI business
        // so can look for more than just "mp3", should find all audio files
        CFStringRef fileExtension = (__bridge CFStringRef) [file pathExtension];
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
        
        // If it's an audio file, stache it in our array
        if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
            [musicArray addObject:file];
        }
        
        CFRelease(fileUTI);
    }
    
    // Set the array we created to the array in our Delegate
    self.myMusicArray = musicArray;
    self.arrayToDisplay = self.myMusicArray;
    
    // Tell the Table View to reload itself now that we have the Array
    [self.myTable reloadData];
    
    // Turn off multiple selection (can also do this in IB)
    // Also turned off "Editable" for Columns in IBe
    [self.myTable setAllowsMultipleSelection:NO];
    
    // Setup first song
    //self.currentIndex = 0;
    //[self setUpSong:self.currentIndex];
    
    // Connecting the table view
    // setDoubleAction & clickedRow
    //self.currentIndex = [self.myTable clickedRow];
    [self.myTable setDoubleAction:@selector(playButton:)];
    
    // Force progress indicator to "determinate"
    [self.indicator setIndeterminate:FALSE];
        
}

- (void)setUpSong:(int)cIndex {
    
    // Stop current song & the indicator
    // (Shouldn't break if these don't exist)
    [self.ourBeats stop];
    [self stopUpdatingIndicator];
    
    // Set current index (due to play next/previous/continue)
    if (cIndex == [self.arrayToDisplay count]) {
        // We have hit the end & gone beyond, time to go back to zero
        self.currentIndex = 0;
    } else if (cIndex < 0) {
        // We've return to the beginning & gone beyond, time to go to the end
        self.currentIndex = [self.arrayToDisplay count] - 1;
    } else {
        [self setCurrentIndex:cIndex];
    }
    
    // Setup NSSound with File
    NSString *startOfString = [NSHomeDirectory() stringByAppendingPathComponent:  @"Music"];
    NSString *wholeString = [startOfString stringByAppendingPathComponent:[self.arrayToDisplay objectAtIndex:self.currentIndex]];
    self.ourBeats = [[NSSound alloc] initWithContentsOfFile:wholeString byReference:YES];
    
    // Set delegate, needs to be set for each and every new song
    [self.ourBeats setDelegate:self];
    
}

- (void)playMusic {
    
    [self setUpSong:self.currentIndex];
    
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

- (IBAction)playButton:(id)sender { // button implements whether row or first song to play
    
    if ([self.myTable selectedRow] < 0) { // selectedRow returns -1
        self.currentIndex = 0;
    } else {
        self.currentIndex = [self.myTable selectedRow];
    }
    
    [self playMusic];
}

- (IBAction)pauseMusic:(id)sender {
    
    [self.ourBeats pause];
    // Tell the timer to stfu and go away
    [self stopUpdatingIndicator];
    
}

- (IBAction)nextSong:(id)sender {
    
    //[self setUpSong:self.currentIndex + 1];
    self.currentIndex++;
    [self playMusic];
    
}

- (IBAction)previousSong:(id)sender {
    
    //[self setUpSong:self.currentIndex - 1];
    self.currentIndex--;
    [self playMusic];
    
}

- (IBAction)updateSearchResults:(id)sender { // "Searches Immediately" is checkmarked in the Attributes Inspector
        
    NSString *searchString = [self.searchField stringValue]; // Grabbing the input text to search for
    
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        
        // Want the last compenent in the string, rather than the path name
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.lastPathComponent contains[cd] %@", searchString];
        
        // Filter array & update table view
        self.searchResults = [self.myMusicArray filteredArrayUsingPredicate:predicate];
        self.arrayToDisplay = self.searchResults;
        [self.myTable reloadData];
        
    } else { // Do I need an else? Yes
        
        self.arrayToDisplay = self.myMusicArray;
        [self.myTable reloadData];
        
    }
}

- (void)updateIndicator {
    
    // Increment by 1 second since max is set to duration
    // so 1 second is equal to 1% of the song
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
        
    // If YES, Play next song
    // && do not continue to play if at end of array
    if (aBool && (self.currentIndex != ([self.myMusicArray count] - 1))) {
        //[self setUpSong:self.currentIndex + 1];
        self.currentIndex++;
        [self playMusic];
    }
    
    // Hide the bar when done playing
    if (aBool && (self.currentIndex == ([self.myMusicArray count] - 1))) {
        [self.indicator setHidden:YES];
    }
    
    if (!aBool) {
        // Stop timer 
        [self stopUpdatingIndicator];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    NSInteger count = 0;
    
    if (self.arrayToDisplay) {
        count = [self.arrayToDisplay count];
    }
    
    return count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    id returnValue = nil;
    NSString *theName = [self.arrayToDisplay objectAtIndex:row];
    returnValue = [theName lastPathComponent];
    
    return returnValue;
}

@end
