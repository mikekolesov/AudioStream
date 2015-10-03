//
//  AudioPart.c
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All Rights Reserved.
//  Based on Apple code example. Copyright (c) 2007 Apple Inc. All Rights Reserved. 

#include "AudioPart.h"

MyData* myAudioPartData;


void MyPropertyListenerProc(void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags)
{
	// this is called by audio file stream when it finds property values
	MyData* myData = (MyData*)inClientData;
	OSStatus err = noErr;
    
	printf("found property '%c%c%c%c'\n", (char)((inPropertyID>>24)&255),
           (char)((inPropertyID>>16)&255), (char)((inPropertyID>>8)&255),
           (char)(inPropertyID&255));
    
	switch (inPropertyID) {
  
		case kAudioFileStreamProperty_ReadyToProducePackets :
		{
            // the file stream parser is now ready to produce audio packets.
			
            // get the stream format.
			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
    
            if (err) {
                PRINTERROR("get kAudioFileStreamProperty_DataFormat");
                myData->failed = true;
                myData->engineError = true;
                myData->engineErrorDescription = "Data format unknown";
                return;
            }
            
            err = CFSwapInt32HostToBig(asbd.mFormatID);
			printf("Data Format '%4.4s'\n", (char*)&err);
            
			// create the audio queue
			err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, myData, NULL, NULL, 0, &myData->audioQueue);
			if (err) {
                PRINTERROR("AudioQueueNewOutput");
                myData->failed = true;
                myData->engineError = true;
                myData->engineErrorDescription = "Cannot create audio queue";
                return;
            }
			
			// allocate audio queue buffers
            myData->bufSize = (myData->bitRate / 8) * 1024;
            for (unsigned int i = 0; i < kNumAQBufs; ++i) {
				err = AudioQueueAllocateBuffer(myData->audioQueue, myData->bufSize, &myData->audioQueueBuffer[i]);
				if (err) {
                    PRINTERROR("AudioQueueAllocateBuffer");
                    myData->failed = true;
                    myData->engineError = true;
                    myData->engineErrorDescription = "Allocating audio buffer failed";
                    AudioQueueDispose(myData->audioQueue, true);
                    return;
                }
			}
            
            // setup minimum pre-streamed buffers
            myData->preStreamedBuffers = kPreStreamedBufs;
            
			// get the cookie size
			UInt32 cookieSize;
			Boolean writable;
			err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
			if (err) { PRINTERROR("info kAudioFileStreamProperty_MagicCookieData"); break; }
			printf("cookieSize %u\n", (unsigned int)cookieSize);
            
			// get the cookie data
			void* cookieData = calloc(1, cookieSize);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
			if (err) { PRINTERROR("get kAudioFileStreamProperty_MagicCookieData"); free(cookieData); break; }
            
			// set the cookie on the queue.
			err = AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
			free(cookieData);
			if (err) { PRINTERROR("set kAudioQueueProperty_MagicCookie"); break; }
            
			// listen for kAudioQueueProperty_IsRunning
			err = AudioQueueAddPropertyListener(myData->audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, myData);
			if (err) { PRINTERROR("AudioQueueAddPropertyListener"); myData->failed = true; break; }
			
			break;
		}
	}
}

void MyPacketsProc(	void *							inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions)
{
	// this is called by audio file stream when it finds packets of audio
	MyData* myData = (MyData*)inClientData;
	
    if (myData->engineError)
        return;
    
    if (myData->finishing) {
        myData->finishingReady = true;
        return;
    }
    printf("got data.  bytes: %u  packets: %u\n", (unsigned int)inNumberBytes, (unsigned int)inNumberPackets);
	// the following code assumes we're streaming VBR data. for CBR data, you'd need another code branch here.
    
	for (int i = 0; i < inNumberPackets; ++i) {
		SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
		SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
		
		// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
		size_t bufSpaceRemaining = myData->bufSize - myData->bytesFilled;
		if (bufSpaceRemaining < packetSize)
        {
            printf("buffer space ended\n");
			if ( MyEnqueueBuffer(myData) != noErr ) {
                myData->engineError = true;
                return;
            }
			WaitForFreeBuffer(myData);
		}
		if (myData->finishing) {
            myData->finishingReady = true;
            return;
        }
		// copy data to the audio queue buffer
		AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
		memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
		// fill out packet description
		myData->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
		myData->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
		// keep track of bytes filled and packets filled
		myData->bytesFilled += packetSize;
		myData->packetsFilled += 1;
		
		// if that was the last free packet description, then enqueue the buffer.
		size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
		if (packetsDescsRemaining == 0)
        {
            printf("max packet descs reached\n");
			if ( MyEnqueueBuffer(myData) != noErr ) {
                myData->engineError = true;
                return;
            }
			WaitForFreeBuffer(myData);
		}
        if (myData->finishing) {
            myData->finishingReady = true;
            return;
        }
	}
}

