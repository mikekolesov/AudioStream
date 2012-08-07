//
//  ASMasterViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioPart.h"
#import "ASStreamThread.h"


@class ASDetailViewController;

@interface ASMasterViewController : UITableViewController <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    ASStreamThread *streamThread;
}

@property (strong, nonatomic) ASDetailViewController *detailViewController;


@end
