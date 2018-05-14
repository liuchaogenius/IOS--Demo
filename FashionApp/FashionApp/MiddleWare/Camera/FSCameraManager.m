//
//  FSCameraManager.m
//  FashionApp
//
//  Created by ericbbpeng(彭博斌)on 2018/4/13.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSCameraManager.h"

@interface FSCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, strong) dispatch_queue_t videoProcessingQueue;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@end

@implementation FSCameraManager

- (instancetype)initWithPosition:(AVCaptureDevicePosition)position{
    self = [super init];
    if (self) {
        [self setupSessionWithPositon:position];
    }
    return self;
}

- (void)dealloc{
    [self destroySession];
}

- (void)destroySession
{
    [self.session removeInput:self.deviceInput];
    [self.session removeOutput:self.stillImageOutput];
    [self.session removeOutput:self.videoDataOutput];
    [self.session stopRunning];
    self.session = nil;
    self.videoProcessingQueue = nil;
}


#pragma mark - public methods

- (void)startRunning{
    [self.session startRunning];
    self.isPaused = NO;
}

- (void)stopRunning{
    [self.session stopRunning];
}

- (void)manualFocusAtDevicePoint:(CGPoint)point{
    [self focusWithMode:AVCaptureFocusModeAutoFocus
         exposeWithMode:AVCaptureExposureModeAutoExpose
          atDevicePoint:point
      monitorAreaChange:YES];
}


- (void)captureStillImage
{
    [self pause];
    AVCaptureConnection *connection = [self findVideoConnectionfromConnections:self.stillImageOutput.connections];
    if ([connection isVideoOrientationSupported]){
        [connection setVideoOrientation:[self currentCaptureVideoOrientation]];
    }
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
        if (error){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self didCaptureStillImage:nil error:error];
            });
        }else{
            NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self didCaptureStillImage:image error:nil];
            });
        }
        [self startRunning];
    }];
}


- (BOOL)switchCameras:(NSError *__autoreleasing *)error
{
    AVCaptureDevicePosition position = [self.deviceInput device].position;
    AVCaptureDevicePosition descPosition = AVCaptureDevicePositionBack;
    switch (position){
        case AVCaptureDevicePositionBack:
            descPosition = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionFront:
            descPosition = AVCaptureDevicePositionBack;
            break;
        default:
            descPosition = AVCaptureDevicePositionBack;
            break;
    }
    
    AVCaptureDevice* device = [self getDeviceWithPostion:descPosition];
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:error];
    
    [self.session beginConfiguration];
    [self.session removeInput:self.deviceInput];
    if ([self.session canAddInput:input]){
        [self.session addInput:input];
        self.deviceInput = input;
    }else{
        return NO;
    }
    [self.session commitConfiguration];
    AVCaptureConnection *connection = [self findVideoConnectionfromConnections:[self.videoDataOutput connections]];
    if ([connection isVideoOrientationSupported]){
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    if (descPosition == AVCaptureDevicePositionFront){
        if ([connection isVideoMirroringSupported]){
            [connection setVideoMirrored:YES];
        }
    }
    
    return YES;
}

- (BOOL)setFlashMode:(AVCaptureFlashMode)mode error:(NSError *__autoreleasing *)error{
    if ([self.deviceInput.device lockForConfiguration:error]){
        [self.deviceInput.device setFlashMode:mode];
        [self.deviceInput.device unlockForConfiguration];
        return YES;
    }else{
        return NO;
    }
}

