//
//  ASDataModel.m
//  AudioStream
//
//  Created by Michael Kolesov on 9/20/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASDataModel.h"

@interface ASDataModel () <UIAlertViewDelegate>

@end

@implementation ASDataModel

@synthesize objectTitle;
@synthesize resetPlaying;
@synthesize startPlaying;
@synthesize isModified;

-(id) init
{
    self = [super init];
    if (self != nil) {
        selectedIndex = -1;
        playingIndex = -1;
        isModified = NO;
        
        // setup path for settings file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths objectAtIndex:0];
        filePath = [NSString stringWithFormat:@"%@/AudioStreamList.plist", docDir];
        
        NSError *err = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:filePath]) {
            // copy presets file from bundle
            NSString *filePathInBundle = [[NSBundle mainBundle] pathForResource:@"AudioStreamList.plist" ofType:nil];
            [fileManager copyItemAtPath:filePathInBundle toPath:filePath error:&err];
        }
        
        streamObjects = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    
    }
    return self;
}

- (void) dealloc
{
    [streamObjects removeAllObjects];
}

- (NSString *) description
{
    NSString *desc = [NSString stringWithFormat:@"Object count %lu\n%@",
                      (unsigned long)streamObjects.count,
                      streamObjects.description];
    return desc;
}


- (void) addNewEmptyObject
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:@"New Stream" forKey:@"StreamName"];
    [dic setValue:@"http://" forKey:@"StreamURL"];
        
    // insert always to top (at index 0)
    [streamObjects insertObject:dic atIndex:0];
    
    // save into the file
    [streamObjects writeToFile:filePath atomically:YES];
    
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
    selectedIndex = (int)index;
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

- (void) setValue: (NSString *) newValue forKey: (NSString *) keyName atObjectByIndex: (NSUInteger) index
{
    NSMutableDictionary *mdic = [streamObjects objectAtIndex:index];
    [mdic setValue:newValue forKey:keyName];
    
    // save into the file
    [streamObjects writeToFile:filePath atomically:YES];
}


- (int) indexOfPlayingObject
{
    return playingIndex;
}


- (BOOL) removeObjectAtIndex:(NSUInteger)index
{
    // trying delete object which is playing now
    if (playingIndex == index) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Operation Not Permited" message:@"Stop this stream\n before delete it" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
        alert.tag = 1;
        [alert show];
        
        return NO;
    }
    
    // delete confirmation alert
    confirmed = -1;
    
    NSString *name = [self valueForKey:@"StreamName" atObjectByIndex:index];
    NSString *mes = [NSString stringWithFormat:@"Are you sure to delete\n \"%@\" stream?", name];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete confirmation" message:mes delegate:self cancelButtonTitle:@"Yes" otherButtonTitles: @"No", nil];
    alert.tag = 2;
    [alert show];
    
    // wait for confirm (0 or 1)
    while (confirmed == -1) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    
    if (confirmed) {
        [streamObjects removeObjectAtIndex:index];
        
        // save into the file
        [streamObjects writeToFile:filePath atomically:YES];
        
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

- (int) indexOfSelectedObject
{
    return selectedIndex;
}



/*

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

#pragma mark - ASStreamThread delegate

-(void) audioStreamEngineDidStartPlaying
{
    [self makeSelectedObjectPlaying];
}


-(void) audioStreamEngineDidUpdateTitle:(NSString *)title
{
    // invokes key-value observing
    self.objectTitle = title;
    NSLog(@"Updated to title: %@", self.objectTitle);
}

-(void) audioStreamEngineDidCancel
{
    [self resetPlayingState];
}

-(void) audioStreamEngineErrorOccured:(NSString *)title withMessage:(NSString *)msg
{
    //TODO: move UIAlertView calls from data model later
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alert.tag = 3;
        [alert show];
        
    });
}

@end



