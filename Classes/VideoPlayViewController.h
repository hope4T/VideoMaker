//
//  VideoPlayViewController.h
//  VideoMaker
//
//  Created by sergey on 11/12/15.
//  Copyright © 2015 sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVAudioSession.h>

@interface VideoPlayViewController : UIViewController

@property (nonatomic, retain) MPMoviePlayerController *theMoviPlayer;

@end
