//
//  ASStreamThread.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol ASStreamThreadDelegate <NSObject>

@optional
-(void) streamThreadDidStartPlaying;
-(void) streamThreadDidCancel;
-(void) streamThreadDidUpdateTitle:(NSString*)title;
@end



@interface ASStreamThread : NSObject

- (void) setupStream;
- (void) startWithURL: (NSString *) url;
- (void) stop;

@property (assign, nonatomic) BOOL preparing;
@property (assign, nonatomic) BOOL playing;
@property (assign, nonatomic) BOOL finishing;
@property (copy, nonatomic) NSString *streamTitle;
@property (copy, nonatomic) NSString *urlString;
@property (assign, nonatomic) BOOL allowMixing;
@property (copy, nonatomic) NSString *contentType;
@property (copy, nonatomic) NSString *bitRate;
@property (strong, nonatomic) NSString *icyMetaInt;

@property (nonatomic, weak) id <ASStreamThreadDelegate> delegate;

@end
