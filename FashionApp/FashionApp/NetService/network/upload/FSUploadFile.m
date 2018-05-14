//
//  FSUploadPictureService.m
//  FashionApp
//
//  Created by 1 on 2018/4/24.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSUploadFile.h"
#import <QCloudCore/QCloudCore.h>
#import <QCloudCOSXML/QCloudCOSXML.h>
#import "ThreadSafeMutableDictionary.h"
#import "NSObject+FSObject.h"
#import "FSNetWorkError.h"

#define FSUGCUploadPicCosKey             @"FSUploadPic"
#define FSUploadPictureBucket    @"img"
//static QCloudServiceConfiguration* configuration = nil;
@interface FSUploadFile()<QCloudSignatureProvider>
{
    NSString *_sessionToken;
    NSString *_tmpSecretId;
    NSString *_tmpSecretKey;
    NSString *_bucket;
    NSString *_filePrefixPath;
    NSString *_regionName;
    NSString *_appId;
    NSTimeInterval _expiredTime;
    NSDictionary *_fileMD5Dict;
}
@property (nonatomic, strong) ThreadSafeMutableDictionary *cacheUploadSafeDict;
@property (nonatomic, strong) ThreadSafeMutableDictionary *cacheFinshBlockSafeDict;
@property (nonatomic, strong) ThreadSafeMutableDictionary *cacheProcessBlockSafeDict;
//@property (nonatomic, strong) QCloudAuthentationCreator* creator;
@property (nonatomic, strong) QCloudServiceConfiguration *configuration;
//@property (nonatomic, strong) QCloudSignature* signature;
@end

@implementation FSUploadFile

- (void)setupCOSXMLShareService:(NSString *)filePath callback:(id)delegate;
{
    if(!self.configuration)
    {
        self.configuration = [QCloudServiceConfiguration new];
        self.configuration.appID = _appId?:kUPLoadVideoAPPID;
        self.configuration.signatureProvider = self;
        QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
        endpoint.regionName = _regionName?:@"ap-guangzhou";
        self.configuration.endpoint = endpoint;
        [QCloudCOSXMLService registerCOSXMLWithConfiguration:self.configuration withKey:FSUGCUploadPicCosKey];
        [QCloudCOSTransferMangerService registerCOSTransferMangerWithConfiguration:self.configuration withKey:FSUGCUploadPicCosKey];
    }
}

#pragma mark delegate QCloudSignatureProvider
- (void)signatureWithFields:(QCloudSignatureFields*)fileds
                    request:(QCloudBizHTTPRequest*)request
                 urlRequest:(NSMutableURLRequest*)urlRequst
                  compelete:(QCloudHTTPAuthentationContinueBlock)continueBlock
{

    QCloudCredential *credential = [QCloudCredential new];
    credential.secretID = _tmpSecretId;
    credential.secretKey = _tmpSecretKey;
    credential.token = _sessionToken;
    credential.experationDate  = [NSDate dateWithTimeIntervalSince1970:_expiredTime];
    QCloudAuthentationV5Creator *creator = [[QCloudAuthentationV5Creator alloc] initWithCredential:credential];
    QCloudSignature *signature =  [creator signatureForData:urlRequst];
    continueBlock(signature, nil);
}

- (BOOL)resetUploadData
{
    if(_sessionToken && _tmpSecretKey && _tmpSecretId && _expiredTime > 0)
    {
        return YES;
    }
    return NO;
}

#pragma mark upload
- (void)uploadFilePath:(NSString *)filePath
               process:(UploadPictProcessBlock)processBlock
                finish:(UploadPicFinishBlock)finishBlock
{
    NSAssert(filePath, @"图片路径不合法");
    [self setupCOSXMLShareService:filePath callback:self];
    NSString *tmpfilePath = [NSString stringWithString:filePath];
    QCloudCOSXMLUploadObjectRequest* upload = [QCloudCOSXMLUploadObjectRequest new];
    upload.body = [NSURL fileURLWithPath:filePath];
    upload.bucket = _bucket;
    upload.object = [NSString stringWithFormat:@"%@%@%@",_filePrefixPath,[_fileMD5Dict objectForKey:filePath],[self fileType:filePath]];
    [self.cacheUploadSafeDict setValue:upload forKey:tmpfilePath];
    [self.cacheFinshBlockSafeDict setValue:[finishBlock copy] forKey:tmpfilePath];
    [self.cacheProcessBlockSafeDict setValue:[processBlock copy] forKey:tmpfilePath];
    if([self resetUploadData])
    {
        [self upload:tmpfilePath];
    }
    else
    {
        [self retFail:tmpfilePath errorCode:kNetworkSignatureInvalid];
    }
}

- (void)upload:(NSString *)filePath
{
    NSString *tmpFilePath = [NSString stringWithString:filePath];
    QCloudCOSXMLUploadObjectRequest *upload = [self.cacheUploadSafeDict objectForKey:tmpFilePath];
    WeakSelf(self);
    [upload setFinishBlock:^(QCloudUploadObjectResult *result, NSError *error) {
        if (error)
        {
            [weakself uploadError:error uploadPath:tmpFilePath];
        }
        else
        {
            [weakself retSuccess:tmpFilePath imgurl:result.location];
        }
    }];
    [upload setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        UploadPictProcessBlock pb = [weakself.cacheProcessBlockSafeDict objectForKey:tmpFilePath];
        if(pb)
        {
            pb(bytesSent,totalBytesSent,totalBytesExpectedToSend);
        }
    }];
    [[QCloudCOSTransferMangerService costransfermangerServiceForKey:FSUGCUploadPicCosKey] UploadObject:upload];
}

