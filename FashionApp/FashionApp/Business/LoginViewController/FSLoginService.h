//
//  FSLoginManager.h
//  FashionApp
//
//  Created by 1 on 2018/4/13.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSLoginService : NSObject
//+(FSLoginService *)shareInstance;

- (void)registerWXLogin;
- (void)wxLogin;
- (void)handWXLoginUrl:(NSDictionary *)aDict;

- (void)registerQQLogin;
- (void)qqLogin;
- (void)handQQLoginUrl:(NSDictionary *)aDict;

- (void)loginSuccessWithResult:(NSDictionary *)aDict;
- (void)loginFailWithResult:(NSDictionary *)aDict;
@end
