//
//  FSNetworkCache.h
//  FashionApp
//
//  Created by 1 on 2018/5/7.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSNetworkCache : NSObject

- (void)setCacheData:(NSData *)data cacheTime:(NSTimeInterval)time key:(NSString *)key;

- (NSData *)netCacheData:(NSString *)key data:(void(^)(id data))dataBlock;

@end
