//
//  ASStreamThread.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ASStreamThread : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSThread *thread;           // stream thread object
    CFRunLoopRef runLoop;       // run loop
    NSURLConnection *conn;      // stream connection 
    NSString *urlString;        // stream url string
    
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

-(void) startWithURL: (NSString *) url;
-(void) stop;
-(void) test;
-(void) performTest;

@property (retain, nonatomic) NSThread *thread;
@property (assign, nonatomic) BOOL playing;
@property (retain, nonatomic) NSString *streamTitle;
@property (retain, nonatomic) NSString *urlString;

@end
