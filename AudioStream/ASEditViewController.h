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

@interface ASEditViewController : UIViewController <UITextFieldDelegate>
{
    NSTimer *timer;
    UIView *noKeyboard;
    UIBarButtonItem * saveButton;
}

- (IBAction) soundCheck: (id) sender;
- (IBAction) doneKeyboard:(id)sender;

@property (strong, nonatomic) IBOutlet UITextField *streamName;
@property (strong, nonatomic) IBOutlet UITextField *streamURLString;
@property (strong, nonatomic) IBOutlet UIButton *checkButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) ASDataModel *dataModel;
@property (strong, nonatomic) ASStreamThread *streamThread;

@end
