//
//  ASStreamThread.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ASDataModel.h"

@interface ASStreamThread : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSThread *thread;           // stream thread object
    BOOL releaseThread;         // release thread if error occured before

    CFRunLoopRef runLoop;       // secondary thread run loop
    
    NSURLConnection *conn;      // stream connection
    NSString *urlString;        // stream url string
    
    BOOL preparing;             // start/stop preparing flag
    BOOL finishing;             // flag to finish audio processing
    BOOL callbackFinished;       // exit of connection callback
    
    BOOL playing;
    
    BOOL checkIfShoutcast;      // check if server is SHOUTcast
    BOOL textHtml;              // text instead of audio in response
    
    NSString *contentType;      // http-style type of stream
    NSString *bitRate;          // icy-br NSString value
    int br;                     // icy-br int value
    AudioFileTypeID streamType; // stream type for core audio
    int metaInterval;           // icy-metaint int value
    NSString *icyMetaInt;       // icy-metaint NSString value
    
    int dataRest;               // audio data remaining before metadata
    char *metaData;             // C style metadata
    UInt32 metaSize;            // size of metadata
    NSString *streamTitle;      // value of SteamTitle tag
    
    BOOL tornMetaData;          // flag set when metadata tears between packets
    int tornMetaSize;           // size of torn (second) portion of metadata
}

- (void) startWithURL: (NSString *) url;
- (void) stop;
- (void) updateStreamTitle: (id) title;

@property (retain, nonatomic) ASDataModel *dataModel; 
@property (retain, nonatomic) NSThread *thread;
@property (assign, nonatomic) BOOL preparing;
@property (assign, nonatomic) BOOL playing;
@property (assign, nonatomic) BOOL finishing;
@property (copy, nonatomic) NSString *streamTitle;
@property (copy, nonatomic) NSString *urlString;
@property (assign, nonatomic) BOOL allowMixing;
@property (copy, nonatomic) NSString *contentType;
@property (copy, nonatomic) NSString *bitRate;
@property (retain, nonatomic) NSString *icyMetaInt;


@end
