//
//  BaseHttpService.m
//  FashionApp
//
//  Created by 1 on 2018/4/10.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSBaseNetworkService.h"
#import "FSNetWorkService.h"
#import "ThreadSafeMutableArry.h"
#import "ThreadSafeMutableDictionary.h"
#import "JCEObjectConverter.h"

@interface FSBaseNetworkService()
{
    NSString *_reqCmd;
    NSData *_reqData;
    ThreadSafeMutableArry *_reqCacheArry;
    NSString *_servantName;
    NSString *_funcName;
    NSString *_requestJceClass;
    NSString *_responseJceClass;
    
}
@property (nonatomic, strong) ThreadSafeMutableDictionary *jceMap;
@end

@implementation FSBaseNetworkService

- (instancetype)init
{
    if(self = [super init])
    {
        _reqCacheArry = [[ThreadSafeMutableArry alloc] init];
        self.jceMap = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}

#pragma mark TCP
- (NSString *)wnsCmd
{
    if(!_reqCmd)
    {
#ifdef DEBUG
        _reqCmd = @"srf_proxy_test";
#else
        _reqCmd = @"srf_proxy";
#endif
    }
    return _reqCmd;
}

#pragma mark overLoad func

- (NSString *)serviceName
{
    return _servantName;
}

- (NSString *)funcName
{
    return _funcName;
}

- (NSString *)requestJceClass
{
    return _requestJceClass;
}

- (NSData *)requestData
{
    if(_reqData)
    {
        return _reqData;
    }
    return nil;
}

- (NSString *)responseJceClass
{
    return _responseJceClass;
}

- (NSTimeInterval)networkCacheTime
{
    return 2;
}

- (BOOL)isCacheData
{
    return YES;
}

- (NSTimeInterval)reqTimeOut
{
    return 10000;
}

#pragma mark request network func
- (long)sendRequestDict:(NSDictionary *)dict completion:(void(^)(NSDictionary *busDict, NSError *bizError))completion
{
    if([self checkParam:dict])
    {
        JceObjectV2 *jceObject = convertDicToJceObject(dict, NSClassFromString(_requestJceClass));
        _reqData = creatCommonPacketWithServantName(_servantName, _funcName, @"req", jceObject);
        if(_reqData.length>0)
        {
            _reqCmd = [self wnsCmd];
            NSAssert(_reqCmd, @"cmd不能为空");
            WeakSelf(self);
            NSMutableString *strSeq = [[NSMutableString alloc] init];
            long reqNum = [[FSNetWorkService shareInstance] sendRequestTCPData:self completion:^(NSString *cmd, NSData *data, NSError *bizError, NSError *wnsError, NSError *wnsSubError) {
                if(!wnsError && !wnsSubError && !bizError)
                {
                    NSString *respoJceClass = [weakself.jceMap objectForKey:strSeq];
                    if(!respoJceClass)
                    {
                        respoJceClass= weakself.responseJceClass;
                    }
                    NSDictionary *dict = parseWUPData(data, @"rsp", respoJceClass);
                    completion(dict,bizError);
                    DDLogDebug(@"请求成功seq=%@,dict=%@",strSeq,dict);
                }
                else
                {
#warning 处理wns错误码  需要和后台定义错误码和msg
                    NSError *error = [NSError errorWithDomain:@"current net " code:kNetWorkFail userInfo:@{@"code":[NSNumber numberWithBool:kNetWorkFail],@"msg":@"当前服务不稳定，请稍后访问"}];
                    completion(nil,error);
                    
                }
                [weakself removeSeqNum:strSeq];
            }];
            
            if(reqNum != -1)
            {
                [strSeq appendFormat:@"%ld",reqNum];
                [_reqCacheArry addObject:strSeq];
                [self.jceMap setObject:_responseJceClass forKey:strSeq];
            }
            else if(reqNum == kNetworkCacheReturn)
            {
                DebugLog(@"网络数据来自缓存");
            }
            else
            {
#warning 处理网络请求为-1的情况
                NSError *error = [NSError errorWithDomain:@"current net " code:-1 userInfo:@{@"code":[NSNumber numberWithBool:kNetWorkFail],@"msg":@"当前网路不可用"}];
                completion(nil,error);
            }
            return reqNum;
        }
    }
    else
    {
        NSError *error = [NSError errorWithDomain:@"current net " code:-2 userInfo:@{@"code":[NSNumber numberWithBool:kNetworkParam],@"msg":@"参数不正确"}];
        completion(nil,error);
    }
    return -1;
}

#pragma mark  tool func

- (NSMutableDictionary *)packetReqParamSerName:(NSString *)servantName
                                      funcName:(NSString *)funcName
                                    reqJceName:(NSString *)reqJce
                                resposeJceName:(NSString *)responseJce
                                       busDict:(NSDictionary *)busDict
{
    if(!funcName || !reqJce || !responseJce || !servantName)
    {
        NSAssert(NO, @"funcName,cmd,servantName,requestJceClass,responseJceClass是必须填写的");
    }
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
    [mutDict setObject:servantName forKey:@"servantName"];
    [mutDict setObject:funcName forKey:@"funcName"];
    [mutDict setObject:reqJce forKey:@"requestJceClass"];
    [mutDict setObject:responseJce forKey:@"responseJceClass"];
    if(busDict)
    {
        [mutDict addEntriesFromDictionary:busDict];
    }
    _servantName = servantName;
    _funcName = funcName;
    _requestJceClass = reqJce;
    _responseJceClass = responseJce;
    return mutDict;
}

- (BOOL)checkParam:(NSDictionary *)dict
{
    if(!_servantName)
    {
        _servantName = [self serviceName]?:[dict objectForKey:@"servantName"];
    }
    if(!_funcName)
    {
        _funcName = [self funcName]?:[dict objectForKey:@"funcName"];
    }
    if(!_requestJceClass)
    {
        _requestJceClass = [self requestJceClass]?:[dict objectForKey:@"requestJceClass"];
    }
    if(!_responseJceClass)
    {
        _responseJceClass = [self responseJceClass]?:[dict objectForKey:@"responseJceClass"];
    }

    if(!_funcName || !_requestJceClass || !_responseJceClass || !_servantName)
    {
        NSAssert(NO, @"funcName,cmd,servantName,requestJceClass,responseJceClass是必须填写的");
        DDLogInfo(@"%@",dict);
        return NO;
    }
    return YES;
}

- (void)removeSeqNum:(NSString *)reqNum
{
    if(reqNum)
    {
        [_reqCacheArry removeObject:reqNum];
        [_jceMap removeObjectForKey:reqNum];
    }
}

- (void)cancelRequest:(long)seq
{
    [[FSNetWorkService shareInstance] cancelReq:seq];
}

- (void)cancelAllReq
{
    if(_reqCacheArry.count>0)
    {
        int count = (int)_reqCacheArry.count;
        [_reqCacheArry enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[FSNetWorkService shareInstance] cancelReq:[(NSString *)obj longLongValue]];
            if(idx == count-1)
            {
                *stop = YES;
            }
        }];
        [_reqCacheArry removeAllObjects];
    }
}


- (void)dealloc
{
    [self cancelAllReq];
}

@end
