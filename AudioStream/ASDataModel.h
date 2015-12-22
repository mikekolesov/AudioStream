//
//  ASDataModel.h
//  AudioStream
//
//  Created by Michael Kolesov on 9/20/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASStreamThread.h"

@interface ASDataModel : NSObject <ASStreamThreadDelegate>
{
    NSMutableArray* streamObjects;
    int selectedIndex;
    int playingIndex;
    int confirmed;
    NSString *filePath;
}

- (void) addNewEmptyObject;
- (void) makeSelectedObjectPlaying;
- (void) resetPlayingState;
- (BOOL) isSelectedObjectPlaying;
- (void) selectObjectAtIndex: (NSUInteger) index;
- (NSUInteger) countOfObjects;
- (NSString *) valueForKey: (NSString *) keyName atObjectByIndex: (NSUInteger) index;
- (void) setValue: (NSString *) newValue forKey: (NSString *) keyName atObjectByIndex: (NSUInteger) index;
- (int) indexOfPlayingObject;
- (BOOL) removeObjectAtIndex:(NSUInteger)index;
- (int) indexOfSelectedObject;

/*
- (NSUInteger) indexOfSelectedObject;
- (void) resetSelectedState;
- (NSDictionary *) objectAtIndex: (NSUInteger) index;
- (void) insertObject:(id)anObject atIndex:(NSUInteger)index;
*/ 
 
@property (strong, nonatomic) NSString * objectTitle;
@property (assign, nonatomic) BOOL resetPlaying;
@property (assign, nonatomic) BOOL startPlaying;
@property (assign, nonatomic) BOOL isModified;

@end
