//
//  QQLoginService.m
//  PayHousekeeper
//
//  Created by striveliu on 2016/12/5.
//  Copyright © 2016年 striveliu. All rights reserved.
//

#import "QQLoginService.h"


@interface QQLoginService()<TencentSessionDelegate>

@end

@implementation QQLoginService
+ (QQLoginService *)shareQQLoginService
{
    static QQLoginService *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[QQLoginService alloc] init];
    });
    return service;
}

- (void)registerQQLogin
{
    self.tOAuth = [[TencentOAuth alloc] initWithAppId:kQQLoginAPPID andDelegate:self];
}

- (void)qqLogin
{
    NSArray *permissions = [NSArray arrayWithObjects:kOPEN_PERMISSION_GET_INFO, kOPEN_PERMISSION_GET_USER_INFO, kOPEN_PERMISSION_GET_SIMPLE_USER_INFO, nil];
    self.tOAuth.authMode = kAuthModeClientSideToken;
    [self.tOAuth authorize:permissions inSafari:NO];
//    [self.tOAuth authorize:permissions localAppId:kQQLoginAPPID inSafari:NO];
}

- (void)handCallbackUrl:(NSURL *)url
{
    [TencentOAuth HandleOpenURL:url];
}

#pragma mark QQ登录回调
- (void)tencentDidLogin
{
    BOOL result = [self.tOAuth getUserInfo];
    if (result) {
        [self reqLoginByQQToken:self.tOAuth.accessToken openID:self.tOAuth.openId];
    }
}
- (void)tencentDidNotLogin:(BOOL)cancelled
{
//    [self.window hideToastActivity];
}
- (void)tencentDidNotNetWork
{
//    [self.window hideToastActivity];
}
- (BOOL)tencentNeedPerformIncrAuth:(TencentOAuth *)tencentOAuth withPermissions:(NSArray *)permissions
{
    return YES;
}

- (void)getUserInfoResponse:(APIResponse *)response {
    
    if (response && response.retCode == URLREQUEST_SUCCEED) {
        
        NSDictionary *userInfo = [response jsonResponse];
        [self requestLogin:userInfo loginResult:^(int result) {
            if(result == 0)
            {
//                [[YXManager sharedInstance] yxLogin:[UserInfoData shareUserInfoData]];
                //                [self showRootviewController];
            }

            else if(result != 0)
            {
                 DebugLog(@"登录失败，请检测网络");
            }
        }];
    } else {
        DebugLog(@"QQ auth fail ,getUserInfoResponse:%d", response.detailRetCode);
    }
}

- (void)autoLoginQQRequest:(NSDictionary *)aDict loginResult:(void(^)(int errorCode))aBlock
{
    [self requestLogin:aDict loginResult:aBlock];
}

- (void)requestLogin:(NSDictionary *)aUserInfoDict
         loginResult:(void(^)(int result))aBlock
{
    self.strNickname = [aUserInfoDict objectForKey:@"nickname"];
    self.strCity = [aUserInfoDict objectForKey:@"city"];
    self.strProvince = [aUserInfoDict objectForKey:@"province"];
    NSString *tempSex = nil;
    tempSex = [aUserInfoDict objectForKey:@"gender"];
    if([tempSex compare:@"男"] == 0)
    {
        self.strSex = @"M";
    }
    else
    {
        self.strSex = @"F";
    }
//    AppDelegate *del = (AppDelegate*)[UIApplication sharedApplication].delegate;
//    self.openId = del.tOAuth.openId;
    self.strHeadUrl = [aUserInfoDict objectForKey:@"figureurl_qq_1"];
    
    if(YES)
    {
//        [[DDLoginManager shareLoginManager] requestThirdLogin:del.tOAuth.openId loginType:@"0" hearUrl:self.strHeadUrl nick:self.strNickname gender:self.strSex birthday:nil loginResult:^(int result) {
//            aBlock(result);
//        }];
    }
    else
    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:kQQLoginSuccessNotifyName object:nil];
//        aBlock(0);
    }
    if(aUserInfoDict)
    {
//        NSMutableDictionary *qqdict = [NSMutableDictionary dictionaryWithDictionary:aUserInfoDict];
//        [qqdict setObject:del.tOAuth.openId forKey:kQQAutoLoginOpenid];
//        [[NSUserDefaults standardUserDefaults] setObject:qqdict forKey:kQQAutoLoginOpenid];
//        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - 后台网络接口

- (void)reqLoginByQQToken:(NSString *)token openID:(NSString *)openID{
    NSMutableDictionary *busDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [busDict setObject:openID forKey:@"openid"];
    [busDict setObject:token forKey:@"token"];
    NSMutableDictionary *reqDic = [self packetReqParamSerName:@"Style.LoginServer.LoginObj"
                                                     funcName:@"LoginByQQToken"
                                                   reqJceName:@"FSStyleReqLoginByQQToken"
                                               resposeJceName:@"FSStyleRspLogin"
                                                      busDict:busDict];
    [self sendRequestDict:reqDic completion:^(NSDictionary *busDict, NSError *error){
        if (error.code == noErr) {
            DDLogDebug(@"qq login success");
            [FSServiceRoute syncCallService:@"FSLoginService" func:@"loginSuccessWithResult:" withParam:busDict];
        }else{
            DDLogDebug(@"qq login error");
            [FSServiceRoute syncCallService:@"FSLoginService" func:@"loginFailWithResult:" withParam:busDict];
        }
    }];
}

@end
