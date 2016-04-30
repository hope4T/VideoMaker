//
//  TransationVideoMaker.m
//  TriangleImage
//
//  Created by Lucky on 11/11/15.
//  Copyright © 2015 Lucky. All rights reserved.
//

#import "TransitionVideoMaker.h"
#import <AVFoundation/AVFoundation.h>

#define FRAMECNT_PER_SECOND (24.0)
#define PIECE_CNT (4)
#define VIDEO_SIZE CGSizeMake(640, 960)
#define TMP_PATH_BGVIDEO @"/Documents/bgScreenVideo.mov"
#define TMP_PATH_FORMAT_CROP_IMAGE @"/Documents/pieceImage%d.png"
#define TMP_PATH_FORMAT_MOTION_IMAGE @"/Documents/motionImage%d.png"


@implementation TransitionVideoMaker
@synthesize delegate;
@synthesize activityView;
- (id) init{
    self = [super init];
    if(self)
    {
        backgroundPath = @"";
        overlayPath = @"";
        splashVideo = @"";
        transitionVideo = @"";
        thumbnail = @"";
        backgoundVideoPath = @"";
        pipVideoPath = @"";
        previousVideo = @"";
        pipBackVideo = @"";
        composeVideoPath = @"";
        waterImagePath = @"";
        waterMarkVideoPath = @"";
        return self;
    }
    return nil;
}

- (id) initWith:(UIImage *)bgImgPath OverlayImagePath:(UIImage *)overlayImgPath WaterImagePath:(UIImage *)waterImgPath backgroundVideo:(NSString *)backVideo pipVideo:(NSString *)pipVideo composeVideo:(NSString *)composeVideo {
    
    self = [super init];
    
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths objectAtIndex:0];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        screenWidth = screenRect.size.width;
        screenHeight = screenRect.size.height;
        
        NSData *bgImgData = UIImagePNGRepresentation(bgImgPath);
        backgroundPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"backgroundImage.png"];
        [UIImagePNGRepresentation([UIImage imageWithData:bgImgData]) writeToFile:backgroundPath atomically:YES];
        
        NSData *ovImgData = UIImagePNGRepresentation(overlayImgPath);
        overlayPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"overlayImage.png"];
        [UIImagePNGRepresentation([UIImage imageWithData:ovImgData]) writeToFile:overlayPath atomically:YES];

        waterImagePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"waterImage"];
        [UIImagePNGRepresentation(waterImgPath) writeToFile:waterImagePath atomically:YES];
        
        backgoundVideoPath = backVideo;
        pipVideoPath = pipVideo;
        composeVideoPath = composeVideo;
        
        waterMarkVideoPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"waterMarkVideo.mp4"];
        splashVideo = [NSString stringWithFormat:@"%@%@%@", NSTemporaryDirectory(), @"splash", @".mp4"];
        transitionVideo = [NSString stringWithFormat:@"%@%@%@", NSTemporaryDirectory(), @"transition", @".mp4"];

        previousVideo = [NSString stringWithFormat:@"%@%@%@", NSTemporaryDirectory(), @"previousVideo", @".mp4"];
        pipBackVideo = [NSString stringWithFormat:@"%@%@%@", NSTemporaryDirectory(), @"pipBackVideo", @".mp4"];

        thumbnail = [self getThumbnail:backVideo];
        
        isComposedPreviousVideo = FALSE;
        
        return self;
    }
    
    return nil;
    
    
}

- (NSString *) getThumbnail:(NSString *)videoPath {
    NSURL *videoUrl = [NSURL fileURLWithPath:videoPath];
    
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    
    AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:sourceAsset];
    
    //Get the 1st frame 3 seconds in
    int frameTimeStart = 3;
    int frameLocation = 1;
    
    CGImageRef frameRef = [generator copyCGImageAtTime:CMTimeMake(frameTimeStart,frameLocation) actualTime:nil error:nil];

    UIImage *thumbImage = [UIImage imageWithCGImage:frameRef];
    
    NSData *pngData = UIImagePNGRepresentation(thumbImage);
    NSString *filePath = [NSString stringWithFormat:@"%@%@%@", NSTemporaryDirectory(), @"thumb", @".png"]; //Add the file name
    [UIImagePNGRepresentation([UIImage imageWithData:pngData]) writeToFile:filePath atomically:YES];
    
    return filePath;
    
}

