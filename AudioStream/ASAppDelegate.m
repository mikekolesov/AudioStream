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

@synthesize dataModel;
@synthesize streamThread;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // alloc data model
    dataModel = [[ASDataModel alloc] init];
    
    // alloc and setup stream
    streamThread = [[ASStreamThread alloc] init];
    streamThread.dataModel = dataModel;
    [streamThread setupStream];

    // set up audio session
    
    
//    CheckError(AudioSessionInitialize(NULL,
//                                      kCFRunLoopDefaultMode,
//                                      MyInterruptionListener,
//                                      (__bridge void *)(self.streamThread)),
//               "couldn't initialize audio session");
//    
//    UInt32 category = kAudioSessionCategory_MediaPlayback;
//    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
//                                       sizeof(category),
//                                       &category),
//               "Couldn't set category on audio session");


    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   
    ASMasterViewController *masterViewController = [[ASMasterViewController alloc] initWithNibName:@"ASMasterViewController_iPhone" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    ASDetailViewController *detailViewController = [[ASDetailViewController alloc] initWithNibName:@"ASDetailViewController_iPhone" bundle:nil];
    
    masterViewController.detailViewController = detailViewController;
    masterViewController.dataModel = dataModel;
    masterViewController.streamThread = streamThread;
    [dataModel addObserver:masterViewController forKeyPath:@"startPlaying" options:0 context:NULL];
    [dataModel addObserver:masterViewController forKeyPath:@"resetPlaying" options:0 context:NULL];
    
    detailViewController.dataModel = dataModel;
    detailViewController.streamThread = streamThread;
    [dataModel addObserver:detailViewController forKeyPath:@"objectTitle" options:0 context:NULL];
    [dataModel addObserver:detailViewController forKeyPath:@"startPlaying" options:0 context:NULL];
    [dataModel addObserver:detailViewController forKeyPath:@"resetPlaying" options:0 context:NULL];
    
    ASEditViewController *evc = [[ASEditViewController alloc] initWithNibName:@"ASEditViewController" bundle:nil];
    evc.dataModel = dataModel;
    evc.streamThread = streamThread;
    masterViewController.detailViewController.editViewController = evc;
    
    self.window.rootViewController = self.navigationController;
   
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
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.    
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
//static void CheckError(OSStatus error, const char *operation)
//{
//	if (error == noErr) return;
//	
//	char str[20];
//	// see if it appears to be a 4-char-code
//	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
//	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
//		str[0] = str[5] = '\'';
//		str[6] = '\0';
//	} else
//		// no, format it as an integer
//		sprintf(str, "%d", (int)error);
//    
//	fprintf(stderr, "Error: %s (%s)\n", operation, str);
//
//}
//
//static void MyInterruptionListener (void *inUserData, UInt32 inInterruptionState) {
//	
//    ASStreamThread *stream = (__bridge ASStreamThread *) inUserData;
//    
//	printf ("Interrupted! inInterruptionState=%u\n", (unsigned int)inInterruptionState);
//    
//    
//	switch (inInterruptionState) {
//		case kAudioSessionBeginInterruption:
//            printf("kAudioSession_Begin_Interruption\n");
//            [stream stop];
//            break;
//            
//		case kAudioSessionEndInterruption:
//            printf("kAudioSession_End_Interruption\n");
//
//            NSLog(@"set allow mixing");
//            stream.allowMixing = TRUE;
//            
//            [stream startWithURL: stream.urlString];
//
//            break;
//            
//		default:
//			break;
//	};
//}
//

@end
