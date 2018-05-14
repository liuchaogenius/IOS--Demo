//
//  FSHttpService.m
//  FashionApp
//
//  Created by 1 on 2018/4/10.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSNetWorkService.h"
#import "FSBaseNetworkService.h"
#import <WnsSDK4Cloud/WnsWidLoginProtocol.h>
#import <WnsSDK4Cloud/WnsSDK.h>
#import "FSNetworkCache.h"
#import "NSData+Base64.h"
#import "JCEObjectConverter.h"
#import "JceObjectV2.h"

@interface FSNetWorkService ()
{
    WnsSDK *_wnsSDK;
}
@property (nonatomic, assign)WnsSDKStatus gWnsSDKStatus;
@property (nonatomic, strong)FSNetworkCache *dataCache;
@property (nonatomic, assign)int tryCount;
@property (nonatomic, strong)NSMapTable *sendMapTable;
@property (nonatomic, strong)dispatch_queue_t networkQueue;
@property (nonatomic, strong)NSMapTable *subcriptionMapTable;
@end

@implementation FSNetWorkService

+ (FSNetWorkService *)shareInstance
{
    static FSNetWorkService *fshObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fshObject = [[FSNetWorkService alloc] init];
    });
    return fshObject;
}

- (id)init
{
    if(self=[super init])
    {
        self.tryCount = 0;
    }
    return self;
}
#pragma mark  init wns
- (void)connectNetWns
{
    __weak FSNetWorkService *weakself = self;
    if(_wnsSDK)
    {
        [_wnsSDK reset:YES];
    }
    else
    {
        _wnsSDK = [[WnsSDK alloc] initWithAppID:kFSAPPID
                    andAppVersion:kFSAPPSHORTVERSION
                    andAppChannel:[self appChannel]
                       andAppType:WnsSDKAppTypeInner];
    }
    [_wnsSDK setStatusCallback:^(WnsSDKStatus status) {
        weakself.gWnsSDKStatus = status;
        if(weakself.gWnsSDKStatus == WnsSDKStatusDisconnected)
        {
            DebugLog(@"wns连接失败");
            if(weakself.tryCount<2)
            {
                [weakself resetConnection];
                weakself.tryCount++;
            }
        }
        else if(weakself.gWnsSDKStatus == WnsSDKStatusConnecting)
        {
            DebugLog(@"wns连接中......");
        }
        else if(weakself.gWnsSDKStatus == WnsSDKStatusConnected)
        {
            DebugLog(@"wns连接成功");
            weakself.tryCount = 0;
            [weakself againSendCache];
            [weakself recevicePushMsg];
        }
        
    }];
}

- (void)resetConnection
{
    if(_wnsSDK)
    {
        [_wnsSDK reset:YES];
    }
    else
    {
        [self connectNetWns];
    }
}

- (NSString *)appChannel
{
    return @"appstore";
}

#pragma mark 封装tcp
- (long)sendRequestTCPData:(FSBaseNetworkService *)baseService
                completion:(void(^)(NSString *cmd, NSData *data, NSError *bizError, NSError *wnsError, NSError *wnsSubError))completion
{
    if(self.gWnsSDKStatus == WnsSDKStatusConnected)
    {
        if([self dataForCache:baseService] && [baseService isCacheData])
        {
            completion([baseService wnsCmd],[self dataForCache:baseService],nil,nil,nil);
            DDLogInfo(@"该请求走的缓存数据sername=%@,funcname=%@,cmd=%@",[baseService serviceName],[baseService funcName],[baseService wnsCmd]);
            return kNetworkCacheReturn;
        }
        else
        {
            long seqNum = [_wnsSDK sendRequest:[baseService requestData] cmd:[baseService wnsCmd] timeout:[baseService reqTimeOut] completion:^(NSString *cmd, NSData *data, NSError *bizError, NSError *wnsError, NSError *wnsSubError) {
                DDLogInfo(@"cmd=%@,bizeErrorCode=%ld,wnsErrorCode=%ld,wnsSubErrorCode=%ld",cmd,(long)bizError.code,(long)wnsError.code,(long)wnsSubError.code);
                completion(cmd,data,bizError,wnsError,wnsSubError);
                if(!bizError && !wnsError && !wnsSubError)
                {
                    [self cacheNetworkData:data service:baseService];
                }
                [self removeCachecForkey:baseService];
            }];
            return seqNum;
        }
    }
    else
    {
        [self addCache:baseService completion:completion];
        [self resetConnection];
    }
    return -1;
}

- (void)cancelReq:(long)reqNum
{
    [_wnsSDK cancelRequest:reqNum];
}

#pragma mark cache data
- (void)addCache:(FSBaseNetworkService *)baseService
      completion:(void(^)(NSString *cmd, NSData *data, NSError *bizError, NSError *wnsError, NSError *wnsSubError))completion
{
    if(baseService && completion)
    {
        dispatch_async(self.networkQueue, ^{
            [self.sendMapTable setObject:[completion copy] forKey:baseService];
        });
    }
}

- (void)removeCachecForkey:(FSBaseNetworkService *)baseService
{
    if(baseService)
    {
        dispatch_async(self.networkQueue, ^{
            [self.sendMapTable removeObjectForKey:baseService];
        });
    }
}

