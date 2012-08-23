//
//  ASEditViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 8/21/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASEditViewController : UIViewController

- (IBAction) soundCheck: (id) sender;
- (IBAction) doneKeyboard:(id)sender;

@property (retain, nonatomic) IBOutlet UITextField *streamURLString;


@end
