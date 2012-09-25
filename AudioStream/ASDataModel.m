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

-(id) init
{
    self = [super init];
    if (self != nil) {
        streamObjects = [[NSMutableArray alloc] init];
        selDic = nil;
        playDic = nil;
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

- (NSUInteger) indexOfSelectedObject
{
    return [streamObjects indexOfObject:selDic];
}

- (void) selectObjectAtIndex: (NSUInteger)index
{
    selDic = [streamObjects objectAtIndex:index];
}

- (void) resetSelectedState
{
    selDic = nil;
}

- (void) makeSelectedObjectPlaying
{
    playDic = selDic;
}

- (void) resetPlayingState
{
    playDic = nil;
    
    if ([NSThread isMainThread]) {
        self.resetPlaying = YES;
    }
    else
        [self performSelectorOnMainThread:@selector(updateResetPlaying) withObject:nil waitUntilDone:NO];
}

- (void) updateResetPlaying
{
    self.resetPlaying = YES;
}

- (BOOL) isSelectedObjectPlaying
{
    return (selDic == playDic);
}

- (NSUInteger) indexOfPlayingObject
{
    return [streamObjects indexOfObject:playDic];
}

-(NSDictionary *) objectAtIndex: (NSUInteger) index
{
    return [streamObjects objectAtIndex:index];
}

- (NSUInteger) countOfObjects
{
    return streamObjects.count;
}

- (void) insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [streamObjects insertObject:anObject atIndex:index];
}

- (void) removeObjectAtIndex:(NSUInteger)index
{
    [streamObjects removeObjectAtIndex:index];
}

- (NSString *) valueForKey: (NSString *) keyName atObjectByIndex: (NSUInteger) index
{
    NSDictionary *dic = [streamObjects objectAtIndex:index];
    return [dic objectForKey:keyName];
}

- (void) addNewEmptyObject
{
    NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
    [dic setValue:@"New Stream" forKey:@"StreamName"];
    [dic setValue:@"" forKey:@"StreamURL"];

    [streamObjects addObject:dic];
    
    // make new empty object selected by default
    selDic = dic;
}

@end



