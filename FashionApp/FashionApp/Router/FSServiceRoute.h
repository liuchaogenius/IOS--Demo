//
//  FSServiceRoute.h
//  ProtocalClass
//
//  Created by 1 on 2018/4/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSServiceRoute : NSObject

+ (FSServiceRoute *)shareInstance;

+ (id)asyncCallService:(NSString *)className
                  func:(NSString *)actionName
             withParam:(NSDictionary *)param
            completion:(void(^)(NSDictionary *info))completion;

+ (id)syncCallService:(NSString *)className
                 func:(NSString *)actionName
            withParam:(NSDictionary *)param;

//+ (id)singletonCallService:(NSString *)className
//                          func:(NSString *)actionName
//                     withParam:(NSDictionary *)param
//                    completion:(void(^)(NSDictionary *info))completion;

@end
