//
//  ASDetailViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASDataModel.h"
#import "ASStreamThread.h"

@class ASEditViewController;

@interface ASDetailViewController : UIViewController <UISplitViewControllerDelegate>
{
    NSTimer *timer;
}

- (IBAction) playOrStop:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *playStopButton;
@property (strong, nonatomic) IBOutlet UILabel *streamTitleLabel;
@property (strong, nonatomic) ASEditViewController *editViewController;
@property (strong, nonatomic) ASDataModel *dataModel;
@property (strong, nonatomic) IBOutlet UILabel *streamName;
@property (strong, nonatomic) IBOutlet UILabel *streamBitRate;
@property (strong, nonatomic) IBOutlet UILabel *streamFormat;
@property (strong, nonatomic) ASStreamThread *streamThread;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UIView *volumeView;

@end