OSStatus StartQueueIfNeeded(MyData* myData)
{
	OSStatus err = noErr;
    int curPreStreamed;
    UInt32 allow = true;

    
	if (!myData->started) {		// start the queue if it has not been started already
        
        // check of currently pre-streamed buffers
        pthread_mutex_lock(&myData->mutex);
 
        curPreStreamed = 0;
        for (int a = 0; a < kNumAQBufs ; a++)
        {
            if (myData->inuse[a])
            {
                curPreStreamed++;
            }
        }
        pthread_mutex_unlock(&myData->mutex);
        
        if (curPreStreamed >= myData->preStreamedBuffers )
        {
            if (myData->allowMixing) { // backgroung interrupt workaround. part 1
                printf("allow mixing workaround\n");
                allow = true;
                err = AudioSessionSetProperty( kAudioSessionProperty_OverrideCategoryMixWithOthers,
                                                sizeof (allow),
                                                &allow);
                if (err) {
                    PRINTERROR("AudioSessionSetProperty Mix");
                    myData->failed = true;
                    myData->engineErrorDescription = "Setting audio session property failed";
                    return err;
                }
                err = AudioSessionSetActive(true);
                if (err) {
                    PRINTERROR("AudioSessionSetActive");
                    myData->failed = true;
                    myData->engineErrorDescription = "Audio session activation failed";
                    return err;
                }
                
            }
            
            err = AudioQueueStart(myData->audioQueue, NULL);
            if (err) {
                PRINTERROR("AudioQueueStart");
                myData->failed = true;
                myData->engineErrorDescription = "Audio queue start failed";
                return err;
            }
            
            // preparing state ended, next is playing state
            if ( myData->preparing )
                myData->preparing = false;


            
            if (myData->allowMixing) { // backgroung interrupt workaround. part 2
                allow = false;
                err = AudioSessionSetProperty( kAudioSessionProperty_OverrideCategoryMixWithOthers,
                                                sizeof (allow),
                                                &allow);
                if (err) {
                    PRINTERROR("AudioSessionSetProperty NoMix");
                    myData->failed = true;
                    myData->engineErrorDescription = "Reseting audio session property failed";
                    return err;
                }

                myData->allowMixing = false;
            }
            
            myData->started = true;
            printf("started\n");
        }
        else
        {
            printf("not started. not enough buffers.. %d\n", curPreStreamed );
        }
	}
	return err;
}

OSStatus MyEnqueueBuffer(MyData* myData)
{
	OSStatus err = noErr;
	myData->inuse[myData->fillBufferIndex] = true;		// set in use flag
	
	// enqueue buffer
	AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
	fillBuf->mAudioDataByteSize = (UInt32)myData->bytesFilled;
    err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, (UInt32)myData->packetsFilled, myData->packetDescs);
	if (err) {
        PRINTERROR("AudioQueueEnqueueBuffer");
        myData->failed = true;
        myData->engineErrorDescription = "Cannot enqueue audio buffer";
        return err;
    }
    
    printf("enqueued %zd packets %zd bytes ", myData->packetsFilled, myData->bytesFilled );
    for (int a = 0; a < kNumAQBufs; a++) {
        printf("%d ", myData->inuse[a]);
    }
    printf("\n");
	
    err = StartQueueIfNeeded(myData);
	
	return err;
}


void WaitForFreeBuffer(MyData* myData)
{
	// go to next buffer
	if (++myData->fillBufferIndex >= kNumAQBufs) myData->fillBufferIndex = 0;
	myData->bytesFilled = 0;		// reset bytes filled
	myData->packetsFilled = 0;		// reset packets filled
    
	// wait until next buffer is not in use
	printf("->lock\n");
	pthread_mutex_lock(&myData->mutex);
	while (myData->inuse[myData->fillBufferIndex]) {
		printf("... WAITING ...\n");
		pthread_cond_wait(&myData->cond, &myData->mutex);
        if (myData->finishing) {
            pthread_mutex_unlock(&myData->mutex);
            return;
        }
        
	}
	pthread_mutex_unlock(&myData->mutex);
	printf("<-unlock\n");
  
}

int MyFindQueueBuffer(MyData* myData, AudioQueueBufferRef inBuffer)
{
	for (unsigned int i = 0; i < kNumAQBufs; ++i) {
		if (inBuffer == myData->audioQueueBuffer[i])
			return i;
	}
	return -1;
}


