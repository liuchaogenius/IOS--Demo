//
//  FSCameraManager.h
//  FashionApp
//
//  Created by ericbbpeng(彭博斌) on 2018/4/13.
//  Copyright © 2018年 1. All rights reserved.
//

@import UIKit;
@import AVFoundation;

#pragma mark - FSCameraManagerDelegate
@class FSCameraManager;
@protocol FSCameraManagerDelegate
@required
// 相机视频流捕获回调
- (void)cameraManager:(FSCameraManager *)manager didOutputSampleImage:(UIImage *)image;

// 相机拍照回调
- (void)cameraManager:(FSCameraManager *)manager didCaptureStillImage:(UIImage *)image error:(NSError *)error;

@end

typedef NS_ENUM( NSInteger, FSCaptureMode ) {
    FSCaptureModePhoto = 0,
    FSCaptureModeMovie = 1
};

#pragma mark - FSCameraManager
@interface FSCameraManager : NSObject

@property (nonatomic, weak) id<FSCameraManagerDelegate> delegate;

- (instancetype)initWithPosition:(AVCaptureDevicePosition)position;
- (void)startRunning;
- (void)stopRunning;
- (void)captureStillImage;
- (BOOL)switchCameras:(NSError *__autoreleasing *)error;
- (BOOL)setFlashMode:(AVCaptureFlashMode)mode error:(NSError *__autoreleasing *)error;
- (void)manualFocusAtDevicePoint:(CGPoint)point;
- (void)toggleCaptureMode:(FSCaptureMode)mode;
@end
