//
//  FSUploadNetWorkService.m
//  FashionApp
//
//  Created by 1 on 2018/4/23.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSUploadVideo.h"
#import "TXUGCPublish.h"
#import "ThreadSafeMutableDictionary.h"
#import "FSNetWorkError.h"

@interface FSUploadVideo()<TXVideoPublishListener>
{
    int uploadReq;
    NSTimeInterval _expiredTime;
    NSString *_appId;
}
@property (nonatomic, strong) ThreadSafeMutableDictionary *cacheDict;
@property (nonatomic, strong) TXUGCPublish *pulish;
@property (nonatomic, strong) NSString *videoSignature;
@property (nonatomic, copy) void(^resultBlock)(NSDictionary *dict, NSError *error);
@property (nonatomic, copy) void(^processBlock)(NSInteger uploadBytes, NSInteger totalBytes);
@end

@implementation FSUploadVideo
#pragma mark overload func
- (NSString *)getVideoPath
{
    return nil;
}

- (UIImage *)coverImage
{
    return nil;
}

- (BOOL)enableHTTPS
{
    return YES;
}

- (BOOL)enableResume
{
    return NO;
}

#pragma mark upload func
- (void)upLoadVideoPath:(NSString *)videoPath
                 result:(void(^)(NSDictionary *result, NSError *error))resultBlock
                 procee:(void(^)(NSInteger bytesUpload, NSInteger bytesTotal))processBlock
{
    self.resultBlock = resultBlock;
    self.processBlock = processBlock;
    if([self resetUploadData])
    {
        [self upload:videoPath];
    }
    else
    {
        self.resultBlock(nil, [FSNetWorkError error:kNetworkSignatureInvalid]);
    }
    
}

- (void)upload:(NSString *)videoPath
{
    self.pulish = [[TXUGCPublish alloc] initWithUserID:_appId?:kUPLoadVideoAPPID];
    self.pulish.delegate = self;
    TXPublishParam *upParm = [self getVideoParam];
    if(videoPath)
    {
        upParm.videoPath = videoPath;
    }
    upParm.signature = self.videoSignature;
    if([self.pulish publishVideo:upParm] != 0)
    {
        self.resultBlock(nil, [FSNetWorkError error:kNetworkUploadParamError]);
    }
}

- (void)signatureInfo:(NSDictionary *)aDict
{
    self.videoSignature = [aDict objectForKey:@"videoSignature"];
    _expiredTime = [[aDict objectForKey:@"expiredTime"] longLongValue];
    _appId = [aDict objectForKey:@"appid"];
}

- (TXPublishParam *)getVideoParam
{
    TXPublishParam *upParm = [TXPublishParam new];
    if([self coverImage])
    {
        upParm.coverImage = [self coverImage];
    }
    if([self getVideoPath])
    {
        upParm.videoPath = [self getVideoPath];
    }
    upParm.enableHTTPS = [self enableHTTPS];
    upParm.enableResume = [self enableResume];
    return upParm;
}

- (void)cancelUpload
{
    if(self.pulish)
    {
        [self.pulish canclePublish];
    }
}

- (BOOL)resetUploadData
{
    if(_videoSignature)
    {
        return YES;
    }
    return NO;
}

#pragma mark delegate txvideoPublishListerer

-(void) onPublishProgress:(NSInteger)uploadBytes totalBytes: (NSInteger)totalBytes
{
    if(self.processBlock)
    {
        self.processBlock(uploadBytes, totalBytes);
    }
}

/**
 * 短视频发布完成
 */
-(void) onPublishComplete:(TXPublishResult*)result
{
    if(self.resultBlock)
    {
        NSError *error = nil;

        if(result.retCode != 0 && result.descMsg)
        {
            error = [NSError errorWithDomain:@"" code:result.retCode userInfo:@{@"code":[NSNumber numberWithInt:result.retCode],@"msg":result.descMsg}];
        }
        self.resultBlock([self responseToDict:result], error);
    }
    DDLogInfo(@"onPublishComplete%d",result.retCode);
}

-(void) onPublishEvent:(NSDictionary*)evt
{
    DebugLog(@"%@",evt);
}

#pragma mark tool func
- (NSDictionary *)responseToDict:(TXPublishResult *)response
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[NSNumber numberWithInt:response.retCode] forKey:@"retCode"];
    [dict setValue:response.descMsg forKey:@"descMsg"];
    [dict setValue:response.videoId forKey:@"videoId"];
    [dict setValue:response.videoURL forKey:@"videoURL"];
    [dict setValue:response.coverURL forKey:@"coverURL"];
    return dict;
}

- (ThreadSafeMutableDictionary *)cacheDict
{
    if(!_cacheDict)
    {
        _cacheDict = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
    return _cacheDict;
}


- (void)dealloc
{
    DebugLog(@"upload dealloc");
}

@end
