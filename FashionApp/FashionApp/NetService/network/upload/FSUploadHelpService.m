//
//  FSUploadHelpService.m
//  FashionApp
//
//  Created by 1 on 2018/4/26.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSUploadHelpService.h"
#import "FSUploadFile.h"
#import "FSUploadVideo.h"
#import "ThreadSafeMutableDictionary.h"
#import "ThreadSafeMutableArry.h"
#import "FSNetWorkError.h"
#import "NSString+MD5.h"
@interface FSUploadConfig()
@property (nonatomic, strong) NSString *uploadId;
@end
@implementation FSUploadConfig

@end

//////***************************///////////////////
#pragma mark upload service
@interface FSUploadHelpService()

@property (nonatomic, strong) FSUploadFile *fileUpload;
@property (nonatomic, strong) FSUploadVideo *videoUpload;
@property (nonatomic, weak)id<FSUploadCallBack> callDelegate;
@property (nonatomic, strong) FSUploadConfig *config;
@property (nonatomic, strong) ThreadSafeMutableDictionary *filesFinishDict;
@property (nonatomic, strong) NSMutableDictionary *signatureDict;
@property (nonatomic, strong) NSMutableDictionary *fileContentMD5Dict;
@property (nonatomic, strong) dispatch_queue_t uploadQueue;
@end

@implementation FSUploadHelpService

- (instancetype)init
{
    if(self = [super init])
    {
        _uploadQueue = dispatch_queue_create("com.fsstyle.uploadFileQueue", DISPATCH_QUEUE_SERIAL);
        _fileContentMD5Dict = [NSMutableDictionary dictionaryWithCapacity:0];
        _filesFinishDict = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
        _fileUpload = [[FSUploadFile alloc] init];
        _videoUpload = [[FSUploadVideo alloc] init];
        _signatureDict = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}


- (void)uploadFile:(FSUploadConfig *)config callback:(id<FSUploadCallBack>)callback
{
    self.config = config;
    self.callDelegate = callback;
    [self.fileContentMD5Dict removeAllObjects];
    [self applySignatureInfo:config.resourceType uploadId:nil];
}

- (void)applySignatureInfo:(UPLoadReousrceType)aType uploadId:(NSString *)uploadId
{
    WeakSelf(self);

    NSMutableDictionary *dict = [self packetReqParamSerName:self.config.signatureServantName funcName:self.config.signaturefuncName reqJceName:@"FSStyleApplyUploadReq" resposeJceName:@"FSStyleApplyUploadRsp" busDict:nil];
    NSMutableDictionary *feedDict = [NSMutableDictionary dictionaryWithCapacity:0];
    [feedDict setValue:[NSNumber numberWithInt:self.config.serviceId] forKey:@"service_id"];
    [dict setObject:[NSNumber numberWithInt:aType] forKey:@"res_type"];
    if(aType == UPLoadReousrce_video)
    {
        [self.fileContentMD5Dict setValue:[self.config.videoUploadPath filePathReadStreamMD5] forKey:self.config.videoUploadPath];
    }
    else
    {
        [self readFileContentMD5];
    }
    [dict setValue:[self.fileContentMD5Dict allValues] forKey:@"file_list"];
    if(uploadId)
    {
        [dict setValue:uploadId forKey:@"reuse_upload_id"];
    }
    if(self.config.uploadInfoDict)
    {
        [dict setValue:self.config.uploadInfoDict forKey:@"service_info"];
    }
    
    [self sendRequestDict:dict completion:^(NSDictionary *busDict, NSError *bizError) {
        
        if(busDict && [[busDict objectForKey:@"ret_code"] intValue] == 0)
        {
            [weakself.signatureDict setValue:[[busDict objectForKey:@"cos_key"] objectForKey:@"expired_time"] forKey:@"expiredTime"];
            [weakself.signatureDict setValue:[[busDict objectForKey:@"cos_key"] objectForKey:@"token"] forKey:@"sessionToken"];
            [weakself.signatureDict setValue:[[busDict objectForKey:@"cos_key"] objectForKey:@"tmp_id"] forKey:@"tmpSecretId"];
            [weakself.signatureDict setValue:[[busDict objectForKey:@"cos_key"] objectForKey:@"tmp_key"] forKey:@"tmpSecretKey"];
            [weakself.signatureDict setValue:[busDict objectForKey:@"appid"] forKey:@"appid"];
            [weakself.signatureDict setValue:[[busDict objectForKey:@"cos_key"] objectForKey:@"region"] forKey:@"region"];
            [weakself.signatureDict setValue:[[busDict objectForKey:@"cos_key"] objectForKey:@"bucket"] forKey:@"bucket"];
            [weakself.signatureDict setValue:[[busDict objectForKey:@"cos_key"] objectForKey:@"path_prefix"] forKey:@"path_prefix"];
            [weakself.signatureDict setValue:[busDict objectForKey:@"video_sign"] forKey:@"videoSignature"];
            weakself.config.uploadId = [busDict objectForKey:@"upload_id"];
            [self uploadResource];
        }
        else
        {
            [weakself callbackFinish:nil resoutcePath:nil err:[FSNetWorkError error:kNetworkReqSigFail]];
        }
    }];
}

- (FSUploadHelpService *)uploadResource
{
    if(self.config.resourceType == UPLoadReousrce_video)
    {
        [self uploadVideo];
    }
    else
    {
        dispatch_async(self.uploadQueue, ^{
            [self uploadOtherFile];
        });
        
    }
    return self;
}

- (void)uploadVideo
{
    WeakSelf(self);
    [self.videoUpload signatureInfo:self.signatureDict];
    [self.videoUpload upLoadVideoPath:self.config.videoUploadPath result:^(NSDictionary *result, NSError *error) {
        [weakself callbackFinish:result resoutcePath:weakself.config.videoUploadPath err:nil];
        if(!error)
        {
            [weakself commitUploadSucc];
        }
        
    } procee:^(NSInteger bytesUpload, NSInteger bytesTotal) {
        [weakself process:weakself.config.videoUploadPath sendByte:bytesUpload totalByte:bytesTotal];
    }];
}

- (void)uploadOtherFile
{
    if(self.config.fileUploadPaths)
    {
        WeakSelf(self);
        [self.fileUpload clearUploadFinishData];
        [self.fileUpload signatureInfo:self.signatureDict fileMD5:[self.fileContentMD5Dict copy]];
        [self.filesFinishDict removeAllObjects];
        [self.config.fileUploadPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *filepath = (NSString*)obj;
            [weakself resetFinishDict:filepath];
            [weakself.fileUpload uploadFilePath:filepath process:^(long bytesSent, long totalBytesSent, long totalBytesExpectedToSend) {
                [weakself process:filepath sendByte:bytesSent totalByte:totalBytesSent];
            } finish:^(NSDictionary *dict, NSError *error) {
                [weakself handleFilesFinish:dict err:error];
                [weakself callbackFinish:dict resoutcePath:filepath err:error];
            }];
        }];
    }
}

