//
//  ViewController.h
//  VideoMaker
//
//  Created by sergey on 11/11/15.
//  Copyright © 2015 sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransitionVideoMaker.h"

@interface ViewController : UIViewController<UINavigationControllerDelegate,UIImagePickerControllerDelegate, VideoMakerDelegate>
{
    UIImage* BackgroundImage;
    UIImage* OverlayImage;
    UIImage* watermarkImage;
    NSString* PIPVideo;
    NSString* BackgroundVideo;
    
    NSString* composeVideo;
    
    CGFloat   screenWidth;
    CGFloat   screenHeight;
    UIButton* createButton;

}

@end

