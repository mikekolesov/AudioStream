//
//  ASEditViewController.m
//  AudioStream
//
//  Created by Michael Kolesov on 8/21/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASEditViewController.h"
#import "ASAppDelegate.h"


@implementation ASEditViewController

@synthesize streamName;
@synthesize streamURLString;
@synthesize checkButton;
@synthesize activity;
@synthesize dataModel;
@synthesize streamThread;

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

- (void) viewWillAppear:(BOOL)animated
{
    if ([dataModel isSelectedObjectPlaying]) {
        [checkButton setTitle:@"Stop" forState:UIControlStateNormal];
        // + sibscribe to streamTitle updates
    } else {
        [checkButton setTitle:@"Sound Check" forState:UIControlStateNormal];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    // unsibscribe of streamTitle updates
}

- (void) viewDidAppear:(BOOL)animated
{
    [streamName becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) timerCallback
{    
    // check audio part state
    if ( !(streamThread.preparing || streamThread.finishing) ) {
        [timer invalidate];
        NSLog(@"Timer invalidated");
        checkButton.enabled = TRUE;
        NSLog(@"Check button enabled");
        
        if (streamThread.playing)
            [checkButton setTitle:@"Stop" forState: UIControlStateNormal];
        else
            [checkButton setTitle:@"Sound Check" forState: UIControlStateNormal];

        [activity stopAnimating];
        checkButton.hidden = NO;
        
    }
    else {
    NSLog(@"Timer goes on... preparing %d, finishing %d", streamThread.preparing, streamThread.finishing);
    }
}

- (IBAction) soundCheck: (id) sender
{    
    
    checkButton.enabled = NO;
    
    NSLog(@"Button disabled");
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
    NSLog(@"Timer added");
    
    checkButton.hidden = YES;
    [activity startAnimating];
        
    
    if (streamThread.playing) {
        
        if ([dataModel isSelectedObjectPlaying])
            [streamThread stop];
        else {
            [streamThread stop];
            [streamThread startWithURL:[streamURLString text]];
        }
    }
    else
        [streamThread startWithURL:[streamURLString text]];
}

- (IBAction) doneKeyboard:(id)sender
{
    [sender resignFirstResponder];
}

@end