- (void)handleFilesFinish:(NSDictionary *)dict err:(NSError *)error
{
    if(error.code == 0)
    {
        NSString *imgPath = [dict objectForKey:@"imgPath"];
        [self.filesFinishDict setValue:dict forKey:imgPath];
    }
    for(int i=0;i<self.config.fileUploadPaths.count;i++)
    {
        NSString *key = [self.config.fileUploadPaths objectAtIndex:i];
        NSDictionary *dict = [self.filesFinishDict objectForKey:key];
        if([[dict objectForKey:@"code"] intValue] != 0)
        {
            break;
        }
        else if(i == self.config.fileUploadPaths.count-1)
        {
            [self commitUploadSucc];
        }
    }
}

- (void)commitUploadSucc
{
    WeakSelf(self);
    if(weakself.callDelegate && [weakself.callDelegate respondsToSelector:@selector(busiInfoCommit:)] && self.config.uploadId)
    {
        NSDictionary *busiDict = [weakself.callDelegate busiInfoCommit:@{@"appid":self.config.uploadId}];
        NSDictionary *dict = [self packetReqParamSerName:self.config.commitServantName funcName:self.config.commitfuncName reqJceName:self.config.comitReqJceName resposeJceName:self.config.comitRspJceName busDict:busiDict];
        [self sendRequestDict:dict completion:^(NSDictionary *busDict, NSError *bizError) {
            if(weakself.callDelegate && [weakself.callDelegate respondsToSelector:@selector(commitFinish:error:)])
            {
                [weakself.callDelegate commitFinish:busDict error:bizError];
            }
        }];
    }
    else
    {
        if(weakself.callDelegate && [weakself.callDelegate respondsToSelector:@selector(busiInfoCommit:)])
        {
            NSError *error = [FSNetWorkError error:kNetworkNotUploadid];
            [weakself.callDelegate commitFinish:nil error:error];
        }
    }
}

#pragma mark cancel upload
- (void)cancelUpload:(FSUploadConfig *)config
{
    if(config.resourceType == UPLoadReousrce_video)
    {
        [self.videoUpload cancelUpload];
    }
    else
    {
        [self.fileUpload cancelUpload:config.fileUploadPaths];
        self.callDelegate = nil;
    }
    [self removeAllCache];
}


#pragma mark callback delegate

- (void)callbackFinish:(NSDictionary *)aDict resoutcePath:(NSString *)aPath err:(NSError *)error
{
    if(self.callDelegate && [self.callDelegate respondsToSelector:@selector(uploadFinish:resourcePath:error:)])
    {
        [self.callDelegate uploadFinish:aDict resourcePath:aPath error:error];
    }
}

- (void)process:(NSString *)path sendByte:(long long)sendByte totalByte:(long long)totalBtype
{
    if(self.callDelegate && [self.callDelegate respondsToSelector:@selector(uploadProcess:sendByte:totalByte:)])
    {
        [self.callDelegate uploadProcess:path sendByte:sendByte totalByte:totalBtype];
    }
}

#pragma mark tool
- (void)resetFinishDict:(NSString *)imgPath
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:kNetworkUploadFail] forKey:@"code"];
    [self.filesFinishDict setValue:dict forKey:imgPath];
}

- (void)readFileContentMD5
{
    [self.config.fileUploadPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       if(obj)
       {
           [self.fileContentMD5Dict setValue:[obj filePathReadStreamMD5] forKey:obj];
       }
    }];
}

- (void)removeAllCache
{
    [self.filesFinishDict removeAllObjects];
    [self.signatureDict removeAllObjects];
    [self.fileContentMD5Dict removeAllObjects];
}

- (void)dealloc
{
    DebugLog(@"FSUploadHelpService");
}
@end
