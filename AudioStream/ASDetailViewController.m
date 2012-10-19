//
//  ASDetailViewController.m
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASDetailViewController.h"
#import "ASEditViewController.h"

@interface ASDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
//- (void)configureView;
@end

@implementation ASDetailViewController

@synthesize playStopButton;
@synthesize streamTitleLabel;
@synthesize dataModel;
@synthesize streamName;
@synthesize streamThread;
@synthesize editViewController;
@synthesize activity;
@synthesize streamBitRate;
@synthesize streamFormat;
@synthesize volumeView;

- (void)dealloc
{
    [editViewController release];
    //[_detailItem release];
    //[_detailDescriptionLabel release];
    [_masterPopoverController release];
    [dataModel release];
    [streamThread release];
    [super dealloc];
    NSLog(@"DetailViewController dealloc");
}

#pragma mark - Managing the detail item

/*
- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        [_detailItem release];
        _detailItem = [newDetailItem retain];

        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // setup system volume slider
    NSArray *subviewArray = [volumeView subviews];
    for (id arrayItem in subviewArray) {
        if ([arrayItem isKindOfClass:[UISlider class]]) {
            UISlider *volumeSlider = arrayItem;
            
            // customize slider to default images
            [volumeSlider setThumbImage:nil forState:UIControlStateNormal];
            [volumeSlider setThumbImage:nil forState:UIControlStateDisabled];
            [volumeSlider setMinimumTrackImage:nil forState:UIControlStateNormal];
            [volumeSlider setMinimumTrackImage:nil forState:UIControlStateDisabled];
            [volumeSlider setMaximumTrackImage:nil forState:UIControlStateNormal];
            [volumeSlider setMaximumTrackImage:nil forState:UIControlStateDisabled];
        }
    }
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
}

- (void) viewWillAppear:(BOOL)animated
{
    int selectedIndex = [dataModel indexOfSelectedObject];
    [streamName setText:[dataModel valueForKey:@"StreamName" atObjectByIndex:selectedIndex]];
    
    if ([dataModel isSelectedObjectPlaying]) {
        [streamTitleLabel setText:streamThread.streamTitle];
        [playStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        [streamBitRate setText:streamThread.bitRate];
        [streamFormat setText:streamThread.contentType];
    }
    else {
        [streamTitleLabel setText:@"..."];
        [playStopButton setTitle:@"Play" forState:UIControlStateNormal];
        [streamBitRate setText:@"..."];
        [streamFormat setText:@"..."];
    }
        
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    /*if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }*/
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Station";
        
        // change back title
        UIBarButtonItem *bb = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
        self.navigationItem.backBarButtonItem = bb;
        
        UIBarButtonItem * settingsButton = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editSettings)] autorelease];
        self.navigationItem.rightBarButtonItem = settingsButton;
    }
    return self;
}
	
-(void) editSettings
{
    [self.navigationController pushViewController:self.editViewController animated:YES];
}


#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (void) timerCallback
{
    // check audio part state
    if ( !(streamThread.preparing || streamThread.finishing) ) {
        [timer invalidate];
        NSLog(@"Timer invalidated");
        playStopButton.enabled = TRUE;
        NSLog(@"Check button enabled");
        
        if (streamThread.playing) {
            [streamTitleLabel setText:streamThread.streamTitle];
            [playStopButton setTitle:@"Stop" forState: UIControlStateNormal];
            [streamBitRate setText: streamThread.bitRate];
            [streamFormat setText: streamThread.contentType];
        }
        else
            [playStopButton setTitle:@"Play" forState: UIControlStateNormal];
        
        [activity stopAnimating];
        playStopButton.hidden = NO;
    }
    else {
        NSLog(@"Timer goes on... preparing %d, finishing %d", streamThread.preparing, streamThread.finishing);
    }
}

- (IBAction) playOrStop:(id)sender
{
    playStopButton.enabled = NO;
    
    NSLog(@"Button disabled");
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
    NSLog(@"Timer added");
    
    playStopButton.hidden = YES;
    [activity startAnimating];
    
    int selectedIndex = [dataModel indexOfSelectedObject];

    if (streamThread.playing) {
        
        if ([dataModel isSelectedObjectPlaying])
            [streamThread stop];
        else {
            [streamThread stop];
            [streamThread startWithURL:[dataModel valueForKey:@"StreamURL" atObjectByIndex:selectedIndex]];
        }
    }
    else {
        [streamThread startWithURL:[dataModel valueForKey:@"StreamURL" atObjectByIndex:selectedIndex]];
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"Heard the var change, by DetailViewController");
    NSLog(@"Is Main thread? %d", [[NSThread currentThread] isMainThread] );
    
    if ([keyPath isEqualToString:@"objectTitle"]) {
        NSString *title = [object valueForKey:keyPath];
        NSLog(@"objectTitle: %@",title);
        if ([dataModel isSelectedObjectPlaying])
            [streamTitleLabel setText:title];
    }
    else if ([keyPath isEqualToString:@"resetPlaying"]) {
        NSLog(@"resetPlaying");
        [streamTitleLabel setText:@"..."];
        [playStopButton setTitle:@"Play" forState:UIControlStateNormal];
        [streamBitRate setText:@"..."];
        [streamFormat setText:@"..."];
    }
    else if ([keyPath isEqualToString:@"startPlaying"]) {
        NSLog(@"startPlaying");
        if ([dataModel isSelectedObjectPlaying]) {
            [streamTitleLabel setText:streamThread.streamTitle];
            [playStopButton setTitle:@"Stop" forState: UIControlStateNormal];
            [streamBitRate setText: streamThread.bitRate];
            [streamFormat setText: streamThread.contentType];
        }
    }

    else {
        // some another
    }
   
}

 
@end
