//
//  WXLoginData.m
//  PayHousekeeper
//
//  Created by striveliu on 2016/12/4.
//  Copyright © 2016年 striveliu. All rights reserved.
//

#import "WXLoginService.h"
#import "WXApi.h"

@interface WXLoginService ()<WXApiDelegate>
@end

@implementation WXLoginService

+ (WXLoginService *)shareWXLoginData
{
    static WXLoginService *wxlData;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wxlData = [[WXLoginService alloc] init];
    });
    return wxlData;
}

- (void)registerWXApi
{
    [WXApi registerApp:kWEIXINLoginAppid enableMTA:NO];
}

- (void)loginWXAccount
{
    SendAuthReq *req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo";
    req.state = @"com.fashionApp.Login";
    [WXApi sendReq:req];
}

- (void)handleWXLoginDelegateUrl:(NSURL *)aUrl
{
    [WXApi handleOpenURL:aUrl delegate:self];
}

- (void)onResp:(BaseResp *)resp
{
    if([resp isKindOfClass:[SendAuthResp class]])
    {
        SendAuthResp *temp = (SendAuthResp *)resp;
        if(temp.code)
        {
            [self reqLoginByWXCode:temp.code];
        }
        else
        {
            if(temp.errCode == -2)//用户取消
            {
                DDLogDebug(@"微信用户取消登录");
            }
            else if(temp.errCode == -4) //用户拒绝
            {
                DDLogDebug(@"微信用户拒绝登录");
            }
        }
    }
}

#pragma mark - 后台网络接口

- (void)reqLoginByWXCode:(NSString *)code{
    NSMutableDictionary *busDict = [NSMutableDictionary dictionaryWithCapacity:1];
    [busDict setObject:code forKey:@"code"];
    NSMutableDictionary *reqDic = [self packetReqParamSerName:@"Style.LoginServer.LoginObj"
                                                     funcName:@"LoginByWxCode"
                                                   reqJceName:@"FSStyleReqLoginByWxCode"
                                               resposeJceName:@"FSStyleRspLogin"
                                                      busDict:busDict];
    [self sendRequestDict:reqDic completion:^(NSDictionary *busDict, NSError *error){
        if (error.code == noErr) {
            DDLogDebug(@"wx login success");
            [FSServiceRoute syncCallService:@"FSLoginService" func:@"loginSuccessWithResult:" withParam:busDict];
        }else{
            DDLogDebug(@"wx login error");
            [FSServiceRoute syncCallService:@"FSLoginService" func:@"loginFailWithResult:" withParam:busDict];
        }
    }];
}
@end
