//
//  ASDataModel.h
//  AudioStream
//
//  Created by Michael Kolesov on 9/20/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASDataModel : NSObject
{
    NSMutableArray* streamObjects;
    NSDictionary *selDic;
    NSDictionary *playDic;
}

- (NSUInteger) indexOfSelectedObject;
- (void) selectObjectAtIndex: (NSUInteger) index;
- (void) resetSelectedState;
- (BOOL) isSelectedObjectPlaying;
- (void) makeSelectedObjectPlaying;
- (void) resetPlayingState;
- (NSUInteger) indexOfPlayingObject;
- (NSDictionary *) objectAtIndex: (NSUInteger) index;
- (NSUInteger) countOfObjects;
- (void) insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void) removeObjectAtIndex:(NSUInteger)index;
- (NSString *) valueForKey: (NSString *) keyName atObjectByIndex: (NSUInteger) index;
- (void) addNewEmptyObject;

@property (strong, nonatomic) NSString * objectTitle;
@property (assign, nonatomic) BOOL resetPlaying;

@end
