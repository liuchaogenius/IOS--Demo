//
//  FSNetworkCache.m
//  FashionApp
//
//  Created by 1 on 2018/5/7.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSNetworkCache.h"
#import "ThreadSafeMutableDictionary.h"
@interface FSNetworkCache()

@property (nonatomic, strong) ThreadSafeMutableDictionary *netCache;
@property (nonatomic, strong) dispatch_source_t sourceTimer;
@property (nonatomic, strong) dispatch_queue_t netCacheQueue;
@end

@implementation FSNetworkCache

- (void)setCacheData:(NSData*)data cacheTime:(NSTimeInterval)time key:(NSString *)key
{
    if(data)
    {
        NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [tempDict setValue:[NSNumber numberWithLongLong:time] forKey:@"timeCount"];
        [tempDict setValue:data forKey:@"cacheData"];
        if(data)
        {
            [self.netCache setObject:tempDict forKey:key];
        }
    }
    if(!self.sourceTimer)
    {
        [self startCheckCacheData];
    }
}

- (NSData *)netCacheData:(NSString *)key data:(void(^)(id data))dataBlock
{
    return [[self.netCache objectForKey:key] objectForKey:@"cacheData"];
}

#pragma mark 定时器操作
- (void)startCheckCacheData
{
    if(!self.sourceTimer)
    {
        self.sourceTimer =  dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.netCacheQueue);
    }
    dispatch_source_set_timer(self.sourceTimer, DISPATCH_TIME_NOW, 2.0*NSEC_PER_SEC, 1.0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.sourceTimer, ^{
        [self.netCache enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if(obj)
            {
                int timeCount = [[obj objectForKey:@"timeCount"] intValue];
                timeCount -= 2;
                if(timeCount<=0)
                {
                    [self.netCache removeObjectForKey:key];
                }
                if([self.netCache allKeys].count==0)
                {
                    dispatch_source_cancel(self.sourceTimer);
                    self.sourceTimer = nil;
                }
            }
        }];
    });
    dispatch_resume(self.sourceTimer);
}

#pragma mark get
- (dispatch_queue_t)netCacheQueue
{
    if (!_netCacheQueue) {
        _netCacheQueue = dispatch_queue_create("com.fsstyle.networkCacheQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _netCacheQueue;
}

- (ThreadSafeMutableDictionary *)netCache
{
    if(!_netCache)
    {
        _netCache = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
    return _netCache;
}

@end
