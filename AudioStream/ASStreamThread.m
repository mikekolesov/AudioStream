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
    //NSURL *url = [NSURL URLWithString: @"http://91.190.117.131:8000/64"];
    //NSURL *url = [NSURL URLWithString: @"http://online.radiorecord.ru:8100/rr_ogg"];
    NSURL *url = [NSURL URLWithString: @"http://online.radiorecord.ru:8100/rr_aac"];
    //NSURL *url = [NSURL URLWithString: @"http://79.143.70.114:8000/detifm-onair-64k.aac"];
    //NSURL *url = [NSURL URLWithString: @"http://79.143.70.114:8000/detifm-dvbs-64k.aac"];
    //NSURL *url = [NSURL URLWithString: @"http://radiovkontakte.ru:8000/rvkaac"];
    //NSURL *url = [NSURL URLWithString: @"http://radiovkontakte.ru:8000/rvkmp3"];
    //NSURL *url = [NSURL URLWithString: @"http://serveur.wanastream.com:24100"];
    //NSURL *url = [NSURL URLWithString: @"http://listen.radiogora.ru:8000/electro192"];
    //NSURL *url = [NSURL URLWithString: @"http://listen.radiogora.ru:8000/electro320"];
    
    //AAN PURE ROCK SHOUTast
    //NSURL *url = [NSURL URLWithString: @"http://174.37.159.206:9000/"];
    
    //A-All Metal Radio SHOUTast
    //NSURL *url = [NSURL URLWithString: @"http://173.192.224.123:8543/"];

    //SKY.FM SMOOTH LOUNGE
    //NSURL *url = [NSURL URLWithString: @"http://u16b.sky.fm:80/sky_smoothlounge_aac"];
    
    //SKY.FM Modern Rock Alternative
    //NSURL *url = [NSURL URLWithString: @"http://u16b.sky.fm:80/sky_hardrock_aacplus"];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: url];
    
    //allow background http streaming
    [req setNetworkServiceType:NSURLNetworkServiceTypeVoIP];
    
    // for getting song title
    [req addValue: @"1" forHTTPHeaderField: @"Icy-MetaData"];
    
    //[req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    NSLog( @"request method:\n %@", [req HTTPMethod]);
    NSLog( @"request header: %@", [req allHTTPHeaderFields]);
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
    
    // Defaults
    
    
    
    
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
    
    
    // Getting stream's type, bitrate and meta interval from http header
    NSDictionary *allHeaders = [http_resp allHeaderFields];
    contentType = [allHeaders objectForKey: @"Content-Type"];
    bitRate = [allHeaders objectForKey:@"icy-br"];
    icyMetaInt = [allHeaders objectForKey:@"icy-metaint"];
    
    // set default values
    streamType = 0; br = 128; metaInterval = 0;
    
    checkIfShoutcast = NO;
    if (contentType == nil && bitRate == nil)
    {
        NSLog(@"it seems SHOUTcast non-standard header, try later in didReceiveData");
        checkIfShoutcast = TRUE;
        return;
    }


    [self parseStreamType];

    [self parseStreamBitrate];
    
    [self parseMetaInterval];
    
    
    AudioPartNewStream(streamType, br);
}



- (void) parseStreamType
{
    // parse stream type
    NSLog(@"Type of stream is <%@>", contentType);
    textHtml = NO;
    
    if ( [contentType isEqualToString: @"audio/mpeg"] ) {
        streamType = kAudioFileMP3Type;
    }
    else if ( [contentType isEqualToString: @"audio/aacp"] ) {
        streamType = kAudioFileAAC_ADTSType;
    }
    else if ( [contentType isEqualToString:@"text/html"]) {
        // no audio stream avalable. server mountpoint is down?
        textHtml = YES; // check later in connectionDidFinishLoading
    }
    else {
        // unsupported type or custom mpeg/aacp naming?
        NSLog(@"unsupported content-type: %@", contentType);
        
        // try mp3 as default value if unknown
        streamType = kAudioFileMP3Type;
        
    }
    
    [contentType retain];
}

