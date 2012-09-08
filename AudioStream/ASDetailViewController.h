//
//  ASDetailViewController.h
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ASEditViewController;

@interface ASDetailViewController : UIViewController <UISplitViewControllerDelegate>

- (IBAction) playOrStop:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *playStopButton;
@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@property (strong, nonatomic) ASEditViewController *editViewController;

@end