- (void)toggleCaptureMode:(FSCaptureMode)mode{
    if ( mode == FSCaptureModePhoto ) {
        dispatch_async( self.videoProcessingQueue, ^{
            [self.session beginConfiguration];
            [self.session removeOutput:self.movieFileOutput];
            self.session.sessionPreset = AVCaptureSessionPresetPhoto;
            self.movieFileOutput = nil;
            [self.session commitConfiguration];
        } );
    }else if ( mode == FSCaptureModeMovie ) {
        dispatch_async( self.videoProcessingQueue, ^{
            AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            
            if ( [self.session canAddOutput:movieFileOutput] )
            {
                [self.session beginConfiguration];
                [self.session addOutput:movieFileOutput];
                self.session.sessionPreset = AVCaptureSessionPresetHigh;
                AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                if ( connection.isVideoStabilizationSupported ) {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
                [self.session commitConfiguration];
                self.movieFileOutput = movieFileOutput;
            }
        } );
    }
}

#pragma mark - private methods

- (BOOL)setupSessionWithPositon:(AVCaptureDevicePosition)position{
    // get device
    AVCaptureDevice *device = [self getDeviceWithPostion:position];
    
    // add input
    self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canAddInput:self.deviceInput]){
        [self.session addInput:self.deviceInput];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    }else{
        return NO;
    }
    
    // add output
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    [self.stillImageOutput setOutputSettings:outputSettings];
    if ([self.session canAddOutput:self.stillImageOutput]){
        [self.session addOutput:self.stillImageOutput];
    }else{
        return NO;
    }
    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    NSDictionary* videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    [self.videoDataOutput setVideoSettings:videoSettings];
    self.videoProcessingQueue = dispatch_queue_create("camera session queue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoProcessingQueue];
    if ([self.session canAddOutput:self.videoDataOutput]){
        [self.session addOutput:self.videoDataOutput];
    }else{
        return NO;
    }
    
    // config connection
    AVCaptureConnection *connection = [self findVideoConnectionfromConnections:[self.videoDataOutput connections]];
    if ([connection isVideoOrientationSupported]){
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    if (position == AVCaptureDevicePositionFront) {
        if ([connection isVideoMirroringSupported]){
            [connection setVideoMirrored:YES];
        }
    }
    
    return YES;
}


- (AVCaptureDevice *)getDeviceWithPostion:(AVCaptureDevicePosition)position{
    AVCaptureDevice* device = nil;
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *aDevice in devices){
        if (aDevice.position == position){
            device = aDevice;
            break;
        }
    }
    
    if ([device lockForConfiguration:nil]){
        if ([device hasFlash]){
            if ([device isFlashModeSupported:AVCaptureFlashModeOff]){
                [device setFlashMode:AVCaptureFlashModeOff];
            }
        }
        if ([device hasTorch]){
            if ([device isTorchModeSupported:AVCaptureTorchModeOff]){
                [device setTorchMode:AVCaptureTorchModeOff];
            }
        }
        
        [device setSubjectAreaChangeMonitoringEnabled:YES];
        [device unlockForConfiguration];
    }
    
    return device;
}


// Create a UIImage from sample buffer data
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void)subjectAreaDidChange:(NSNotification *)notification{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus
         exposeWithMode:AVCaptureExposureModeContinuousAutoExposure
          atDevicePoint:devicePoint
      monitorAreaChange:NO];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode
       exposeWithMode:(AVCaptureExposureMode)exposureMode
        atDevicePoint:(CGPoint)point
    monitorAreaChange:(BOOL)monitorSubjectAreaChange{
    dispatch_async(self.videoProcessingQueue, ^{
        AVCaptureDevice *device = self.deviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}


- (AVCaptureConnection *)findVideoConnectionfromConnections:(NSArray *)connections{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
                return connection;
            }
        }
    }
    return nil;
}

- (AVCaptureVideoOrientation)currentCaptureVideoOrientation{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation){
        case UIDeviceOrientationFaceDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIDeviceOrientationFaceUp:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIDeviceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIDeviceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIDeviceOrientationUnknown:
            return AVCaptureVideoOrientationPortrait;
            break;
            
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

- (void)pause{
    self.isPaused = YES;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.isPaused){
        return;
    }
    
    // todo: sampleBuffer
    
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.delegate cameraManager:self didOutputSampleImage:image];
    });
}

@end