- (void)againSendCache
{
    dispatch_async(self.networkQueue, ^{
        NSEnumerator *keys =[self.sendMapTable keyEnumerator];
        NSArray *allkeys = [keys allObjects];
        [allkeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if(obj && [self.sendMapTable objectForKey:obj])
           {
               [self sendRequestTCPData:obj completion:[self.sendMapTable objectForKey:obj]];
           }
        }];
    });
}

- (void)cacheNetworkData:(NSData *)data service:(FSBaseNetworkService *)baseService
{
    if([baseService serviceName] && [baseService funcName])
    {
        NSString *key = [NSString stringWithFormat:@"%@%@",[baseService serviceName],[baseService funcName]];
        [self.dataCache setCacheData:data cacheTime:[baseService networkCacheTime] key:key];
    }
}

- (id)dataForCache:(FSBaseNetworkService *)baseService
{
    NSData *data = nil;
    if([baseService serviceName] && [baseService funcName])
    {
        NSString *key = [NSString stringWithFormat:@"%@%@",[baseService serviceName],[baseService funcName]];
        data = [self.dataCache netCacheData:key data:nil];
    }
    return data;
}
#pragma mark wns func
- (void)bindUser:(NSDictionary *)userDict
{
    if(_wnsSDK)
    {
        NSString *userId = [userDict objectForKey:@"bindUserId"];
         id<WnsWidLoginProtocol> wnsLoginManager = [_wnsSDK loginManager];
        if([wnsLoginManager respondsToSelector:@selector(bind: completion:)])
        {
            [wnsLoginManager bind:userId completion:^(NSError *error) {
                if(!error)
                {
                    DDLogDebug(@"wns bind success");
                    
                }
                else
                {
                    DDLogDebug(@"wns bind fail");
                }
            }];
        }
    }
}

- (void)unbindUser:(NSDictionary *)userDict
{
    if(_wnsSDK)
    {
        NSString *userId = [userDict objectForKey:@"bindUserId"];
        id<WnsWidLoginProtocol> wnsLoginManager = [_wnsSDK loginManager];
        if([wnsLoginManager respondsToSelector:@selector(bind: completion:)])
        {
            [wnsLoginManager unbind:userId completion:^(NSError *error) {
                if(!error)
                {
                    DDLogDebug(@"wns unbind success");
                }
                else
                {
                    DDLogDebug(@"wns unbind fail");
                }
            }];
        }
    }
}

- (void)registerRemoteNotification:(NSDictionary *)deviceToken
{
    NSString *devtoken = [deviceToken objectForKey:@"deviceToken"];
    [_wnsSDK registerRemoteNotification:devtoken completion:^(NSError *error) {
        if(!error)
        {
            DDLogDebug(@"deviceToken 注册成功");
        }
        else
        {
            DDLogDebug(@"deviceToken 注册失败");
        }
    }];
}

- (void)subcriptionMsgObj:(NSDictionary *)dict
{
    dispatch_async(self.networkQueue, ^{
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if(obj && key)
            {
                [self.subcriptionMapTable setObject:obj forKey:key];
            }
        }];
    });

    
}

- (void)recevicePushMsg
{
    WeakSelf(self);
    [_wnsSDK setPushDataReceiveBlock:^(NSString *cmd, NSData *data, NSError *error) {
        DDLogDebug(@"接受push");
        if(!error && cmd && data)
        {
            NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSData *decData = [NSData dataFromBase64String:temp];
            Class jceclass = NSClassFromString(@"FSSrfWNSPushData");
            JceObjectV2 *jceObjc = [jceclass fromData:decData];
            NSDictionary *dict = convertJceObjectToDic(jceObjc);
            NSDictionary *pushDict = @{@"cmd":cmd,@"msgData":dict};
            dispatch_async(weakself.networkQueue, ^{
                NSArray *allkeys = [weakself.subcriptionMapTable keyEnumerator].allObjects;
                
                [allkeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                   if(obj)
                   {
                       id target = [weakself.subcriptionMapTable objectForKey:obj];
                       if(target && [target respondsToSelector:NSSelectorFromString(obj)])
                       {
                          #pragma clang diagnostic push
                          #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                          [target performSelector:NSSelectorFromString(obj) withObject:pushDict];
                          #pragma clang diagnostic pop
                           
                           
                       }
                   }
                }];
            });
        }
    }];
}

#pragma mark get
- (NSMapTable *)sendMapTable
{
    if(!_sendMapTable)
    {
        _sendMapTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    }
    return _sendMapTable;
}

- (NSMapTable *)subcriptionMapTable
{
    if(!_subcriptionMapTable)
    {
        _subcriptionMapTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    }
    return _subcriptionMapTable;
}

- (dispatch_queue_t)networkQueue
{
    if (!_networkQueue) {
        _networkQueue = dispatch_queue_create("com.fsstyle.networkFileQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _networkQueue;
}

- (FSNetworkCache *)dataCache
{
    if(!_dataCache)
    {
        _dataCache = [FSNetworkCache new];
    }
    return _dataCache;
}

@end
