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
        
        // pre-setup save button
        saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(saveSettings)];
    }
    return self;
}

- (void) saveSettings
{
    if ([dataModel isSelectedObjectPlaying]) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Operation Not Permited" message:@"Stop this stream \nbefore changing its settings" delegate:self cancelButtonTitle: @"Dismiss" otherButtonTitles: nil] autorelease];
        [alert show];
        return;
    }
    
    int selectedIndex = [dataModel indexOfSelectedObject];
    
    // modify data if needed
    
    NSString *storeName = [dataModel valueForKey:@"StreamName" atObjectByIndex:selectedIndex];
    NSString *fieldName = [streamName text];
    if (![storeName isEqualToString:fieldName]) {
        [dataModel setValue:fieldName forKey:@"StreamName" atObjectByIndex:selectedIndex];
        dataModel.isModified = YES;
    }
    
    NSString *storeURL = [dataModel valueForKey:@"StreamURL" atObjectByIndex:selectedIndex];
    NSString *fieldURL= [streamURLString text];
    if (![storeURL isEqualToString:fieldURL]) {
        [dataModel setValue:fieldURL forKey:@"StreamURL" atObjectByIndex:selectedIndex];
        dataModel.isModified = YES;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    streamName.delegate = self;
    streamURLString.delegate = self;
    noKeyboard = [[UIView alloc] initWithFrame:CGRectZero]; 
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [noKeyboard release];
    [saveButton release];
}

- (void) viewWillAppear:(BOOL)animated
{
    int selectedIndex = [dataModel indexOfSelectedObject];
    [streamName setText:[dataModel valueForKey:@"StreamName" atObjectByIndex:selectedIndex]];
    [streamURLString setText:[dataModel valueForKey:@"StreamURL" atObjectByIndex:selectedIndex]];
    
    // setup keyboard and save button appearance 
    if ([dataModel isSelectedObjectPlaying]) {
        streamName.inputView = noKeyboard;
        streamURLString.inputView = noKeyboard;
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        streamName.inputView = nil;
        streamURLString.inputView = nil;
        self.navigationItem.rightBarButtonItem = saveButton;
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    if (!([streamName isFirstResponder] || [streamURLString isFirstResponder])) {
        // make streamName default responder
        [streamName becomeFirstResponder];
    }
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


- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // prevent changing if in playing state
    if ([dataModel isSelectedObjectPlaying]) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Operation Not Permited" message:@"Stop stream to change settings" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil] autorelease];
        [alert show];
        return NO;
    }
    else {
        return YES;
    }
}


@end
