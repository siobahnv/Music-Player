//
//  AppDelegate.m
//  Music Player Feb 24
//
//  Created by Heather Ransome on 2/24/13.
//  Copyright (c) 2013 Heather Ransome. All rights reserved.
//

// Simple Music Player using NSString
// Switching to NSURL?
// so can implement Albums & Sorting and AV crap

// ------What to do if it hits end of array?
// ------Options: Nuke Indicator? Loop back to beginning?
// I expect it to stop when reaches end of directory while playing
// but to loop if I hit previous/next buttons (did not implement this,
// pretty sure it just loops and never stops)

// Potentially create a separate Music class
// TO DO (Optional): There are probably duplicates in the array of songs, could try handling that?
// TO DO (Optional): Playlists?
// TO DO (Optional): Sort? Sort by Album? by Rating?

// Useful things:
// mediaItem.title
// mediaItem.sortTitle
// mediaItem.album
// mediaItem.artist

// Useful later:
// mediaItem.contentRating
// mediaItem.description
// mediaItem.genre

// Alternative path to allmediaitems:
// NSArray *playlists = library.allPlaylists; //  <- NSArray of ITLibPlaylist // This returns 18 objects
//
// items (playlists.items)
// The media items (tracks) in this playlist. (read-only)
//
// @property (readonly, nonatomic, retain) NSArray* items;



#import "AppDelegate.h"
#import <iTunesLibrary/ITLibrary.h>
#import <iTunesLibrary/ITLibMediaItem.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // ------------------------------------------------------------------------------------------
    // What does one normally expect a music player to search for?
    // Just music folder? All of music on computer?
    // I have it searching for all music in the "Music" directory
    // ------------------------------------------------------------------------------------------
    
    /*// Proper searching of a directory
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
    
    // Store and display the array we created
    self.myMusicArray = musicArray;
    self.arrayToDisplay = self.myMusicArray; */
    // ------------------------------------------------------------------------------------------
    
    // #1: Added iTunes library framework, need to use Shift+Cmd+G to find
    // Went to Project in the left bar > Targets > Build Phases > Link Binary with Libraries > + > Add Other > Shift+Cmd+G > /Library/Frameworks > iTunesLibrary.frameworks
    // #2: But that was not enough, needed to do this as well for it to Build
    // Build Settings > search for "Framework Search Paths" > doubleclick on the empty row, hit plus, and add /Library/Frameworks/
    // #3: Also need to be code signed (used Zach's team membership & set to Mac Developer)
    
    NSError *error = nil;
    ITLibrary *library = [ITLibrary libraryWithAPIVersion:@"1.0" error:&error];
    // ISSUE: Code-signing, "ad hoc" option not showing
    
    if (library) {
        
        NSArray *tracks = library.allMediaItems; //  <- NSArray of ITLibMediaItem // This returns 361 objects
        NSMutableArray *musicArray = [NSMutableArray array];
        
        if (tracks.count > 0) {
            
            for (int i = 0; i < tracks.count; i++) {
                
                ITLibMediaItem *mediaItem = (ITLibMediaItem*)[tracks objectAtIndex:i];
                
                // if (mediaItem.mediaKind == ITLibMediaItemMediaKindSong) { // Returning kind "Unknown" for known music files
                //     [musicArray addObject:mediaItem.location]; // Array of NSURLs
                //     NSLog(@"%@", mediaItem.title);
                // }
                
                // This is where we need the UTI business
                // so can look for more than just "mp3", should find all audio files
                // NSString *file; // But we have URLs, not NSStrings
                // CFStringRef fileExtension = (__bridge CFStringRef) [file pathExtension];
                CFStringRef fileExtension = (__bridge CFStringRef) [mediaItem.location pathExtension];
                CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
                
                // If it's an audio file, stache it in our array
                if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
                    [musicArray addObject:mediaItem.location]; // Arrays of NSURLs
                }
                
                CFRelease(fileUTI);

            }
            
            // Store and display the array
            // self.myMusicArray = tracks;
            self.myMusicArray = musicArray;
            self.arrayToDisplay = self.myMusicArray;
            
        }
        
        /*if (tracks.count > 0) {
            
            // Get the location (URL) of the first media item and prepare it for file read/write access.
            ITLibMediaItem *mediaItem = (ITLibMediaItem*)[tracks objectAtIndex:0];
            NSLog(@"%@", mediaItem);
         
        }*/
    }

    
    // Tell the Table View to reload itself now that we have the Array
    [self.myTable reloadData];
    // Also tell the Text Field Label to update itself
    [self updateTotalSongsButton];
    
    // Turn off multiple selection (can also do this in IB)
    // Also turned off "Editable" for Columns in IB
    [self.myTable setAllowsMultipleSelection:NO];
    
    // Hide the Header in Table View (not necessary for such a Simple table)
    [self.myTable setHeaderView:nil];
    
    // Connecting the table view
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
    // NSString *startOfString = [NSHomeDirectory() stringByAppendingPathComponent:  @"Music"];
    // NSString *wholeString = [startOfString stringByAppendingPathComponent:[self.arrayToDisplay objectAtIndex:self.currentIndex]];
    // self.ourBeats = [[NSSound alloc] initWithContentsOfFile:wholeString byReference:YES];
    self.ourBeats = [[NSSound alloc] initWithContentsOfURL:[self.arrayToDisplay objectAtIndex:self.currentIndex] byReference:YES];
    // NEED TO DO WORK HERE!!! I think it works?
    
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

