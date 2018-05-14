//
//  WnsCommonDefine.h
//  WnsSDK
//
//  Created by best1a on 8/31/15.
//  Copyright (c) 2015 Tencent. All rights reserved.
//

#ifndef WnsSDK_WnsCommonDefine_h
#define WnsSDK_WnsCommonDefine_h

#pragma mark - 相关枚举定义

// WnsSDK通道状态
typedef NS_ENUM(NSInteger, WnsSDKStatus) {
    WnsSDKStatusDisconnected    = 0,    //WnsSDK通道不可用
    WnsSDKStatusConnecting      = 1,    //WnsSDK通道建立中 过程包括网络连接、握手包(Handshake)、加密包(B2)
    WnsSDKStatusConnected       = 2,    //WnsSDK通道建立成功
};

// LOG等级
typedef NS_ENUM(NSInteger, WnsSDKLogLevel) {
    WnsSDKLogLevelDisabled      = -1,
    WnsSDKLogLevelError         = 0,
    WnsSDKLogLevelWarn          = 1,
    WnsSDKLogLevelInfo          = 2,
    WnsSDKLogLevelDebug         = 3,
    WnsSDKLogLevelTrace         = 4,
    WnsSDKLogLevelMax           = 5,
};

// 运营商类型
typedef NS_ENUM(NSInteger, WnsSDKCarrierType) {
    WnsSDKCarrierTypeUnknown        = 0,
    WnsSDKCarrierTypeMobile         = 1,
    WnsSDKCarrierTypeUnicom         = 2,
    WnsSDKCarrierTypeTelecom        = 3,
    WnsSDKCarrierTypeTietong        = 4
};


// APN类型
typedef NS_ENUM(NSInteger, WnsSDKApnType) {
    WnsSDKApnTypeUnknown            = 0,
    WnsSDKApnTypeMobile             = 1,
    WnsSDKApnTypeUnicom             = 2,
    WnsSDKApnTypeTelecom            = 3,
    WnsSDKApnTypeWifi               = 4
};

typedef NS_ENUM(NSInteger, WnsSDKNetworkType) {
    WnsSDKNetworkTypeUnknow         = 0,
    WnsSDKNetworkTypeNone           = 1,
    WnsSDKNetworkType2G             = 2,
    WnsSDKNetworkType3G             = 3,
    WnsSDKNetworkType4G             = 4,
    WnsSDKNetworkTypeWifi           = 5
};

typedef NS_ENUM(NSInteger, WnsSDKReachable){
    WnsSDKNotReachable              = 0,
    WnsSDKReachableViaWWAN          = 1,
    WnsSDKReachableViaWiFi          = 2
};

// APP类型
typedef NS_ENUM(NSInteger, WnsSDKAppType) {
    WnsSDKAppTypeQzone              = 0,    // qzone
    WnsSDKAppTypeOwn                = 1,    // sng内部应用: 微云、k歌、电台、腾讯课堂等
    WnsSDKAppTypeInner              = 2,    // 腾讯内部云: 音乐、企鹅游戏、企鹅电竞助手等
    WnsSDKAppTypeThirdParty         = 3     // 腾讯外部云: 第三方开发商使用
};

typedef NS_ENUM(NSInteger, WnsSDKLoginType) {
    WnsSDKLoginTypeNoAuth      = 0,     //无登录态，wns不做鉴权和加密, 以uid 999透传数据，默认方式，不需要传参数
    WnsSDKLoginTypeWtlogin     = 1,     //qq账号密码登录，或呼起qq/qzone快速登录(获取A1方式，非oauth)，通过wtlogin获取鉴权票据，wns做鉴权和加密，传入Account、Pwd、IsMd5、ForceVerifyPwd、Bitmap（可选）
    WnsSDKLoginTypeOAuthWeChat = 2,     //oauth，通过微信互联sdk获取鉴权票据，wns做鉴权和加密，传入Code
    WnsSDKLoginTypeOAuthQQ     = 3,     //oauth，通过微信互联sdk获取鉴权票据，wns做鉴权和加密，传入Openid、RefreshToken、RefreshTokenExpireDate
    WnsSDKLoginTypeAnonymous   = 4,     //匿名登录，需要登录由后台分配uid，但对用户透明，没有鉴权票据，wns只做加密，不需要传参数
    WnsSDKLoginTypeWid         = 5,     //匿名登录，wns后台分配wid，业务bind(wid+uid)，不需要传参数
    
    WNSSDKLoginTypeCtlogin     = 6,     //账号密码登录，通过ctlogin(sso)获取鉴权票据(ST)，wns做鉴权和加密，传入Uin、ST、STKey
    //WnsLoginType_Extension   = 7,     //extension模式，所有票据由业务赋值，wns做鉴权和加密
    
    WnsSDKLoginTypeFb          = 8,     //oauth，通过facebook sdk获取鉴权票据，wns做鉴权和加密，传入Openid、AccessToken、AccessTokenExpireDate
    WnsSDKLoginTypeGooglePlus  = 9,     //oauth，通过google sdk获取鉴权票据，wns做鉴权和加密
    WnsSDKLoginTypeTwitter     = 10,    //oauth，通过twitter sdk获取鉴权票据，wns做鉴权和加密
    
    WnsSDKLoginTypeTinyID      = 11,     //使用即通的tiny id,类似oauth方式，传入Uid、TinyIDA2
    WnsSDKLoginTypeTempA2      = 12,    //临时, 未经同意请勿使用，传入Uid、A2
};

