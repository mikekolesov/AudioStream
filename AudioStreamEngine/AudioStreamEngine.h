//
//  AudioStreamEngine.h
//  AudioStream
//
//  Copyright (c) 2012-2015 Michael Kolesov. All rights reserved.
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