- (IBAction)playButton:(id)sender { // button implements whether row or first song is to play
    
    if ([self.myTable selectedRow] < 0) { // selectedRow returns -1
        self.currentIndex = 0;
    } else {
        self.currentIndex = [self.myTable selectedRow];
    }
    
    [self playMusic];
}

- (IBAction)pauseMusic:(id)sender {
    
    [self.ourBeats pause];
    [self stopUpdatingIndicator]; // Tell the timer to stfu and go away
    
}

- (IBAction)nextSong:(id)sender {
    
    self.currentIndex++;
    [self playMusic];
    
}

- (IBAction)previousSong:(id)sender {
    
    self.currentIndex--;
    [self playMusic];
    
}

- (IBAction)updateSearchResults:(id)sender { // "Searches Immediately" is checkmarked in the Attributes Inspector
        
    NSString *searchString = [self.searchField stringValue]; // Grabbing the input text to search for
    
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        
        // Want the last component in the string, rather than the path name
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.lastPathComponent contains[cd] %@", searchString];
        
        // Filter array & update table view
        self.searchResults = [self.myMusicArray filteredArrayUsingPredicate:predicate];
        self.arrayToDisplay = self.searchResults;
        
    } else { // Do I need an else? Yes, resets the table 
        
        self.arrayToDisplay = self.myMusicArray;
        
    }
    
    [self.myTable reloadData];
    [self updateTotalSongsButton];
    
}

- (IBAction)shuffleMusic:(id)sender {
    
    // Set Button to "Push On Push Off" in IB
    if ([self.shuffleButton state]) {
        self.currentIndex = arc4random_uniform(self.arrayToDisplay.count);
    }
}

- (void)updateIndicator {
    
    // Increment by 1 sec since max is set to duration so 1 sec is equal to 1% of the song
    [self.indicator incrementBy:1.0];
    
}

- (void)stopUpdatingIndicator {
    
    // Stop and nuke timer
    [self.timer invalidate];
    self.timer = nil;
    
}

- (void)updateTotalSongsButton {
    
    //self.totalSongs = [NSString stringWithFormat:@"%li", (unsigned long)self.arrayToDisplay.count];
    
    [self.totalSongs setStringValue: [NSString stringWithFormat:@"%li", (unsigned long)self.arrayToDisplay.count]];
    
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
    
    // ------------------------------------------------------------------------------------------
    // Logic:
    // If YES then song finished, stop Timer & play next song
    // If NO song didn't finish, still need to stop Timer
    // ------------------------------------------------------------------------------------------
        
    // If YES, Play next song && do not continue to play if at end of array
    if (aBool && (self.currentIndex != ([self.myMusicArray count] - 1))) {
        self.currentIndex++;
        [self playMusic];
    }
    
    // Hide the bar when done playing
    if (aBool && (self.currentIndex == ([self.myMusicArray count] - 1))) {
        [self.indicator setHidden:YES];
    }
    
    if (!aBool) { // If NO, Stop timer 
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
    returnValue = [theName lastPathComponent]; // Should I replace with mediaItem.title?
    
    return returnValue;
}

@end
