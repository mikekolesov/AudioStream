//
//  ASStreamThread.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASStreamThread : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSThread *thread;
    NSURLConnection *conn;
    BOOL finish;
    BOOL playing;
}

-(void) start;
-(void) test;
-(void) performTest;

@property (retain, nonatomic) NSThread *thread;

@end
