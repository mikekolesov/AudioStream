//
//  ASAppDelegate.m
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASAppDelegate.h"

#import "ASMasterViewController.h"

#import "ASDetailViewController.h"

#import "ASEditViewController.h"


@implementation ASAppDelegate

- (void)dealloc
{
    [_window release];
    [_navigationController release];
    [_splitViewController release];
    [_streamThread release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // set up audio session
    CheckError(AudioSessionInitialize(NULL,
                                      kCFRunLoopDefaultMode,
                                      MyInterruptionListener,
                                      self),
               "couldn't initialize audio session");
    
    UInt32 category = kAudioSessionCategory_MediaPlayback;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                       sizeof(category),
                                       &category),
               "Couldn't set category on audio session");

    
    // stream alloc
    self.streamThread = [[ASStreamThread alloc] init];
    

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        ASMasterViewController *masterViewController = [[[ASMasterViewController alloc] initWithNibName:@"ASMasterViewController_iPhone" bundle:nil] autorelease];
        self.navigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        ASDetailViewController *detailViewController = [[[ASDetailViewController alloc] initWithNibName:@"ASDetailViewController_iPhone" bundle:nil] autorelease];
        
        masterViewController.detailViewController = detailViewController;
        
        ASEditViewController *evc = [[[ASEditViewController alloc] initWithNibName:@"ASEditViewController" bundle:nil] autorelease];
        masterViewController.detailViewController.editViewController = evc;
        
        self.window.rootViewController = self.navigationController;
    } else {
        ASMasterViewController *masterViewController = [[[ASMasterViewController alloc] initWithNibName:@"ASMasterViewController_iPad" bundle:nil] autorelease];
        UINavigationController *masterNavigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        
        ASDetailViewController *detailViewController = [[[ASDetailViewController alloc] initWithNibName:@"ASDetailViewController_iPad" bundle:nil] autorelease];
        UINavigationController *detailNavigationController = [[[UINavigationController alloc] initWithRootViewController:detailViewController] autorelease];
    	
    	masterViewController.detailViewController = detailViewController;
    	
        self.splitViewController = [[[UISplitViewController alloc] init] autorelease];
        self.splitViewController.delegate = detailViewController;
        self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
        
        self.window.rootViewController = self.splitViewController;
    }
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
   
    // set alive handler for voip socket (for sure)
    // + info.plist has been set with audio and voip background keys
    BOOL backAlive = [[UIApplication sharedApplication] setKeepAliveTimeout: 600.0 handler: ^{
        NSLog(@"keepAliveHandler called");
        }];
    
    if ( backAlive ) {
        NSLog(@"setKeepAliveTimeout handler set");
    }
    else {
        NSLog(@"setKeepAliveTimeout handler not set");
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    // unset voip alive handler
    NSLog(@"clearKeepAliveTimeout");
    [[UIApplication sharedApplication] clearKeepAliveTimeout];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// generic error handler - if err is nonzero, prints error message
static void CheckError(OSStatus error, const char *operation)
{
	if (error == noErr) return;
	
	char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)error);
    
	fprintf(stderr, "Error: %s (%s)\n", operation, str);

}

static void MyInterruptionListener (void *inUserData, UInt32 inInterruptionState) {
	
    ASAppDelegate *app = (ASAppDelegate *)inUserData;
    
	printf ("Interrupted! inInterruptionState=%ld\n", inInterruptionState);
    
    
	switch (inInterruptionState) {
		case kAudioSessionBeginInterruption:
            printf("kAudioSession_Begin_Interruption\n");
            [app.streamThread stop];
            break;
            
		case kAudioSessionEndInterruption:
            printf("kAudioSession_End_Interruption\n");

            NSLog(@"set allow mixining");
            app.streamThread.allowMixing = TRUE;
            
            [app.streamThread startWithURL: app.streamThread.urlString];

            break;
            
		default:
			break;
	};
}


@end
