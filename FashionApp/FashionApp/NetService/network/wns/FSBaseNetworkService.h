//
//  BaseHttpService.h
//  FashionApp
//
//  Created by 1 on 2018/4/10.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, UploadSignatureType){
    VideoSignatureType=1,
    PictureSignatureType,
    UnknowSignatureType
};

#define kNetWorkSendReqFail  -1

@interface FSBaseNetworkService : NSObject

- (NSData *)requestData;

- (NSString *)wnsCmd;

- (NSTimeInterval)reqTimeOut;

- (NSString *)serviceName;

- (NSString *)funcName;

- (NSString *)requestJceClass;

- (NSString *)responseJceClass;

- (NSTimeInterval)networkCacheTime;

- (BOOL)isCacheData;

- (NSMutableDictionary *)packetReqParamSerName:(NSString *)servantName
                                      funcName:(NSString *)funcName
                                    reqJceName:(NSString *)reqJce
                                resposeJceName:(NSString *)responseJce
                                       busDict:(NSDictionary *)busDict;

//网络请求返回-1的时候 completion block是不回调的
- (long)sendRequestDict:(NSDictionary *)dict completion:(void(^)(NSDictionary *busDict, NSError *bizError))completion;

@end
