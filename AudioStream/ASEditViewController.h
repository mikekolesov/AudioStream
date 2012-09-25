//
//  ASEditViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/21/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASStreamThread.h"
#import "ASDataModel.h"

@interface ASEditViewController : UIViewController
{
    NSTimer *timer;
}

- (IBAction) soundCheck: (id) sender;
- (IBAction) doneKeyboard:(id)sender;

@property (retain, nonatomic) IBOutlet UITextField *streamName;
@property (retain, nonatomic) IBOutlet UITextField *streamURLString;
@property (retain, nonatomic) IBOutlet UIButton *checkButton;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) ASDataModel *dataModel;
@property (strong, nonatomic) ASStreamThread *streamThread;

@end
