//
//  ViewController.m
//  MacAudioStream
//
//  Created by MKolesov on 22/12/15.
//  Copyright © 2015 Michael Kolesov. All rights reserved.
//

#import "ViewController.h"
#import "AudioStreamEngine.h"

@interface ViewController () <AudioStreamEngineDelegate>
@property (weak) IBOutlet NSTextField *titleLabel;
@property (nonatomic, strong) AudioStreamEngine *audioStreamEngine;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.audioStreamEngine = [AudioStreamEngine sharedInstance];
    self.audioStreamEngine.delegate = self;
    
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)startAction:(id)sender {
    
    if (self.audioStreamEngine.playing == NO) {
        [self.audioStreamEngine startWithURL:@"http://air.radiorecord.ru:8101/rr_128"];
    }
    
}

- (IBAction)stopAction:(id)sender {
    [self.audioStreamEngine stop];
}

#pragma mark - AudioStreamEngineDelegate

-(void) audioStreamEngineDidUpdateTitle:(NSString *)title
{
    [self.titleLabel setStringValue:title];
}

@end
