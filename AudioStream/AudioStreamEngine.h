//
//  ASStreamThread.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol AudioStreamEngineDelegate <NSObject>

@optional
-(void) audioStreamEngineDidStartPlaying;
-(void) audioStreamEngineDidCancel;
-(void) audioStreamEngineDidUpdateTitle:(NSString*)title;
-(void) audioStreamEngineErrorOccured:(NSString*)title withMessage: (NSString*)msg;
@end



@interface AudioStreamEngine : NSObject

+ (AudioStreamEngine*) sharedInstance;

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

@property (nonatomic, weak) id <AudioStreamEngineDelegate> delegate;

@end
