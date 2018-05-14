//
//  FSMsgService.h
//  FashionApp
//
//  Created by 1 on 2018/5/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSMsgService : NSObject

+ (void)startSubcriptionMsgSer;

//该subDict结构 key为要订阅的cmd(该值需要业务找后台要),value为要处理该消息的object, block为收到push消息的回调
+ (void)subcripitonBusiMsgForCmd:(NSDictionary *)subDict recvPushMsg:(void(^)(NSDictionary *busdiMsg))msgBlock;
@end