void MyAudioQueueOutputCallback(void*					inClientData,
                                AudioQueueRef			inAQ,
                                AudioQueueBufferRef		inBuffer)
{
	// this is called by the audio queue when it has finished decoding our data.
	// The buffer is now free to be reused.
	MyData* myData = (MyData*)inClientData;

    int moreToPlay;
	unsigned int bufIndex = MyFindQueueBuffer(myData, inBuffer);
	
	// signal waiting thread that the buffer is free.
	pthread_mutex_lock(&myData->mutex);
	myData->inuse[bufIndex] = false;
    printf("%d free\n", bufIndex);
    
    moreToPlay = 0;
    for (int a = 0; a < kNumAQBufs ; a++)
    {
        if (myData->inuse[a])
        {
            moreToPlay = 1;
        }
    }
    if (!moreToPlay)
    {
        myData->started = 0;
        AudioQueuePause(myData->audioQueue);
        printf(">>paused\n");
    }
	
    pthread_cond_signal(&myData->cond);
	pthread_mutex_unlock(&myData->mutex);
    
}

void MyAudioQueueIsRunningCallback(	void*				inClientData,
                                   AudioQueueRef		inAQ,
                                   AudioQueuePropertyID	inID)
{
	MyData* myData = (MyData*)inClientData;
	
	UInt32 running;
	UInt32 size;
	OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &size);
	if (err) { PRINTERROR("get kAudioQueueProperty_IsRunning"); return; }
	if (!running) {
		pthread_mutex_lock(&myData->mutex);
		pthread_cond_signal(&myData->done);
		pthread_mutex_unlock(&myData->mutex);
	}
}


int AudioPartInit(bool allowMixing)
{
	// allocate a struct for storing our state
	myAudioPartData = (MyData*)calloc(1, sizeof(MyData));
    
    if (myAudioPartData == NULL)
        return (-1);
    
    myAudioPartData->preparing = true;
    
    // allow mixing with other apps for a moment
    myAudioPartData->allowMixing = allowMixing;
	
	// initialize a mutex and condition so that we can block on buffers in use.
	pthread_mutex_init(&myAudioPartData->mutex, NULL);
	pthread_cond_init(&myAudioPartData->cond, NULL);
	pthread_cond_init(&myAudioPartData->done, NULL);
	
    return 0;
}

int AudioPartNewStream ( AudioFileTypeID inStreamTypeHint, int bitRate )
{
    // create an audio file stream parser
	OSStatus err = AudioFileStreamOpen(myAudioPartData, MyPropertyListenerProc, MyPacketsProc,
                                       inStreamTypeHint, &myAudioPartData->audioFileStream);
    myAudioPartData->bitRate = bitRate;
	if (err)
    {
        PRINTERROR("AudioFileStreamOpen");
        return -1;
    }
    
    // set state
    myAudioPartData->finishing = false;
    myAudioPartData->finishingReady = false;
    
    return 0;
}
                        
                        
int AudioPartParser( const void * buf, ssize_t bytesRecvd )
{
    
    OSStatus err = 0;
	
    printf("->parser recv\n");
	
    if (bytesRecvd <= 0)
    {
        PRINTERROR("AudioPartParser");
        return -1;
    } 
		
    // parse the data. this will call MyPropertyListenerProc and MyPacketsProc
    err = AudioFileStreamParseBytes(myAudioPartData->audioFileStream, (UInt32)bytesRecvd, buf, 0);
    if (err) {
        PRINTERROR("AudioFileStreamParseBytes");
        return -1;
    }
	
    return 0;
}


int AudioPartFinish( bool immediate )
{
    OSStatus err = 0;
    
    if (!immediate) {
        myAudioPartData->finishing = true;
        pthread_mutex_lock(&myAudioPartData->mutex);
        pthread_cond_signal(&myAudioPartData->cond);
        pthread_mutex_unlock(&myAudioPartData->mutex);
        
        while (!myAudioPartData->finishingReady) {
            // wait for ending processing
            usleep(200*1000);
        }
    }

	printf("flushing\n");
	err = AudioQueueFlush(myAudioPartData->audioQueue);
	if (err) { PRINTERROR("AudioQueueFlush"); return 1; }
    
	printf("stopping\n");
	err = AudioQueueStop(myAudioPartData->audioQueue, true);
	if (err) { PRINTERROR("AudioQueueStop"); return 1; }
	
	// cleanup
    err = AudioQueueDispose(myAudioPartData->audioQueue, true);
    err = AudioFileStreamClose(myAudioPartData->audioFileStream);	

    pthread_mutex_destroy(&myAudioPartData->mutex);
    pthread_cond_destroy(&myAudioPartData->cond);
    pthread_cond_destroy(&myAudioPartData->done);
    free(myAudioPartData);
    
    return 0;
}

bool AudioPartIsPreparing( void )
{
    return myAudioPartData->preparing;
}

void AudioPartInitClean( void )
{
    pthread_mutex_unlock(&myAudioPartData->mutex);
    pthread_mutex_destroy(&myAudioPartData->mutex);
    pthread_cond_destroy(&myAudioPartData->cond);
    pthread_cond_destroy(&myAudioPartData->done);
    free(myAudioPartData);
}

bool AudioPartIsEngineError( void )
{
    return myAudioPartData->engineError;
}

char* AudioPartEngineErrorDescription( void )
{
    return myAudioPartData->engineErrorDescription;
}




