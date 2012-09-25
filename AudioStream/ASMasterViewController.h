//
//  ASMasterViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ASDataModel.h"
#import "ASStreamThread.h"

@class ASDetailViewController;

@interface ASMasterViewController : UITableViewController

@property (strong, nonatomic) ASDetailViewController *detailViewController;
@property (strong, nonatomic) ASDataModel *dataModel;
@property (strong, nonatomic) ASStreamThread *streamThread;
@property (assign, nonatomic) IBOutlet UITableViewCell *customCell;

@end
