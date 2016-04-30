//
//  VideoPlayViewController.m
//  VideoMaker
//
//  Created by sergey on 11/12/15.
//  Copyright © 2015 sergey. All rights reserved.
//

#import "VideoPlayViewController.h"

@interface VideoPlayViewController ()

@end

@implementation VideoPlayViewController
@synthesize theMoviPlayer;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self playComposedVideo];
}

- (void) playComposedVideo {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *composedVideo =  [NSString stringWithFormat:@"%@/compose.mp4",documentsDirectory];

    NSURL *mergeUrl = [NSURL fileURLWithPath:composedVideo];
    
    theMoviPlayer = [[MPMoviePlayerController alloc] initWithContentURL:mergeUrl];
    
    theMoviPlayer.controlStyle = MPMovieControlStyleFullscreen;
    
    
    [theMoviPlayer.view setFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:[self theMoviPlayer]];
    NSError *_error = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &_error];
    
    [self.view addSubview:theMoviPlayer.view];
    [theMoviPlayer play];
    
}

-(void)movieFinishedCallback:(NSNotification*)notification
{
    MPMoviePlayerController *moviePlayer = [notification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:moviePlayer];
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
