//
//  TransationVideoMaker.h
//  TriangleImage
//
//  Created by Lucky on 11/11/15.
//  Copyright © 2015 Lucky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAsset.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

#import <Foundation/Foundation.h>
@protocol VideoMakerDelegate <NSObject>

- (void) finished;
- (void) failed;

@end
@interface TransitionVideoMaker : NSObject
{
    NSString *documentsDirectory;
    NSString *backgroundPath, *overlayPath, *splashVideo, *transitionVideo;
    NSString *backgoundVideoPath, *pipVideoPath,*composeVideoPath, *waterImagePath;
    NSString *thumbnail;
    NSString *previousVideo, *pipBackVideo, * waterMarkVideoPath;
    
    AVURLAsset *Asset1, *Asset2;
    AVURLAsset *backAsset, *pipAsset;
    
    CGFloat screenWidth, screenHeight;
    
    BOOL isComposedPreviousVideo;

}

@property (nonatomic, assign) id <VideoMakerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

- (id) init;
- (id) initWith:(UIImage *) bgImgPath OverlayImagePath:(UIImage *) overlayImgPath WaterImagePath:(UIImage *) waterImgPath backgroundVideo:(NSString *) backVideo pipVideo:(NSString *) pipVideo composeVideo:(NSString *)composeVideo;
- (void) start;

@end
