//
//  ASDataModel.m
//  AudioStream
//
//  Created by Michael Kolesov on 9/20/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASDataModel.h"

@implementation ASDataModel

@synthesize objectTitle;
@synthesize resetPlaying;
@synthesize startPlaying;

-(id) init
{
    self = [super init];
    if (self != nil) {
        streamObjects = [[NSMutableArray alloc] init];
        selectedIndex = -1;
        playingIndex = -1;
    }
    return self;
}

- (void) dealloc
{
    [streamObjects removeAllObjects];
    [streamObjects release];
    [super dealloc];
}

- (NSString *) description
{
    NSString *desc = [NSString stringWithFormat:@"Object count %d\n%@",
                      streamObjects.count,
                      streamObjects.description];
    return desc;
}


- (void) addNewEmptyObject
{
    NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
    [dic setValue:@"New Stream" forKey:@"StreamName"];
    [dic setValue:@"http://192.168.1.5:8002/listen" forKey:@"StreamURL"];
        
    // insert always to top (at index 0)
    [streamObjects insertObject:dic atIndex:0];
    
    // make new empty object selected by default
    selectedIndex = 0;
    if (playingIndex != -1) {
        playingIndex++; // shift playing index if currently playing
    }
    
}


- (void) makeSelectedObjectPlaying
{
    playingIndex = selectedIndex; // set befor KVO method invoked
    
    if ([NSThread isMainThread])
        self.startPlaying = YES;
    else
        [self performSelectorOnMainThread:@selector(updateStartPlaying) withObject:nil waitUntilDone:NO];
}

- (void) updateStartPlaying
{
    self.startPlaying = YES;
}


- (void) resetPlayingState
{    
    if ([NSThread isMainThread]) {
        self.resetPlaying = YES;
        playingIndex = -1; // reset only after KVO method invoked
    }
    else
        [self performSelectorOnMainThread:@selector(updateResetPlaying) withObject:nil waitUntilDone:NO];
}

- (void) updateResetPlaying
{
    self.resetPlaying = YES;
    playingIndex = -1; // reset only after KVO method invoked
}

- (BOOL) isSelectedObjectPlaying
{
    if (selectedIndex == playingIndex)
        return YES;
    else
        return NO;
}

- (void) selectObjectAtIndex: (NSUInteger)index
{
    selectedIndex = index;
}

- (NSUInteger) countOfObjects
{
    return streamObjects.count;
}

- (NSString *) valueForKey: (NSString *) keyName atObjectByIndex: (NSUInteger) index
{
    NSDictionary *dic = [streamObjects objectAtIndex:index];
    NSString *str = [dic objectForKey:keyName];
    
    return str;
}

- (NSUInteger) indexOfPlayingObject
{
    return playingIndex;
}


- (BOOL) removeObjectAtIndex:(NSUInteger)index
{
    // trying delete object which is playing now
    if (playingIndex == index) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Operation not permited" message:@"You have to stop the stream\n before delete it" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
        alert.tag = 1;
        [alert show];
        [alert release];
        
        return NO;
    }
    
    // delete confirmation alert
    confirmed = -1;
    
    NSString *name = [self valueForKey:@"StreamName" atObjectByIndex:index];
    NSString *mes = [NSString stringWithFormat:@"Are you sure to delete\n \"%@\" stream?", name];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete confirmation" message:mes delegate:self cancelButtonTitle:@"Yes" otherButtonTitles: @"No", nil];
    alert.tag = 2;
    [alert show];
    [alert release];
    
    // wait for confirm (0 or 1)
    while (confirmed == -1) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    
    if (confirmed) {
        [streamObjects removeObjectAtIndex:index];
        
        if (playingIndex > (int)index)
            playingIndex--; // shift playing index 
        if (selectedIndex > (int)index)
            selectedIndex = -1; // reset last selected object
        
        return YES;
    }
    else
        return NO;
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 1:
            // skip for now
            break;
        case 2:
            if (buttonIndex == 0) // delete confirmed
                confirmed = 1;
            else                  // dismiss
                confirmed = 0;
            break;
        default:
            break;
    }
}



/*
- (NSUInteger) indexOfSelectedObject
{
    return [streamObjects indexOfObject:selDic];
}


- (void) resetSelectedState
{
    selDic = nil;
}


-(NSDictionary *) objectAtIndex: (NSUInteger) index
{
    return [streamObjects objectAtIndex:index];
}



- (void) insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [streamObjects insertObject:anObject atIndex:index];
}


*/

@end