typedef NS_ENUM(NSInteger, WnsSDKLoginState)
{
    WnsSDKLoginStateOffline,       // 没有登录
    WnsSDKLoginStateOnline,        // 登录成功
    WnsSDKLoginStateLogining,      // 登录中
    WnsSDKLoginStateLogouting,     // 登出中
    WnsSDKLoginStateTokenExpired,  // 本地票据过期
    WnsSDKLoginStateNonlogin       // 无登录态透传
};

typedef NS_ENUM(NSInteger, WnsSDKLoginInfoType)
{
    WnsSDKLoginInfoTypeLoginType              = 0,//WnsLoginType
    WnsSDKLoginInfoTypeLoginState             = 1,//NSNumber, WnsLoginState
    WnsSDKLoginInfoTypeUin                    = 2,//NSString, uin
    WnsSDKLoginInfoTypeUid                    = 3,//NSString, user id
    WnsSDKLoginInfoTypeSuid                   = 4,//NSData, 设备id
    WnsSDKLoginInfoTypePwd                    = 5,//NSString or NSData(md5), wtlogin
    WnsSDKLoginInfoTypeIsMd5                  = 6,//BOOL, wtlogin
    WnsSDKLoginInfoTypeRememberPwd            = 7,//BOOL, wtlogin
    WnsSDKLoginInfoTypeAutoLogin              = 8,//BOOL, wtlogin
    WnsSDKLoginInfoTypeForceVerifyPwd         = 9,//BOOL, wtlogin
    WnsSDKLoginInfoTypeBitmap                 = 10,//uint32_t  eSigType, 指定获取的wtlogin票据类型
    WnsSDKLoginInfoTypeQuickLoginUrl          = 11,//NSURL, wtlogin
    WnsSDKLoginInfoTypeAccount                = 12,//NSString, wtlogin user account, such as qq, phone number, email
    WnsSDKLoginInfoTypeCode                   = 13,//NSString, wechat oauth
    WnsSDKLoginInfoTypeOpenid                 = 14,//NSString, qq oauth
    WnsSDKLoginInfoTypeRefreshToken           = 15,//NSString, qq oauth
    WnsSDKLoginInfoTypeRefreshTokenGenDate    = 16,//NSDate, qq oauth
    WnsSDKLoginInfoTypeRefreshTokenExpireDate = 17,//NSDate, qq oauth
    WnsSDKLoginInfoTypeIsRegister             = 18,//uint32_t
    WnsSDKLoginInfoTypeExtra                  = 19,//NSData, 业务数据，wns只做透传
    WnsSDKLoginInfoTypeQmfToken               = 20,
    WnsSDKLoginInfoTypeLoginUserInfo          = 21,//从wtlogin获取的账号信息
    WnsSDKLoginInfoTypeA2                     = 22,//NSData,
    WnsSDKLoginInfoTypeST                     = 23,//NSData,
    WnsSDKLoginInfoTypeSKEY                   = 24,//NSData,
    WnsSDKLoginInfoTypeVKEY                   = 25,//NSData,
    WnsSDKLoginInfoTypeSTWEB                  = 26,//NSData,
    WnsSDKLoginInfoTypeSTKey                  = 27,//NSData,
    WnsSDKLoginInfoTypeEncA2                  = 28,//NSData,
    WnsSDKLoginInfoTypeB2                     = 29,//NSData,
    WnsSDKLoginInfoTypeB2Key                  = 30,//NSData,
    WnsSDKLoginInfoTypeTinyIDA2               = 31,//NSData,
    WnsSDKLoginInfoTypeAccessToken            = 39,//NSString
    WnsSDKLoginInfoTypeAccessTokenExpireDate  = 40,//NSDate
    WnsSDKLoginInfoTypeSchema                 = 41,//NSString, wtlogin
    WnsSDKLoginInfoTypeBizCode                = 42,//NSString
    WnsSDKLoginInfoTypeBizDesc                = 43,//NSString
    // UserInfo
    //    WnsSDKLoginInfoTypeUserInfoNickname,
    //    WnsSDKLoginInfoTypeUserInfoSex,
    //    WnsSDKLoginInfoTypeUserInfoCountry,
    //    WnsSDKLoginInfoTypeUserInfoProvince,
    //    WnsSDKLoginInfoTypeUserInfoCity,
    //    WnsSDKLoginInfoTypeUserInfoLogo,
    //    WnsSDKLoginInfoTypeUserInfoIsClosed,
};

//push注册场景
typedef enum {
    WnsSDKPushRegisterSceneUnknown = 0,         //未知
    WnsSDKPushRegisterSceneLogin,               //主动登录
    WnsSDKPushRegisterSceneParameterChanged,    //参数变化
    WnsSDKPushRegisterSceneQuickLogin           //自动登录(这里指的是有登陆态的情况下,设置uid后的场景)
} WnsSDKPushRegisterScene;


#pragma mark - 结构参数定义
#define _WNS_CLS __attribute__((visibility("default")))

_WNS_CLS @interface WnsAppInfo : NSObject
@property(nonatomic, assign)  NSInteger   appId;
@property(nonatomic, copy)    NSString    *appName;
@property(nonatomic, copy)    NSString    *appVersion;
@property(nonatomic, copy)    NSString    *qua;
@property(nonatomic, copy)    NSString    *releaseVersion;
@property(nonatomic, copy)    NSString    *buildVersion;
@property(nonatomic, copy)    NSString    *deviceInfo;
@property(nonatomic, assign)  WnsSDKAppType   appType;
@property(nonatomic, assign)  BOOL        disableRunmodeSwitch; // 关闭sdk内部监听前后台切换通知，由业务自行调setApplicationState设置
@property(nonatomic, assign)  BOOL        enableAutoSaveBusinessConfig; // 开启保持业务配置开关，开启后，wns内部会将业务配置存储在本地
@property(nonatomic, weak)    id          sdk;
@end

#endif
