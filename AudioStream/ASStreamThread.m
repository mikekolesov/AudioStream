//
//  ASStreamThread.m
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASStreamThread.h"
#import "AudioPart.h"

@implementation ASStreamThread

-(void) start
{
    playing = NO;
    finish = NO;
    
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(streamThread) object:nil];
    [thread setName:@"Stream Thread"];
    [thread start];
    //[NSThread detachNewThreadSelector:@selector(streamThread) toTarget:self withObject:nil];
}

-(void) streamThread
{
    NSLog(@"Enter thread");
    NSAutoreleasePool *topPool = [[NSAutoreleasePool alloc] init];
    
    
    [self runAudioStream];
    
    while (!finish)
    {
       // block here to monitor and handle NSURLConnection [performselector] methods..
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
        
    }
    
    
    [topPool release];
    NSLog(@"Exit thread");
}

-(void) test
{
    NSLog(@"Test, %d", finish);
}

-(void) performTest
{
   NSLog(@"Perform Test");
}

- (void) runAudioStream
{
    if (playing)
    {
        playing = NO;
        // stop and flush data
    }
    
    // configure network connection
    
    //NSURL *url = [NSURL URLWithString: @"http://91.190.117.131:8000/live"];
    //NSURL *url = [NSURL URLWithString: @"http://online.radiorecord.ru:8100/rr_ogg"];
    NSURL *url = [NSURL URLWithString: @"http://online.radiorecord.ru:8100/rr_aac"];
    //NSURL *url = [NSURL URLWithString: @"http://79.143.70.114:8000/detifm-onair-64k.aac"];
    //NSURL *url = [NSURL URLWithString: @"http://79.143.70.114:8000/detifm-dvbs-64k.aac"];
    //NSURL *url = [NSURL URLWithString: @"http://radiovkontakte.ru:8000/rvkaac"];
    //NSURL *url = [NSURL URLWithString: @"http://radiovkontakte.ru:8000/rvkmp3"];
    //NSURL *url = [NSURL URLWithString: @"http://serveur.wanastream.com:24100"];
    //NSURL *url = [NSURL URLWithString: @"http://listen.radiogora.ru:8000/electro192"];
    //NSURL *url = [NSURL URLWithString: @"http://listen.radiogora.ru:8000/electro320"];
    
    //AAN PURE ROCK
    //NSURL *url = [NSURL URLWithString: @"http://174.37.159.206:9000/"];
    
    //A-All Metal Radio
    //NSURL *url = [NSURL URLWithString: @"http://173.192.224.123:8543/"];

    //SKY.FM SMOOTH LOUNGE
    //NSURL *url = [NSURL URLWithString: @"http://u16b.sky.fm:80/sky_smoothlounge_aac"];
    
    //SKY.FM Modern Rock Alternative
    //NSURL *url = [NSURL URLWithString: @"http://u16b.sky.fm:80/sky_hardrock_aacplus"];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: url];
    
    //allow background http streaming
    [req setNetworkServiceType:NSURLNetworkServiceTypeVoIP];
    
    //[req addValue: @"1" forHTTPHeaderField: @"Icy-MetaData"];
    
    //[req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    //NSLog( @"request method: %@", [req HTTPMethod]);
    //NSLog( @"request: %@", [req allHTTPHeaderFields]);
    //NSLog( @"request body: %@", [req HTTPBody]);
    //[req setHTTPMethod: @"GET"];
    
    //conn = [[NSURLConnection alloc] initWithRequest: req delegate: self];
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [conn start];
    
    if (!conn)
    {
        NSLog( @"Connection failed" );
    }
    else
    {
        NSLog( @"Connection OK" );
    }
    
    // configure audio part (if stream type is known before connection response)
    // AudioPartNewStream( _Some_Known_streamType);
    
    playing = YES;
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog( @"Error: %@", [error localizedDescription] );
    [conn release];
    // FIXME try runAudioStream again
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog( @"Response");
    
    NSHTTPURLResponse *http_resp = ( NSHTTPURLResponse *) response;
    NSLog( @"%@", [http_resp allHeaderFields]);
    
    // set stream type
    NSDictionary *allHeaders = [http_resp allHeaderFields];
    NSString *contentType = [allHeaders objectForKey: @"Content-Type"];
    
    AudioFileTypeID streamType = 0; //
    
    if ( [contentType isEqualToString: @"audio/mpeg"] )
    {
        streamType = kAudioFileMP3Type;
    }
    else if ( [contentType isEqualToString: @"audio/aacp"] )
    {
        streamType = kAudioFileAAC_ADTSType;
    }
    else
    {
        //unknown, zero means AudioParser will try to guess itself
        //streamType = 0;
        // try mp3 type as default
        streamType = kAudioFileMP3Type;
    }
    
    AudioPartNewStream(streamType);
    
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog( @"Data, %d", [data length] );
    
    /*NSString *html = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
     NSLog( @"%@", html );
     [html release];*/
    
    AudioPartParser([data bytes], [data length]);
    
    [NSThread sleepForTimeInterval:0.2];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog( @"Finished" );
    [conn release];
}


@end