-(void) parseStreamBitrate
{
    // parse stream bitrate
    br = [bitRate intValue];
    if (br == 0) {
        NSLog(@"Bitrate string is invalid <%@>", bitRate);
        br = 128; // try 128 Kbps default value if unknown
    } else if (br < 8 || br > 320 ) {
        NSLog(@"Bitrate is out of supported range[8-320]: %d", br);
        br = 128;
    }
    else {
        NSLog(@"Bitrate is %d", br);
    }
    
     [bitRate retain];
}

-(void) parseMetaInterval
{
    metaInterval = [icyMetaInt intValue];
    NSLog(@"Meta Interval is %d", metaInterval);
    dataRest = metaInterval;
    tornMetaData = NO;
    metaSize = 0;
    tornMetaData = 0;
    
    [icyMetaInt retain];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSUInteger allDataLen = 0;
    UInt8 metaByte = 0;
    const char *allData = NULL;
    char *cutData = NULL;
    char *originCutData = NULL;
    int cutDataLen = 0;
    
    
    allData = [data bytes];
    allDataLen = [data length];
    
    NSLog( @"Data, %d", allDataLen );
    
    if (checkIfShoutcast) { // parse SHOUTcast http header
        NSString *dataWithHeader = [[NSString alloc] initWithBytes:allData length:allDataLen encoding:NSASCIIStringEncoding];
        NSRange icy200OK = {0}, endOfHeader = {0};
        // check this is ICY response
        icy200OK = [dataWithHeader rangeOfString:@"ICY 200 OK"];
        if (icy200OK.length != 0) {
            NSLog(@"ICY found");
            
            // find end of header
            endOfHeader = [dataWithHeader rangeOfString:@"\r\n\r\n"];
            if (endOfHeader.location > 0 && endOfHeader.location < allDataLen) {
                NSString *shoutHeader = [[NSString alloc] initWithBytes:allData length:endOfHeader.location encoding:NSASCIIStringEncoding];
                
                // separate header by fields (lines) 
                NSArray *headerFields = [shoutHeader componentsSeparatedByString:@"\r\n"];
                for (NSString *field in headerFields) {
                    // sepatate field by colon
                    NSArray *separatedField = [field componentsSeparatedByString:@":"];
                    if ([[separatedField objectAtIndex:0] isEqualToString:@"content-type"]) {
                        contentType = [separatedField objectAtIndex:1];
                        [self parseStreamType];
                    }
                    if ([[separatedField objectAtIndex:0] isEqualToString:@"icy-br"]) {
                        bitRate = [separatedField objectAtIndex:1];
                        [self parseStreamBitrate];
                    }
                    if ([[separatedField objectAtIndex:0] isEqualToString:@"icy-metaint"]) {
                        icyMetaInt = [separatedField objectAtIndex:1];
                        [self parseMetaInterval];
                    }

                }
                [shoutHeader release];
                
                // shift to data
                allData += endOfHeader.location + endOfHeader.length;
                allDataLen -= endOfHeader.location + endOfHeader.length;
            }
            else {
                NSLog(@"End of header not found");
            
            }
        }
        else {
            NSLog(@"ICY not found");
        }

        AudioPartNewStream(streamType, br);
        
        [dataWithHeader release];
        checkIfShoutcast = NO; // check for the first time only
    }
    
    if (metaInterval) { // parse title SHOUTcast metadata
        
        cutData = calloc(1, allDataLen); // alloc maximum avalable buffer
        originCutData = cutData; // save origin pointer
        //NSLog(@"cutData allocated %d", allDataLen);
        
        if (tornMetaData) { // metadata was torn between current and previous packets
            // cutting the second part of metadata
            NSLog(@"Torn data, second part");
            memcpy(metaData + (metaSize - tornMetaSize), allData, tornMetaSize); 
            NSString *md = [[NSString alloc] initWithBytes:metaData length:metaSize encoding:NSASCIIStringEncoding];
            //NSLog(@"FullMetaString=<%@>", md);
            NSArray *mdSeparated = [md componentsSeparatedByString:@"'"];
            if (streamTitle) [streamTitle release];
            streamTitle = [mdSeparated objectAtIndex:1];
            [streamTitle retain];
            NSLog(@"StreamTitle=<%@>", streamTitle);
            
            [md release];
            free(metaData);
            
            allData += tornMetaSize; // increase address, shift to next audio data part
            allDataLen -= tornMetaSize; // decrease length
            tornMetaSize = 0;
            tornMetaData = NO;
        }
           
        while (1) {
            if (dataRest < allDataLen) { // we get metainterval in the packet
                //NSLog(@"Meta interval arrived");
                //NSLog(@"dataRest %d, allDataLen %d", dataRest, allDataLen);
                // since we can safely read (next after dataRest) byte of meta length
                metaByte = *(allData + dataRest);
                if (metaByte) { // there is metadata
                    metaSize = metaByte * 16;
                    //NSLog(@"Metadata detected!");
                    //NSLog(@"metaByte %d, metaSize %ld", metaByte, metaSize);
                    if (dataRest + 1 + metaSize <= allDataLen) { //metadata fully available
                        
                        //NSLog(@"Full metadata");

                        // cutting metadata
                        metaData = calloc(1, metaSize);
                        memcpy(metaData, allData + dataRest + 1, metaSize);
                        NSString *md = [[NSString alloc] initWithBytes:metaData length:metaSize encoding:NSASCIIStringEncoding];
                        //NSLog(@"FullMetaString=<%@>", md);
                        NSArray *mdSeparated = [md componentsSeparatedByString:@"'"];
                        if (streamTitle) [streamTitle release];
                        streamTitle = [mdSeparated objectAtIndex:1];
                        [streamTitle retain];
                        NSLog(@"StreamTitle=%@", streamTitle);
                        
                        [md release];
                        free(metaData);
                        
                        // cutting audio data
                        //NSLog(@"cutting dataRest %d, allDataLen %d", dataRest, allDataLen);
                        memcpy(cutData, allData, dataRest);
                        cutData += dataRest; // shift audio data pointer
                        cutDataLen += dataRest;
                        allData += dataRest + 1 + metaSize; // shift all data pointer after metaByte(+1) and metadata(+metaSize)
                        allDataLen -= dataRest + 1 + metaSize;
                        
                        dataRest = metaInterval; // reset audio data counter
                    }
                    else { //torn metadata. just for sure
                        //NSLog(@"torn metadata");
                        
                        // cutting first part of metadata
                        metaData = calloc(1, metaSize);
                        memcpy(metaData, allData + dataRest + 1, allDataLen - 1 - dataRest);
                        tornMetaSize = metaSize - (allDataLen - 1 - dataRest); // save size of second torn portion of metadata
                        tornMetaData = YES;
                        
                        // cutting audio data
                        memcpy(cutData, allData, dataRest);
                        cutData += dataRest; // shift audio data pointer
                        cutDataLen += dataRest;
                        dataRest = metaInterval; // reset audio data counter
                        
                        //NSLog(@"End of buffer");
                        break; // bufer ended
                        
                    }
                }
                else { // no metadata, cutting audio data
                    //NSLog(@"No metadata detected, just metaByte");
                    //NSLog(@"cutting dataRest %d, allDataLen %d", dataRest, allDataLen);
                    
                    memcpy(cutData, allData, dataRest); // copy only reminded portion of audio data
                    cutData += dataRest; // shift audio data pointer 
                    cutDataLen += dataRest;
                    allData += dataRest + 1; // shift all data pointer after metaByte (+1)
                    allDataLen -= dataRest + 1;
                    
                    dataRest = metaInterval; // reset audio data counter                   
                }
            }
            else { // no metainterval in the packet
                //NSLog(@"No meta interval, just audio data");
                //NSLog(@"dataRest %d, allDataLen %d", dataRest, allDataLen);
                memcpy(cutData, allData, allDataLen);
                cutDataLen += allDataLen;
                dataRest -= allDataLen;
                //NSLog(@"End of buffer");
                break; // bufer ended
            }
        } // end of while
        
        //NSLog(@"Finally parse %d bytes", cutDataLen);
        if (cutDataLen)
            AudioPartParser(originCutData, cutDataLen);
        
        free(originCutData);
    }
    else {
        AudioPartParser(allData, allDataLen);
    }
      
    // call us ~ every 300 miliseconds
    //[NSThread sleepForTimeInterval:0.3];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog( @"Finished" );
    if (textHtml) {
        NSLog(@"server mountpoint down");
        textHtml = NO;
    }
    [conn release];
}


@end
