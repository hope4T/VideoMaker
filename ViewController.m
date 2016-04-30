//
//  ViewController.m
//  VideoMaker
//
//  Created by sergey on 11/11/15.
//  Copyright © 2015 sergey. All rights reserved.
//

#import "ViewController.h"
#import "VideoPlayViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initParams];
    
    [self cleanVideoPath];
    
    [self createButton];
    
}

- (void) initParams {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    
    BackgroundImage = [UIImage imageNamed:@"BackgroundImage.jpg"];
    OverlayImage = [UIImage imageNamed:@"OverlayImage.png"];
    watermarkImage = [UIImage imageNamed:@"WatermarkImage.png"];

    PIPVideo =  [[NSBundle mainBundle] pathForResource:@"PIPVideo" ofType:@"MOV"];
    BackgroundVideo =  [[NSBundle mainBundle] pathForResource:@"BackgroundVideo" ofType:@"MOV"];
    composeVideo =  [NSString stringWithFormat:@"%@/compose.mp4",documentsDirectory];
}

- (void) cleanVideoPath {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:composeVideo]) {
        NSError* error;
        if ([fileManager removeItemAtPath:composeVideo error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }
    
}

- (void) createButton {
    createButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [createButton setTitle:@"Create" forState:UIControlStateNormal];
    [createButton setFrame:CGRectMake(screenWidth * 3 / 10, screenHeight * 3 / 10, screenWidth * 4 /10, screenHeight / 5)];
    [createButton.titleLabel setFont:[UIFont systemFontOfSize:30]];
    [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [createButton addTarget:self action:@selector(makeVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:createButton];
}

- (void) makeVideo {
    [createButton setHidden:YES];
    
    TransitionVideoMaker *transition = [[TransitionVideoMaker alloc] initWith:BackgroundImage OverlayImagePath:OverlayImage  WaterImagePath:watermarkImage backgroundVideo:BackgroundVideo pipVideo:PIPVideo composeVideo:composeVideo];
    transition.delegate = self;
    [transition start];
}

- (void) finished{

    [self playComposedVideo];
    
}

- (void) playComposedVideo {
    VideoPlayViewController *videoController = [[VideoPlayViewController alloc] initWithNibName:@"VideoPlayViewController" bundle:nil];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 1.0;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    
    [self presentViewController:videoController animated:YES completion:^{}];
}

- (void) failed{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
