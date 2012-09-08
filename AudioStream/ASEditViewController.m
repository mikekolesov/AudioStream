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
@synthesize checkButton;

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

- (void) timerCallback
{
    ASAppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    // check audio part state
    if ( !(app.streamThread.preparing || app.streamThread.finishing) ) {
        [timer invalidate];
        D1 NSLog(@"Timer invalidated");
        checkButton.enabled = TRUE;
        D1 NSLog(@"Check button enabled");
    }
    else {
        D1 NSLog(@"Timer goes on... preparing %d, finishing %d", app.streamThread.preparing, app.streamThread.finishing);
    }
}

- (IBAction) soundCheck: (id) sender
{
    ASAppDelegate *app = [[UIApplication sharedApplication] delegate];
    
    
    checkButton.enabled = NO;
    
    D1 NSLog(@"Button disabled");
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
    D1 NSLog(@"Timer added");
    
    
    if (app.streamThread.playing) { // getting stop
        [app.streamThread stop];
        [checkButton setTitle:@"Sound Check" forState: UIControlStateNormal];
    }
    else
    {
        [app.streamThread startWithURL:[streamURLString text]];
        [checkButton setTitle:@"Stop" forState: UIControlStateNormal];
    }
}

- (IBAction) doneKeyboard:(id)sender
{
    [sender resignFirstResponder];
}

@end
