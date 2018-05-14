//
//  FSNetWorkError.h
//  FashionApp
//
//  Created by 1 on 2018/5/2.
//  Copyright © 2018年 1. All rights reserved.
//

#ifndef FSNetWorkError_h
#define FSNetWorkError_h

#define kNetWorkFail -1  //网络不好或者服务的无反应
#define kNetworkParam -5 //参数不对
#define kNetworkSignatureTimeout  -10 //签名过期
#define kNetworkSignatureInvalid  -11 //签名无效
#define kNetworkUploadParamError  -12  //上传参数不对
#define kNetworkUploadFail        -13  //上传失败
#define kNetworkReqSigFail        -14  //请求签名失败
#define kNetworkNotUploadid       -15 //缺少uploadid
#define kNetworkCacheReturn       -100 //从cache 获取的数据

@interface FSNetWorkError :NSObject

+(NSError *)error:(int)errcode;

@end
#endif /* FSNetWorkError_h */
