//
//  ASStreamThread.m
//  AudioStream
//
//  Created by Michael Kolesov on 8/3/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASStreamThread.h"
#import "AudioPart.h"
#import <pthread.h>


@implementation ASStreamThread

@synthesize dataModel;
@synthesize thread;
@synthesize preparing;
@synthesize playing;
@synthesize finishing;
@synthesize streamTitle;
@synthesize urlString;
@synthesize allowMixing;
@synthesize contentType;
@synthesize bitRate;
@synthesize icyMetaInt;

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.preparing = NO;
        self.playing = NO;
        self.finishing = NO;
        self->releaseThread = NO;
    }
    return self;
}

-(void) dealloc
{
    [dataModel release];
    [streamTitle release];
    [super dealloc];
}

-(void) displayError: (NSString*)title withMessage: (NSString*)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [alert release];
}


-(void) startWithURL:(NSString *) url
{
    preparing = TRUE;
        
    urlString = url;
  
    if (releaseThread) {
        // cleaning previous thread breaking
        [thread release]; 
        releaseThread = NO;
    }
    
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(streamThread) object:nil];
    if (thread != nil ) {
        [thread setName:@"StreamThread"];
        NSLog(@"Thread name:%@", thread.name);
        [thread start];
    }
    else {
        [self displayError:@"Start Error" withMessage: @"Thread init failed"];
        preparing = NO;
        [dataModel resetPlayingState];
    }
   
}

-(void) stop
{
    finishing = YES;
    
    // stopping connection
    [conn cancel];

    // finishing audio playback
    AudioPartFinish(callbackFinished);
    
    // waiting connection callback exit
    while (!callbackFinished) {
        [NSThread sleepForTimeInterval: 0.2];
    }
    
    // Exit run loop
    [conn unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [conn release];
    
    NSLog(@"thread finished? %d", [thread isFinished]);
   
    // waiting for finishing thread body method
    [NSThread sleepForTimeInterval: 0.2];
    
    if (![thread isFinished]) { // run loop unblock
        if (CFRunLoopIsWaiting(runLoop)) {
            NSLog(@"RunLoopIsWaiting.. Force to stop it");
            #ifdef DEBUG
                CFShow(runLoop);
            #endif
            CFRunLoopStop(runLoop);
        }

    }
      
    [thread release];
    
    allowMixing = NO;
    finishing = NO;
    playing = NO;
    preparing = NO;
    
    [dataModel resetPlayingState];
}

-(void) streamThread
{
    NSLog(@"Enter streamThread");
    NSAutoreleasePool *topPool = [[NSAutoreleasePool alloc] init];
    
    // set pthread name to show in debugger
    pthread_setname_np([[[NSThread currentThread] name] UTF8String]);
    
    if ([self runAudioStream] == -1) {
        [topPool release];
        allowMixing = NO;
        preparing = NO;
        releaseThread = YES;
        [dataModel resetPlayingState];
        return; // breaking thread
    }
    
    runLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    
    // block here to monitor and handle NSURLConnection methods
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
    
    [topPool release];
    NSLog(@"Exit streamThread");
}

- (int) runAudioStream
{
    // init audio data
    if ( AudioPartInit(allowMixing) == -1 )
    {
        [self displayError:@"Audio Error" withMessage:@"Audio init failed"];
        return -1;
    }
    
    // configure network connection
    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: url];
    
    // allow background http streaming
    [req setNetworkServiceType:NSURLNetworkServiceTypeVoIP];
    
    // set short timeout
    req.timeoutInterval = 15.0;
    
    // for getting song title
    [req addValue: @"1" forHTTPHeaderField: @"Icy-MetaData"];
    
    NSLog( @"request method:\n %@", [req HTTPMethod]);
    NSLog( @"request header: %@", [req allHTTPHeaderFields]);
    
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    
    if (!conn) {
        NSLog( @"Connection init failed" );
        [self displayError:@"Connection Error" withMessage:@"Connection init failed"];
        AudioPartInitClean();
        [dataModel resetPlayingState];
        return -1;
    }
    else {
        NSLog( @"Connection init OK" );
    }

    [conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [conn start];
    
    return 0;
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    callbackFinished = NO;
    NSLog( @"Response");
    
    NSHTTPURLResponse *http_resp = ( NSHTTPURLResponse *) response;
    NSLog( @"%@", [http_resp allHeaderFields]);
    
    
    // Getting stream's type, bitrate and meta interval from http header
    NSDictionary *allHeaders = [http_resp allHeaderFields];
    self.contentType = [allHeaders objectForKey: @"Content-Type"];
    self.bitRate = [allHeaders objectForKey:@"icy-br"];
    self.icyMetaInt = [allHeaders objectForKey:@"icy-metaint"];
    
    // set default values
    streamType = 0; br = 128; metaInterval = 0;
    
    checkIfShoutcast = NO;
    if (contentType == nil && bitRate == nil)
    {
        NSLog(@"it seems SHOUTcast non-standard header, try later in didReceiveData");
        checkIfShoutcast = TRUE;
        return;
    }


    if (![self parseStreamType]) {
        NSString *msg = [NSString stringWithFormat:@"Unsupported content type: %@", self.contentType];
        [self displayError:@"Audio Error" withMessage:msg];
        [self cancelStream];
        return;
    }

    [self parseStreamBitrate];
    
    [self parseMetaInterval];
    
    
    if ( AudioPartNewStream(streamType, br) == -1 )
    {
        [self displayError:@"Audio Error" withMessage:@"Audio stream open failed"];
        [self cancelStream];
        return;
    }
    
    callbackFinished = YES;
}

- (BOOL) parseStreamType
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
        return NO;
    }
    else {
        // unsupported type or custom mpeg/aacp naming?
        NSLog(@"unsupported content-type: %@", contentType);
        
        // try mp3 as default value if unknown
        //streamType = kAudioFileMP3Type;
        
        return NO;
    }
        
    //[contentType retain];
    
    return YES;
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
   
    // escape posible dub field
    NSArray *brArray = [bitRate componentsSeparatedByString:@","];
    if (brArray.count > 1) {
        NSString *firstBr = [brArray objectAtIndex:0];
        self.bitRate = firstBr;
    }
    
     //[bitRate retain];
}