- (void) start{
    [self MakeVideo];
}

- (UIImage *)maskImage:(UIImage *)originalImage toPath:(UIBezierPath *)path {
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, 0);
    [path addClip];
    [originalImage drawAtPoint:CGPointZero];
    UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return maskedImage;
}

- (void) saveFourPieceImages:(UIImage *) orgImage
{
    float posInfo[PIECE_CNT][3][2] = {  {{0, 0}, {1, 0}, {0.5, 0.5}},
        {{0, 1}, {1, 1}, {0.5, 0.5}},
        {{1, 0}, {1, 1}, {0.5, 0.5}},
        {{0, 0}, {0, 1}, {0.5, 0.5}}};
    
    UIBezierPath *trianglePath = [UIBezierPath new];
    float plusX = 0.0, plusY = 0.0;
    for (int i = 0; i < PIECE_CNT; i++){
        if(i != 0)  [trianglePath removeAllPoints];
        if(i < 2){
            plusX = 1;
            if( i == 0)
                plusY = 2;
            else
                plusY = -2;
        }
        [trianglePath moveToPoint:(CGPoint){posInfo[i][0][0] * orgImage.size.width - plusX, posInfo[i][0][1] * orgImage.size.height}];
        [trianglePath addLineToPoint:(CGPoint){posInfo[i][1][0] * orgImage.size.width + plusX, posInfo[i][1][1] * orgImage.size.height}];
        [trianglePath addLineToPoint:(CGPoint){posInfo[i][2][0] * orgImage.size.width, posInfo[i][2][1] * orgImage.size.height + plusY}];
        
        UIImage *croppedImage = [self maskImage:orgImage toPath:trianglePath];
        
        NSString *tempFilePath = [NSString stringWithFormat:TMP_PATH_FORMAT_CROP_IMAGE, i];
        NSString *path = [NSHomeDirectory() stringByAppendingString:tempFilePath];
        [UIImagePNGRepresentation(croppedImage) writeToFile:path atomically:YES];
        NSLog(@"cropped image path: %@",path);
        croppedImage = nil;
        plusX = 0.0, plusY = 0.0;
    }
}

- (void)createVideo:(int) imgCount PathFormat:(NSString *) pathFormat Duration:(int) secDur OutputPath:(NSString *) videoOutputPath;
{
    NSError *error = nil;
    NSFileManager *fileMgr = [NSFileManager defaultManager];

    if ([fileMgr removeItemAtPath:videoOutputPath error:&error] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:videoOutputPath] fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(videoWriter);
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:VIDEO_SIZE.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:VIDEO_SIZE.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];              AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                                                                                                         assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                                                                                         sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    NSUInteger fps = 5;

    BOOL isSingleImg = FALSE;
    double numberOfFramesPerSec = 1;
    
    double snumberOfSecondsPerFrame = 1;
    double sframeDuration = fps * snumberOfSecondsPerFrame;
    if(imgCount == 1)
        isSingleImg = TRUE;
    
    int frameCount = 0, repeatCount = 0;
    
    if(!isSingleImg)
    {
        repeatCount = imgCount;
        numberOfFramesPerSec = FRAMECNT_PER_SECOND;
    }
    else
    {
        repeatCount = secDur;
        buffer = [self pixelBufferFromCGImage:[[UIImage imageNamed:pathFormat] CGImage]];
    }
    
    for(int i = 0; i < repeatCount; i++)
    {
        if(!isSingleImg)
            buffer = [self pixelBufferFromCGImage:[[UIImage imageNamed:[NSString stringWithFormat:pathFormat, i]] CGImage]];
        
        BOOL append_ok = NO;
        int j = 0;
        int jLimit = FRAMECNT_PER_SECOND;
        
        if(isSingleImg)
            jLimit = (int)fps;
        while (!append_ok && j < jLimit)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp %d\n", frameCount, j);
                
                CMTime frameTime;
                if(!isSingleImg)
                    frameTime = CMTimeMake(frameCount,(int32_t) numberOfFramesPerSec);
                else
                    frameTime = CMTimeMake(frameCount*sframeDuration,(int32_t) fps);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                
                if(!isSingleImg && (buffer))
                    CVBufferRelease(buffer);
                [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok) {
            [delegate failed];
            printf("error appending image %d times %d\n", frameCount, j);
            return;
        }
        frameCount++;
    }
    
    if(isSingleImg)
        CVBufferRelease(buffer);
    
    [videoWriterInput markAsFinished];
    
    [videoWriter finishWritingWithCompletionHandler:^{
        if (videoWriter.status != AVAssetWriterStatusFailed && videoWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"Complete Successfully");
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Failed!!!");
            });
        }
    }];
    videoWriter = nil;
    videoWriterInput = nil;
}


- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = @{
                              (__bridge NSString *)kCVPixelBufferCGImageCompatibilityKey: @(NO),
                              (__bridge NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(NO)
                              };
    CVPixelBufferRef pixelBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height,  kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pixelBuffer);
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, frameSize.width, frameSize.height,
                                                 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace,
                                                 (CGBitmapInfo) kCGImageAlphaNoneSkipFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

- (void) composeImage:(NSString *) firstPath SecondImagePath:(NSString *) secondPath TargetSize:(CGSize) targetSize OutputFileName:(NSString *) outputPath PieceIndex:(int) pIndex SubIndex:(int) sIndex{
    UIImage *firstImg    = [UIImage imageNamed:firstPath];
    UIImage *secondImg   = [UIImage imageNamed:secondPath];
    
    UIGraphicsBeginImageContext( targetSize );
    
    [firstImg drawInRect:CGRectMake(0,0,targetSize.width,targetSize.height)];
    
    if (pIndex == 0)
        [secondImg drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height / 11.0 * sIndex) blendMode:kCGBlendModeNormal alpha:1.0];
    else if (pIndex == 1)
        [secondImg drawInRect:CGRectMake(0, targetSize.height / 11.0 * (11 - sIndex), targetSize.width ,targetSize.height / 11.0 * sIndex ) blendMode:kCGBlendModeNormal alpha:1.0];
    else if (pIndex == 2)
        [secondImg drawInRect:CGRectMake(targetSize.width  / 11.0 * (11 - sIndex), 0, targetSize.width  / 11.0 * sIndex , targetSize.height) blendMode:kCGBlendModeNormal alpha:1.0];
    else if (pIndex == 3)
        [secondImg drawInRect:CGRectMake(0, 0, targetSize.width / 11.0 * sIndex,targetSize.height) blendMode:kCGBlendModeNormal alpha:1.0];
    else{ //Second Motion
        float targetRatio = 5.0; // 1/5
        float secondMotionScale = 1.0 / (FRAMECNT_PER_SECOND / (targetRatio - 1.0) * targetRatio) * (FRAMECNT_PER_SECOND / (targetRatio - 1.0) * (targetRatio + 1) - sIndex - FRAMECNT_PER_SECOND / (targetRatio - 1.0));
        [secondImg drawInRect:CGRectMake(0, 0, targetSize.width * secondMotionScale, targetSize.height  * secondMotionScale) blendMode:kCGBlendModeNormal alpha:1.0];
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    [UIImagePNGRepresentation(newImage) writeToFile:outputPath atomically:YES];
    UIGraphicsEndImageContext();
}

- (void) generateMotionTempFiles:(NSString *) bgImagePath thumbPath:(NSString *)thumb
{
    //First Motion
    
    NSString *lastPieceImgName = bgImagePath;
    for (int i = 0; i < 4; i++){
        for (int j = 0; j < FRAMECNT_PER_SECOND / 2; j++) {
            [self composeImage:lastPieceImgName SecondImagePath:[NSString stringWithFormat:[NSHomeDirectory() stringByAppendingString:TMP_PATH_FORMAT_CROP_IMAGE], i] TargetSize:VIDEO_SIZE OutputFileName:[NSString stringWithFormat:[NSHomeDirectory() stringByAppendingString:TMP_PATH_FORMAT_MOTION_IMAGE], (int)(i * FRAMECNT_PER_SECOND / 2 + j)] PieceIndex:i SubIndex:j];
            if( j == 11)
                lastPieceImgName = [NSString stringWithFormat:[NSHomeDirectory() stringByAppendingString:TMP_PATH_FORMAT_MOTION_IMAGE], (int)(i * FRAMECNT_PER_SECOND / 2 + j)];
        }
    }
    //Second Motion
    
    for (int i = 0; i < FRAMECNT_PER_SECOND; i ++) {
        [self composeImage:thumb SecondImagePath:lastPieceImgName TargetSize:VIDEO_SIZE OutputFileName:[NSString stringWithFormat:[NSHomeDirectory() stringByAppendingString:TMP_PATH_FORMAT_MOTION_IMAGE], (int)(4 * FRAMECNT_PER_SECOND / 2 + i)] PieceIndex:5 SubIndex:i];
    }
    
}

