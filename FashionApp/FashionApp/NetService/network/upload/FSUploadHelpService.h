//
//  FSUploadHelpService.h
//  FashionApp
//
//  Created by 1 on 2018/4/26.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSBaseNetworkService.h"

typedef  NS_ENUM(NSInteger, UPLoadReousrceType)
{
    UPLoadReousrce_video=1,
    UPLoadReousrce_picture,
    UPLoadReousrce_log,
    UPLoadReousrce_unKnow,
};

@interface FSUploadConfig : NSObject
//上传资源类型
@property (nonatomic, assign) UPLoadReousrceType resourceType;
//视频发布需要的业务信息 ，业务和后台协商的，sdk负责透传
@property (nonatomic, strong) NSDictionary *busiInfo;
//视频的path
@property (nonatomic, strong) NSString *videoUploadPath;
//图片path 支持多张上传
@property (nonatomic, strong) NSArray<NSString *> *fileUploadPaths;
//业务的发布id 业务与后台协商
@property (nonatomic, assign) int serviceId;
//签名的servantname  业务需要和后台协商
@property(nonatomic, strong) NSString *signatureServantName;
//签名的funName  业务需要和后台协商
@property(nonatomic, strong) NSString *signaturefuncName;
//上传成功后提交的servantName  业务需要和后台协商
@property(nonatomic, strong) NSString *commitServantName;
//上传成功后提交的funcName  业务需要和后台协商
@property(nonatomic, strong) NSString *commitfuncName;
//commit需要的reqjce
@property(nonatomic, strong) NSString *comitReqJceName;
//commit需要的rspjce
@property(nonatomic, strong) NSString *comitRspJceName;
////上传作品需要的信息，业务需要和后台协商是否需要该信息
@property(nonatomic, strong) NSDictionary *uploadInfoDict;
@end

//上传的回调
@protocol FSUploadCallBack <NSObject>
@required
//单个资源上传成功的回调  视频也会回调这个接口
- (void)uploadFinish:(NSDictionary *)dict resourcePath:(NSString *)path error:(NSError *)error;
//通过该函数获取业务需要commit的数据，uploadInfo中会带回appid，key=@"appid"
- (NSDictionary *)busiInfoCommit:(NSDictionary*)uploadInfo;
@optional
//上传中的回调
- (void)uploadProcess:(NSString *)path sendByte:(long long)sendByte totalByte:(long long)totalBtype;

//针对多个files上传，都上传完了后的回调
- (void)commitFinish:(NSDictionary *)dict error:(NSError *)error;

@end


@interface FSUploadHelpService : FSBaseNetworkService

//调用该方法需要实现 FSUploadCallBack 方法接受回调
- (void)uploadFile:(FSUploadConfig *)config callback:(id<FSUploadCallBack>)callback;

- (void)cancelUpload:(FSUploadConfig *)config;
@end
