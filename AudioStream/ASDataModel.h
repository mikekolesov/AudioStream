//
//  ASDataModel.h
//  AudioStream
//
//  Created by Michael Kolesov on 9/20/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASDataModel : NSObject <UIAlertViewDelegate>
{
    NSMutableArray* streamObjects;
    int selectedIndex;
    int playingIndex;
    int confirmed;
    
    NSDictionary *selDic;
    NSDictionary *playDic;
}

- (void) addNewEmptyObject;
- (void) makeSelectedObjectPlaying;
- (void) resetPlayingState;
- (BOOL) isSelectedObjectPlaying;
- (void) selectObjectAtIndex: (NSUInteger) index;
- (NSUInteger) countOfObjects;
- (NSString *) valueForKey: (NSString *) keyName atObjectByIndex: (NSUInteger) index;
- (NSUInteger) indexOfPlayingObject;
- (BOOL) removeObjectAtIndex:(NSUInteger)index;


/*
- (NSUInteger) indexOfSelectedObject;
- (void) resetSelectedState;
- (NSDictionary *) objectAtIndex: (NSUInteger) index;
- (void) insertObject:(id)anObject atIndex:(NSUInteger)index;
*/ 
 
@property (strong, nonatomic) NSString * objectTitle;
@property (assign, nonatomic) BOOL resetPlaying;
@property (assign, nonatomic) BOOL startPlaying;


@end
