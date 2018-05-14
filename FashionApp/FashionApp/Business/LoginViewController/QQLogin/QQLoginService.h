//
//  QQLoginService.h
//  PayHousekeeper
//
//  Created by striveliu on 2016/12/5.
//  Copyright © 2016年 striveliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import "FSBaseNetworkService.h"

@interface QQLoginService : FSBaseNetworkService
@property (nonatomic) NSString *strNickname;
@property (nonatomic) NSString *strCity;
@property (nonatomic) NSString *strProvince;
@property (nonatomic) NSString *strSex;
@property (nonatomic) NSString *strHeadUrl;
@property (nonatomic) NSString *openId;
@property (nonatomic)TencentOAuth * tOAuth;

+ (QQLoginService *)shareQQLoginService;

- (void)handCallbackUrl:(NSURL *)url;

- (void)qqLogin;

- (void)registerQQLogin;
@end
