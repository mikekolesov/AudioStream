//
//  ASEditViewController.m
//  AudioStream
//
//  Created by Michael Kolesov on 8/21/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASEditViewController.h"
#import "ASAppDelegate.h"

@interface ASEditViewController ()

@end



@implementation ASEditViewController

@synthesize streamURLString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) soundCheck: (id) sender
{
    ASAppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app.streamThread startWithURL:[streamURLString text]];   
}

- (IBAction) doneKeyboard:(id)sender
{
    [sender resignFirstResponder];
}

@end
