//
//  ASMasterViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>


@class ASDetailViewController;

@interface ASMasterViewController : UITableViewController <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) ASDetailViewController *detailViewController;



@end