- (void) removeFile:(NSString *) filePath{
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if ([fileMgr removeItemAtPath:filePath error:&error] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
}

- (void) removeTmpFiles{
    //Remove CropedPiece Image
    for (int i = 0; i < PIECE_CNT; i++) {
        [self removeFile:[NSString stringWithFormat:[NSHomeDirectory() stringByAppendingString:TMP_PATH_FORMAT_CROP_IMAGE], i]];
    }
    
    //Remove motionTemp Files
    for (int i = 0; i < PIECE_CNT * FRAMECNT_PER_SECOND / 2 + FRAMECNT_PER_SECOND; i++) {
        [self removeFile:[NSString stringWithFormat:[NSHomeDirectory() stringByAppendingString:TMP_PATH_FORMAT_MOTION_IMAGE], i]];
    }
    
}

- (void) removeTempVideos {
   
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:splashVideo]) {
        NSError* error;
        if ([fileManager removeItemAtPath:splashVideo error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }
    
    if ([fileManager fileExistsAtPath:transitionVideo]) {
        NSError* error;
        if ([fileManager removeItemAtPath:transitionVideo error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }

    if ([fileManager fileExistsAtPath:previousVideo]) {
        NSError* error;
        if ([fileManager removeItemAtPath:previousVideo error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }
    
    if ([fileManager fileExistsAtPath:pipBackVideo]) {
        NSError* error;
        if ([fileManager removeItemAtPath:pipBackVideo error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }

}

- (void) MakeVideo{
    [self makeSplashVideo];
    [self makeTransitionVideo];
    [self makePreviousVideo];

}

- (void) makePreviousVideo {
    [self mergeVideo:splashVideo onVideo:transitionVideo finalVideo:previousVideo];

}

- (void) makePipBackVideo {
    [self composeVideo:pipVideoPath onVideo:backgoundVideoPath fileName:pipBackVideo];
    
}

- (void) makeComposeVideo {
    [self addWaterImageToVideo:pipBackVideo ImagePath:waterImagePath ExportPath:waterMarkVideoPath];
    
}

- (void) makeSplashVideo {
    // Create 2Second Video with Background Image
    [self saveFourPieceImages:[UIImage imageNamed:overlayPath]];
    [self createVideo:1 PathFormat:backgroundPath Duration:2 OutputPath:splashVideo];
}

- (void) makeTransitionVideo {
    [self generateMotionTempFiles:backgroundPath thumbPath:thumbnail];
    [self createVideo:PIECE_CNT * FRAMECNT_PER_SECOND / 2 + FRAMECNT_PER_SECOND PathFormat:[NSHomeDirectory() stringByAppendingString:TMP_PATH_FORMAT_MOTION_IMAGE] Duration:3 OutputPath:transitionVideo];
    [self removeTmpFiles];
}

- (void) addWaterImageToVideo:(NSString *) videoPath ImagePath:(NSString *) imgPath ExportPath:(NSString *) exportPath{
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:videoPath] options:nil];
    
    [activityView startAnimating];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero error:nil];
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }

    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
    
    AVAssetTrack *track = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize videoSize = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
    
    CGSize logoSize = CGSizeMake(videoSize.width * 0.3, videoSize.height * 0.2);
    
    UIImage *myImage = [UIImage imageNamed:imgPath];
    CALayer *aLayer = [CALayer layer];
    aLayer.contents = (id)myImage.CGImage;
    aLayer.frame = CGRectMake(videoSize.width - logoSize.width * 1.05, logoSize.height * 0.05, logoSize.width, logoSize.height); //Needed for proper display. We are using the app icon (57x57). If you use 0,0 you will not see it
    aLayer.opacity = 1.0; //Feel free to alter the alpha here
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:aLayer];
    
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    float scaleW = 1.0f;//VIDEO_SIZE.width / [[[videoAsset tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].width;
    float scaleH = 1.0f; //VIDEO_SIZE.height / [[[videoAsset tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].height;
    
    CGAffineTransform Scale = CGAffineTransformMakeScale(scaleW, scaleH);
    CGAffineTransform Move = CGAffineTransformMakeTranslation(0.0, 0.0);
    
    [layerInstruction setTransform:CGAffineTransformConcat(Scale, Move) atTime:kCMTimeZero];
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = VIDEO_SIZE;
    videoComp.instructions = [NSArray arrayWithObject: instruction];
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];

    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//AVAssetExportPresetPassthrough
    _assetExport.videoComposition = videoComp;
    
    //Add the file name
    NSURL    *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    _assetExport.outputFileType = AVFileTypeMPEG4;
    _assetExport.outputURL = exportUrl;
    _assetExport.shouldOptimizeForNetworkUse = YES;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         NSLog(@"WaterMark Success!!!");
         [self mergeVideo:previousVideo onVideo:waterMarkVideoPath finalVideo:composeVideoPath];
     }
     ];
    
    videoAsset = nil;
}

