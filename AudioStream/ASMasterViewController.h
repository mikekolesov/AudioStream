//
//  ASMasterViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASDetailViewController;

@interface ASMasterViewController : UITableViewController

@property (strong, nonatomic) ASDetailViewController *detailViewController;

@end
