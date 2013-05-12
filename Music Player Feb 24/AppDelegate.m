//
//  AppDelegate.m
//  Music Player Feb 24
//
//  Created by Heather Ransome on 2/24/13.
//  Copyright (c) 2013 Heather Ransome. All rights reserved.
//

// Simple Music Player using NSString
// Switching to NSURL to ITMediaItem
// so can implement Albums & Sorting and AV crap

// Potentially create a separate Music class
// TO DO (Optional): There are probably duplicates in the array of songs, could try handling that? Fixed?
// TO DO (Optional): Playlists?
// ****TO DO: Sort? Sort by Album? by Rating?****
// ****TO DO: Fix Search *****

// Useful later:
// mediaItem.contentRating
// mediaItem.description
// mediaItem.genre

// TO DO: fix search (what do I want it to search anyways?)
// TO DO: add sort, thinking those column arrow thingies?


#import "AppDelegate.h"
#import <iTunesLibrary/ITLibrary.h>
#import <iTunesLibrary/ITLibMediaItem.h>
#import <iTunesLibrary/ITLibAlbum.h>
#import <iTunesLibrary/ITLibArtist.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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
                
                // Reference: http://stackoverflow.com/questions/5814463/get-the-type-of-a-file-in-cocoa
                CFStringRef fileExtension = (__bridge CFStringRef) [mediaItem.location pathExtension];
                CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
                
                // If it's an audio file, stache it in our array
                if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
                    [musicArray addObject:mediaItem]; // Around 265 items
                }
                
                CFRelease(fileUTI);

            }
            
            // Store and display the array
            self.myMusicArray = musicArray;
            self.arrayToDisplay = self.myMusicArray;
            
        }
    
    }
    
    // Tell the Table View to reload itself now that we have the Array
    [self.myTable reloadData];
    // Also tell the Text Field Label to update itself
    [self updateTotalSongsButton];
    
    // Turn off multiple selection (can also do this in IB)
    // Also turned off "Editable" for Columns in IB
    [self.myTable setAllowsMultipleSelection:NO];
    
    // Connecting the table view
    [self.myTable setDoubleAction:@selector(playButton:)];
    
    // Force progress indicator to "determinate"
    [self.indicator setIndeterminate:FALSE];
    
    // Set default search to Title which is tagged with "1"
    //[self setSearchCategory:1];
        
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
    ITLibMediaItem *mediaItem = [self.arrayToDisplay objectAtIndex:self.currentIndex];
    NSURL *mediaURL = mediaItem.location; // location should give us a NSURL
    // Continuation of HACKS! since mediaItem.location is returning nil, we're going to search for the property
    if (!mediaURL) {
        mediaURL = [mediaItem valueForProperty:@"Location"]; // but if it doesn't, fall back to querying the property directly
    }
    self.ourBeats = [[NSSound alloc] initWithContentsOfURL:mediaURL byReference:YES];
    
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

- (IBAction)setSearchCategoryFrom:(NSMenuItem *)sender {
    self.searchCategory = [sender tag];
    [[self.searchField cell] setPlaceholderString:[sender title]];
    
}

- (IBAction)updateSearchResults:(id)sender { // "Searches Immediately" is checkmarked in the Attributes Inspector
    
    // TO DO: Man I don't even want to touch this section...
    // fix for array of media items instead of array of nsstrings
    // fix for multiple columns in table view
    
    NSString *searchString = [self.searchField stringValue]; // Grabbing the input text to search for
    NSPredicate *predicate;
    
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        
        // Want the last component in the string, rather than the path name
        // NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.lastPathComponent contains[cd] %@", searchString];
        // NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.location.lastPathComponent contains[cd] %@", searchString];
        
        // Filter array & update table view
        // self.searchResults = [self.myMusicArray filteredArrayUsingPredicate:predicate];
        // self.arrayToDisplay = self.searchResults;
        
        /*if (self.searchCategory == 1) { // 1 should be Title
            predicate = [NSPredicate predicateWithFormat:@"SELF.title contains[cd] %@", searchString];
            // Filter array & update table view
            self.searchResults = [self.myMusicArray filteredArrayUsingPredicate:predicate];
            self.arrayToDisplay = self.searchResults;
        }*/
        
        // NSString *itemString;
        
        switch (self.searchCategory) {
            case 1: // Title Menu Item
                // itemString = @"title";
                predicate = [NSPredicate predicateWithFormat:@"SELF.title contains[cd] %@", searchString];
                break;
            case 2: // Album Menu Item
                // itemString = @"album.title";
                predicate = [NSPredicate predicateWithFormat:@"SELF.album.title contains[cd] %@", searchString];
                break;
            case 3: // Artist Menu Item
                // itemString = @"artist.name";
                predicate = [NSPredicate predicateWithFormat:@"SELF.artist.name contains[cd] %@", searchString];
                break;
            case 0: // All Menu Item
            default:
                // NSLog(@"Oops, defaulted. Please select a Menu Item to search.");
                predicate = [NSPredicate predicateWithFormat:@"(SELF.title contains[cd] %@) OR (SELF.album.title contains[cd] %@) OR (SELF.artist.name contains[cd] %@)", searchString, searchString, searchString];
                
                // NSArray *argArray = [NSArray arrayWithObjects:@"SELF.title", @"SELF.album.title", @"SELF.artist.name", nil];
                // predicate = [NSPredicate predicateWithFormat:<#(NSString *)#> argumentArray:<#(NSArray *)#>]
                break;
        }
        
        // predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"SELF.%@ contains[cd] %%@", itemString], searchString];
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
    
    ITLibMediaItem *mediaItem = [self.arrayToDisplay objectAtIndex:row]; // Stash your media item in a media item
    id value = nil;
    
    if ([[tableColumn identifier] isEqualToString:@"Title"]) {
        value = mediaItem.title;
    } else if ([[tableColumn identifier] isEqualToString:@"Album"]) {
        if (mediaItem.album.title) {
            value = mediaItem.album.title;
        }
    } else if ([[tableColumn identifier] isEqualToString:@"Artist"]) {
        if (mediaItem.artist.name) {
            value = mediaItem.artist.name;
        }
    }
    
    return value;
    
}

@end