- (void) mergeVideo:(NSString*)firstVideo onVideo:(NSString*)secondVideo finalVideo:(NSString*)finalVideo
{
    @try {
        NSURL *path1 = [NSURL fileURLWithPath:firstVideo];
        
        NSURL *path2 = [NSURL fileURLWithPath:secondVideo];
        
        Asset1 = [[AVURLAsset alloc] initWithURL:path1 options:nil];
        Asset2 = [[AVURLAsset alloc] initWithURL:path2 options:nil];
        
        if (Asset1 !=nil && Asset2!=nil) {
            
            [activityView startAnimating];
            
            // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
            AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
            
            // 2 - Video track
            AVMutableCompositionTrack *firstTrack =
            [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                        preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, Asset1.duration)
                                ofTrack:[[Asset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                 atTime:kCMTimeZero
                                  error:nil];
            
            [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, Asset2.duration)
                                ofTrack:[[Asset2 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                 atTime:Asset1.duration
                                  error:nil];
            
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            if ([[Asset1 tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, Asset1.duration) ofTrack:[[Asset1 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            }
            
            if ([[Asset2 tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, Asset2.duration) ofTrack:[[Asset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:Asset1.duration error:nil];
            }
            
            //convert video size to VIDEO_SIZE
                        
            float scale_x1 = VIDEO_SIZE.width / [[[Asset1 tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].width;
            float scale_x2 = VIDEO_SIZE.width / [[[Asset2 tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].width;
            float scale_y1 = VIDEO_SIZE.height / [[[Asset1 tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].height;
            float scale_y2 = VIDEO_SIZE.height / [[[Asset2 tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].height;
            
            float scaleW = (scale_x1 > scale_x2) ? scale_x2 : scale_x1;
            float scaleH = (scale_y1 > scale_y2) ? scale_y2 : scale_y1;

            
            AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
            
            CGAffineTransform Scale = CGAffineTransformMakeScale(scaleW, scaleH);
            CGAffineTransform Move = CGAffineTransformMakeTranslation(0.0, 0.0);
            
            [layerInstruction setTransform:CGAffineTransformConcat(Scale, Move) atTime:kCMTimeZero];

            // Create an AVMutableVideoComposition object.
            AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
            MainCompositionInst.instructions = [NSArray arrayWithObject:layerInstruction];
            MainCompositionInst.frameDuration = CMTimeMake(1, 30);
            
            // Set the render size to the screen size.
            MainCompositionInst.renderSize = VIDEO_SIZE;
            
            // 4 - Get path
            NSURL *url = [NSURL fileURLWithPath:finalVideo];
            
            // 5 - Create exporter
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                              presetName:AVAssetExportPresetHighestQuality];
            exporter.outputURL=url;
            exporter.outputFileType = AVFileTypeMPEG4;
            exporter.shouldOptimizeForNetworkUse = YES;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (isComposedPreviousVideo) {
                        [self mergeExportDidFinish:exporter];
                        
                    } else {
                        isComposedPreviousVideo = TRUE;
                        [self makePipBackVideo];
                    }
                });
            }];
        }
        
        
    }
    @catch (NSException *ex) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@",ex]
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    
    
}

-(void)mergeExportDidFinish:(AVAssetExportSession*)session {
    
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        [self removeTempVideos];
                        [delegate finished];
                }
                });
            }];
        }
    }
    
    Asset1 = nil;
    Asset2 = nil;
    
    [activityView stopAnimating];
    
    
}


- (void) composeVideo:(NSString*)videoPIP onVideo:(NSString*)videoBG fileName:(NSString*)fileName
{
    @try {
        NSError *e = nil;
        
        // Load our 2 movies using AVURLAsset
        pipAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPIP] options:nil];
        backAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoBG] options:nil];

        [activityView startAnimating];
        
        float scaleW = VIDEO_SIZE.width / [[[backAsset tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].width;
        float scaleH = VIDEO_SIZE.height / [[[backAsset tracksWithMediaType:AVMediaTypeVideo ] objectAtIndex:0] naturalSize].height;

        // Create AVMutableComposition Object - this object will hold our multiple AVMutableCompositionTracks.
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        // Create the first AVMutableCompositionTrack by adding a new track to our AVMutableComposition.
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        // Set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to our newly created track at kCMTimeZero so video plays from the start of the track.
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, pipAsset.duration) ofTrack:[[pipAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:&e];
        if (e)
        {
            NSLog(@"Error0: %@",e);
            e = nil;
        }
        
        // Repeat the same process for the 2nd track and also start at kCMTimeZero so both tracks will play simultaneously.
        AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, backAsset.duration) ofTrack:[[backAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:&e];
        
        if (e)
        {
            NSLog(@"Error1: %@",e);
            e = nil;
        }
        
        // We also need the audio track!
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, backAsset.duration) ofTrack:[[backAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:&e];
        if (e)
        {
            NSLog(@"Error2: %@",e);
            e = nil;
        }
        
        
        // Create an AVMutableVideoCompositionInstruction object - Contains the array of AVMutableVideoCompositionLayerInstruction objects.
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        // Set Time to the shorter Asset.
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, (pipAsset.duration.value > backAsset.duration.value) ? pipAsset.duration : backAsset.duration);
        
        // Create an AVMutableVideoCompositionLayerInstruction object to make use of CGAffinetransform to move and scale our First Track so it is displayed at the bottom of the screen in smaller size.
        AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        
        CGAffineTransform Scale1 = CGAffineTransformMakeScale(0.3f,0.3f);
        
        
        // Top Left
        CGAffineTransform Move1 = CGAffineTransformMakeTranslation(3.0, 3.0);
        
        [FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale1,Move1) atTime:kCMTimeZero];
       
        // Repeat for the second track.
        AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
        
        CGAffineTransform Scale2 = CGAffineTransformMakeScale(scaleW, scaleH);
        
        CGAffineTransform Move2 = CGAffineTransformMakeTranslation(0.0, 0.0);
        
        [SecondlayerInstruction setTransform:CGAffineTransformConcat(Scale2, Move2) atTime:kCMTimeZero];
        
        // Add the 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction.
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction, SecondlayerInstruction, nil];
        
        // Create an AVMutableVideoComposition object.
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        MainCompositionInst.frameDuration = CMTimeMake(1, 30);
        
        
        // Set the render size to the screen size.
//        MainCompositionInst.renderSize = [[UIScreen mainScreen] bounds].size;
        MainCompositionInst.renderSize = VIDEO_SIZE;
        
        // Make sure the video doesn't exist.
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
        {
            [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
        }
        
        // Now we need to save the video.
        NSURL *url = [NSURL fileURLWithPath:pipBackVideo];
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                          presetName:AVAssetExportPresetHighestQuality];
        exporter.videoComposition = MainCompositionInst;
        exporter.outputURL=url;
        exporter.outputFileType = AVFileTypeMPEG4;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self makeComposeVideo];
            });
        }];
        
        pipAsset = nil;
        backAsset = nil;
        
        [activityView stopAnimating];
        
    }
    @catch (NSException *ex) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@",ex]
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    
    
}


@end