-(void) parseMetaInterval
{
    metaInterval = [icyMetaInt intValue];
    NSLog(@"Meta Interval is %d", metaInterval);
    dataRest = metaInterval;
    tornMetaData = NO;
    metaSize = 0;
    tornMetaData = 0;
    
    //[icyMetaInt retain];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSUInteger allDataLen = 0;
    UInt8 metaByte = 0;
    const char *allData = NULL;
    char *cutData = NULL;
    char *originCutData = NULL;
    int cutDataLen = 0;
    
    callbackFinished = NO;
    
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
                        if (![self parseStreamType]) {
                            NSString *msg = [NSString stringWithFormat:@"Unsupported content type: %@", self.contentType];
                            [self displayError:@"Audio Error" withMessage:msg];
                            [self cancelStream];
                            [shoutHeader release];
                            return;
                        }
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

        if ( AudioPartNewStream(streamType, br) == -1 )
        {
            [self displayError:@"Audio Error" withMessage:@"SHOUTcast audio stream open failed"];
            [self cancelStream];
            return;
        }
        
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
            [self cutStreamTitle];
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
                        [self cutStreamTitle];
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
                        NSLog(@"torn metadata");
                        
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
            if ( AudioPartParser(originCutData, cutDataLen) == -1 ) {
                [self displayError:@"Audio Error" withMessage:@"Audio parser failed"];
                free(originCutData);
                [self cancelStream];
                return;
            }
        
        free(originCutData);
    }
    else {
        if ( AudioPartParser(allData, allDataLen) == -1 ) {
            [self displayError:@"Audio Error" withMessage:@"Audio parser failed"];
            [self cancelStream];
            return;
        }
    }
      
    // call us ~ every 300 miliseconds
    //[NSThread sleepForTimeInterval:0.3];
    
    
    // reset preparing state once at start
    if (preparing) {
        if (!AudioPartIsPreparing()) {
            preparing = FALSE;
            playing = YES;
            [dataModel makeSelectedObjectPlaying];
        }
    }
    
    // check if audio engine error occured
    if ( AudioPartIsEngineError() ) {
        NSString *err = [NSString stringWithCString:AudioPartEngineErrorDescription() encoding:NSASCIIStringEncoding];
        [self displayError:@"Audio Error" withMessage:err];
        [self cancelStream];
    }
    
    callbackFinished = YES;
}


- (void) cutStreamTitle
{
    NSString *md = [[NSString alloc] initWithBytes:metaData length:metaSize encoding:NSUTF8StringEncoding];
    //NSLog(@"FullMetaString=<%@>", md);
    NSRange tagBeggining ={0};
    NSRange tagEnding = {0};
    NSRange tagRange;
    tagBeggining = [md rangeOfString:@"StreamTitle='"];
    tagEnding = [md rangeOfString:@"';"];
    if (tagBeggining.location == NSNotFound || tagEnding.location == NSNotFound) {
        self.streamTitle = [NSString stringWithFormat:@"..."];
    }
    else {
        tagRange.location = tagBeggining.location + tagBeggining.length;
        tagRange.length = tagEnding.location - tagRange.location;
        self.streamTitle = [md substringWithRange:tagRange];
    }
    
    NSLog(@"StreamTitle=%@", streamTitle);
    
    if (playing)
        [self performSelectorOnMainThread:@selector(updateStreamTitle:) withObject:streamTitle waitUntilDone:NO];
    
    [md release];
}

- (void) updateStreamTitle: (id) title
{
    // invokes key-value observing
    dataModel.objectTitle = title;
    NSLog(@"Updated to title: %@", dataModel.objectTitle);
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    callbackFinished = NO;
    
    NSLog( @"Finished" );
    if (textHtml) {
        NSLog(@"server mountpoint down");
        textHtml = NO;
    }
    
    [self displayError:@"Connection Error" withMessage:@"Connection finished. Check stream availability"];
    [self cancelStream];
    
    callbackFinished = YES;
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    callbackFinished = NO;
    
    NSLog( @"Error: %@", [error localizedDescription] );
    NSString *errmsg = [NSString stringWithFormat:@"%@ Check URL port and address", [error localizedDescription]];
    [self displayError:@"Connection Error" withMessage:errmsg];
    [self cancelStream];
       
    callbackFinished = YES;
}

- (void) cancelStream
{
    // stopping connection
    [conn cancel];
    
    [conn unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [conn release];
    
    if (playing) // finishing audio playback
        AudioPartFinish(YES);
    
    // unblock loop
    CFRunLoopStop(runLoop);
    
    // release thread instance later
    releaseThread = YES;
    
    allowMixing = NO;
    finishing = NO;
    playing = NO;
    preparing = NO;
    
    [dataModel resetPlayingState];
}

@end


