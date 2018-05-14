//
//  FSN.m
//  FashionApp
//
//  Created by 1 on 2018/5/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSNetWorkError.h"

@implementation FSNetWorkError

+(NSError *)error:(int)errcode
{
    NSError *erro = nil;
    if(errcode == kNetWorkFail)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetWorkFail],@"msg":@"网络异常"}];
    }
    else if(errcode == kNetworkParam)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetworkParam],@"msg":@"参数错误"}];
    }
    else if(errcode == kNetworkSignatureTimeout)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetworkSignatureTimeout],@"msg":@"签名过期"}];
    }
    else if(errcode == kNetworkSignatureInvalid)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetworkSignatureInvalid],@"msg":@"签名无效"}];
    }
    else if(errcode == kNetworkUploadParamError)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetworkUploadParamError],@"msg":@"传入参数不对"}];
    }
    else if(errcode == kNetworkUploadFail)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetworkUploadFail],@"msg":@"上传失败"}];
    }
    else if(errcode == kNetworkReqSigFail)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetworkReqSigFail],@"msg":@"请求签名失败"}];
    }
    else if(errcode == kNetworkNotUploadid)
    {
        erro = [NSError errorWithDomain:@"" code:errcode userInfo:@{@"code":[NSNumber numberWithInt:kNetworkNotUploadid],@"msg":@"缺少uploadId参数"}];
    }
    return erro;
}

@end