- (void)uploadError:(NSError *)error uploadPath:(NSString *)upLoadPath
{
    NSString * errInfo = error.localizedDescription;
    NSString * cosErrorCode = @"";
    if (error.userInfo != nil) {
        errInfo = error.userInfo.description;
        cosErrorCode = error.userInfo[@"Code"];
    }

    if ([cosErrorCode isEqualToString:@"RequestTimeTooSkewed"])//证书过期 要重新获取秘钥
    {
        [self retFail:upLoadPath errorCode:kNetworkSignatureTimeout];
    }
    else
    {
        [self retFail:upLoadPath errorCode:kNetWorkFail];
    }
    
}

- (void)removeCacheUpload:(NSString *)upLoadPath
{
    [self.cacheUploadSafeDict removeObjectForKey:upLoadPath];
    [self.cacheProcessBlockSafeDict removeObjectForKey:upLoadPath];
    [self.cacheFinshBlockSafeDict removeObjectForKey:upLoadPath];
}

- (void)removeAllCacheUpload
{
    [self.cacheUploadSafeDict removeAllObjects];
    [self.cacheProcessBlockSafeDict removeAllObjects];
    [self.cacheFinshBlockSafeDict removeAllObjects];
}
#pragma mark cancel upload
- (void)cancelUpload:(NSArray *)filePaths
{
    if(filePaths)
    {
        WeakSelf(self);
        [filePaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj)
            {
                QCloudCOSXMLUploadObjectRequest* cancelUpload = [weakself.cacheUploadSafeDict objectForKey:obj];
                if(cancelUpload)
                {
                    [cancelUpload abort:^(id outputObject, NSError *error) {
                        
                    }];
                }
            }
        }];
        [self removeAllCacheUpload];
        [self clearUploadFinishData];
    }
}

#pragma mark retBlock
- (void)retSuccess:(NSString *)imgPath imgurl:(NSString *)imgUrl
{
    UploadPicFinishBlock fb = [self.cacheFinshBlockSafeDict objectForKey:imgPath];
    NSMutableDictionary *resutDict = [NSMutableDictionary dictionary];
    [resutDict setValue:imgPath forKey:@"imgPath"];
    [resutDict setValue:@"0" forKey:@"code"];
    [resutDict setValue:imgUrl forKey:@"imgUrl"];
    if(fb)
    {
        fb(resutDict,0);
    }
    [self removeCacheUpload:imgPath];
}

- (void)retFail:(NSString *)imgPath errorCode:(int)code
{
    NSMutableDictionary *resutDict = [NSMutableDictionary dictionary];
    [resutDict setValue:imgPath forKey:@"imgPath"];
    
    UploadPicFinishBlock fb = [self.cacheFinshBlockSafeDict objectForKey:imgPath];
    if(fb)
    {
        fb(resutDict,[FSNetWorkError error:code]);
    }
    [self removeCacheUpload:imgPath];
}

#pragma mark tool
- (void)signatureInfo:(NSDictionary *)aDict  fileMD5:(NSDictionary *)fileMD5Dict
{
    _sessionToken = [aDict objectForKey:@"sessionToken"];
    _tmpSecretKey = [aDict objectForKey:@"tmpSecretKey"];
    _tmpSecretId = [aDict objectForKey:@"tmpSecretId"];
    _expiredTime = [[aDict objectForKey:@"expiredTime"] longLongValue];
    _filePrefixPath = [aDict objectForKey:@"path_prefix"];
    _regionName = [aDict objectForKey:@"region"];
    _fileMD5Dict = fileMD5Dict;
    _appId = [aDict objectForKey:@"appid"];
    _bucket = [aDict objectForKey:@"bucket"]?:FSUploadPictureBucket;
}

- (void)clearUploadFinishData
{
    self.configuration = nil;
    _sessionToken = nil;
    _tmpSecretKey = nil;
    _tmpSecretId = nil;
    _expiredTime = 0;
}

- (NSString *)fileType:(NSString *)filePath
{
    NSString *suffix = nil;
    if(filePath && [filePath length]>0)
    {
        NSRange range = [filePath rangeOfString:@"."];
        suffix = [filePath substringFromIndex:range.location];
    }
    DebugLog(@"file_suffix=%@",suffix);
    return suffix;
}

#pragma mark get func
- (ThreadSafeMutableDictionary *)cacheUploadSafeDict
{
    if(!_cacheUploadSafeDict)
    {
        _cacheUploadSafeDict = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
    return _cacheUploadSafeDict;
}

- (ThreadSafeMutableDictionary *)cacheFinshBlockSafeDict
{
    if(!_cacheFinshBlockSafeDict)
    {
        _cacheFinshBlockSafeDict = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
    return _cacheFinshBlockSafeDict;
}

- (ThreadSafeMutableDictionary *)cacheProcessBlockSafeDict
{
    if(!_cacheProcessBlockSafeDict)
    {
        _cacheProcessBlockSafeDict = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
    return _cacheProcessBlockSafeDict;
}

- (void)dealloc
{
    DDLogDebug(@"dafadsfas");
}

@end
