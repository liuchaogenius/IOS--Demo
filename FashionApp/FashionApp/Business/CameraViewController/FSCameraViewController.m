//
//  FSCameraViewController.m
//  FashionApp
//
//  Created by ericbbpeng(彭博斌) on 2018/4/18.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSCameraViewController.h"
#import "FSCameraManager.h"
#import "VACDataReport.h"
@import AssetsLibrary;

@interface FSCameraViewController ()<FSCameraManagerDelegate>
@property (nonatomic) FSCameraManager *cameraManager;
@property (nonatomic) UIImageView *cameraPreviewView;
@property (nonatomic) UIButton *photoButton;
@property (nonatomic) UIButton *switchCameraButton;
@property (nonatomic) UIButton *flashButton;
@property (nonatomic) AVCaptureFlashMode currentFlashMode;
@end

@implementation FSCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [VACDataReport commitWithModule:@"fationStyle" action:@"new app test" sKey:@"10000"];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    self.cameraPreviewView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.width * 100/75)];
    [self.view addSubview:self.cameraPreviewView];
    
    // take photo button
    self.photoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.photoButton.bounds = CGRectMake(0, 0, 100, 60);
    self.photoButton.center = CGPointMake(self.view.center.x, self.view.bounds.size.height - 40);
    [self.photoButton setTitle:@"拍照" forState:UIControlStateNormal];
    [self.photoButton addTarget:self action:@selector(photoButtonDidTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.photoButton];
    
    // switch Camera Button
    self.switchCameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.switchCameraButton.bounds = CGRectMake(0, 0, 100, 60);
    self.switchCameraButton.center = CGPointMake(self.photoButton.center.x + 100, self.photoButton.center.y);
    [self.switchCameraButton setTitle:@"切换" forState:UIControlStateNormal];
    [self.switchCameraButton addTarget:self action:@selector(switchCameras:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchCameraButton];
    
    // flash button
    self.flashButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.flashButton.bounds = CGRectMake(0, 0, 100, 60);
    self.flashButton.center = CGPointMake(self.photoButton.center.x - 100, self.photoButton.center.y);
    [self.flashButton setTitle:@"闪光关" forState:UIControlStateNormal];
    [self.flashButton addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    // manual focus gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAndExposeTap:)];
    [self.cameraPreviewView addGestureRecognizer:tapGesture];
    self.cameraPreviewView.userInteractionEnabled = YES;
    
    // init camera
    self.cameraManager = [[FSCameraManager alloc] initWithPosition:AVCaptureDevicePositionFront];
    self.cameraManager.delegate = self;
    [self.cameraManager startRunning];
}

- (void)photoButtonDidTap:(UIButton *)sender{
    self.cameraPreviewView.alpha = 0;
    [UIView animateWithDuration:0.1 animations:^(void){
        self.cameraPreviewView.alpha = 1.0;
    }];
    [self.cameraManager captureStillImage];
}

- (void)switchCameras:(id)sender{
    NSError *error = nil;
    [self.cameraManager switchCameras:&error];
}

- (void)switchFlash:(id)sender{
    NSError *error = nil;
    AVCaptureFlashMode targetFlashMode;
    NSString *title;
    switch (self.currentFlashMode) {
        case AVCaptureFlashModeOff:{
            targetFlashMode = AVCaptureFlashModeOn;
            title = @"闪光开";
            break;
        }
        case AVCaptureFlashModeOn:{
            targetFlashMode = AVCaptureFlashModeAuto;
            title = @"自动";
            break;
        }
        case AVCaptureFlashModeAuto:{
            targetFlashMode = AVCaptureFlashModeOff;
            title = @"闪光关";
            break;
        }
        default:
            break;
    }
    [self.cameraManager setFlashMode:targetFlashMode error:&error];
    if (error.code == noErr) {
        self.currentFlashMode = targetFlashMode;
        [self.flashButton setTitle:title forState:UIControlStateNormal];
    }
}

- (void)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer{
    CGPoint viewPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGPoint devicePoint = CGPointMake(viewPoint.x / self.cameraPreviewView.bounds.size.width, viewPoint.y / self.cameraPreviewView.bounds.size.height);
    [self.cameraManager manualFocusAtDevicePoint:devicePoint];
}

#pragma mark - FSCameraManagerDelegate

// 相机视频流捕获回调
- (void)cameraManager:(FSCameraManager *)manager didOutputSampleImage:(UIImage *)image{
    self.cameraPreviewView.image = image;
}

// 相机拍照回调
- (void)cameraManager:(FSCameraManager *)manager didCaptureStillImage:(UIImage *)image error:(NSError *)error{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        
    }];
}

@end
