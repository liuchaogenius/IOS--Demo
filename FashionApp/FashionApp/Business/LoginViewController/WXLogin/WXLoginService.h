//
//  WXLoginData.h
//  PayHousekeeper
//
//  Created by striveliu on 2016/12/4.
//  Copyright © 2016年 striveliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSBaseNetworkService.h"

#define kWXBaseUrl @"https://api.weixin.qq.com/sns"
#define WX_ACCESS_TOKEN @"access_token"
#define WX_OPEN_ID @"openid"
#define WX_REFRESH_TOKEN @"refresh_token"


@interface WXLoginService : FSBaseNetworkService
@property (nonatomic) NSString *code;
@property (nonatomic) NSString *state;
@property (nonatomic) NSString *openid;
@property (nonatomic) NSString *nickName;
@property (nonatomic) NSString *province;
@property (nonatomic) NSString *sex;
@property (nonatomic) NSString *city;
@property (nonatomic) NSString *country;
@property (nonatomic) NSString *headUrl;
@property (nonatomic) NSString *unionid;
@property (nonatomic) NSString *accessToken;
@property (nonatomic, copy) void(^loginReuslt)(int errcode);

+ (WXLoginService *)shareWXLoginData;

- (void)registerWXApi;

- (void)loginWXAccount;

- (void)handleWXLoginDelegateUrl:(NSURL *)aUrl;

@end
