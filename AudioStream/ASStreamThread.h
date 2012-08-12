//
//  ASStreamThread.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioPart.h"

@interface ASStreamThread : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSThread *thread;
    NSURLConnection *conn;
    BOOL finish;
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

-(void) start;
-(void) test;
-(void) performTest;

@property (retain, nonatomic) NSThread *thread;

@end
