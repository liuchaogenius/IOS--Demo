//
//  WnsSDK.h
//  WnsSDK
//
//  Created by astorli on 5/14/15.
//  Copyright (c) 2015 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WnsCommonDefine.h"
#import "WnsErrorCode.h"

typedef void (^WnsLogBlock)(NSString *log, WnsSDKLogLevel level);
typedef void (^WnsStatusBlock)(WnsSDKStatus status);

_WNS_CLS @interface WnsSDK : NSObject

@property (nonatomic, assign) WnsSDKStatus status;       // wns当前状态
@property (nonatomic, assign) WnsSDKLoginType loginType; // 设置Wns登陆类型，云版本不需要设置，默认为WnsSDKLoginTypeWid

#pragma mark - 初始化

/*! @brief 初始化WnsSDK。此接口需在application:didFinishLaunchingWithOptions:调用
 *
 * @param appID 第三方应用的标识ID
 * @param appVersion 第三方应用的版本号
 * @param appChannel 第三方应用发布渠道
 */
- (instancetype)initWithAppID:(int)appID
                andAppVersion:(NSString *)appVersion
                andAppChannel:(NSString *)appChannel;

/*! @brief 初始化WnsSDK。
 *
 * @param appID 应用的标识ID
 * @param appVersion 应用的版本号
 * @param appChannel 应用发布渠道
 * @param andAppType 应用类型
 */
- (instancetype)initWithAppID:(int)appID
                andAppVersion:(NSString *)appVersion
                andAppChannel:(NSString *)appChannel
                   andAppType:(WnsSDKAppType)appType;

/*! @brief 重置wns连接
 *
 * @param reconnect YES先关闭现有WNS通道再重新建立，NO只关闭现有WNS通道
 */
- (void)reset:(BOOL)reconnect;


/*! @brief 获取WnsSDK 状态。
 *
 * @param block 回调Block
 */
- (void)setStatusCallback:(WnsStatusBlock)block;


/*! @brief 获取WnsSDK LOG。
 *
 * @param block 回调Block
 */
- (void)setLogCallback:(WnsLogBlock)block;

#pragma mark - 请求

/*! @brief 发送请求(TCP协议接口)。
 *
 * @param data 第三方应用应用层数据
 * @param cmd 第三方应用应用层请求命令字
 * @param timeout 请求超时时间,单位ms
 * @param completion 回调Block，参数data表示服务器应答数据，参数bizError表示第三方业务错误，参数wnsError表示Wns内部错误，wnsSubError表示Wns的子类错误
 * @return 成功返回请求序列号，失败返回-1。
 */
- (long)sendRequest:(NSData *)data
                cmd:(NSString *)cmd
            timeout:(unsigned int)timeout
         completion:(void(^)(NSString *cmd, NSData *data, NSError *bizError, NSError *wnsError, NSError *wnsSubError))completion;


/*! @brief 发送请求(HTTP协议接口)。
 *
 * @param request 第三方应用应用层HTTP请求
 * @param cmd 第三方应用应用层请求命令字
 * @param timeout 请求超时时间,单位ms
 * @param completion 回调Block，参数data表示服务器应答数据，参数wnsError表示Wns内部错误，参数wnsSubError表示Wns的子类错误。当请求被取消时，该block也会被调用
 * @return 成功返回请求序列号，失败返回-1。
 */
- (long)sendHTTPRequest:(NSURLRequest *)request
                    cmd:(NSString *)cmd
                timeout:(unsigned int)timeout
             completion:(void (^)(NSString *cmd, NSURLResponse* response, NSData* data, NSError* wnsError, NSError *wnsSubError))completion;


/*! @brief 取消请求。根据调用的时机不同,取消未必能成功
 *
 * @seqno 请求序列号。
 */
- (void)cancelRequest:(long)seqno;

/*! @brief 取消所有请求
 *
 */
- (void)cancelAllRequest;

#pragma mark - 账号
/**
 *  获取当前使用的login manager实例
 *
 *  @return 实例的引用,可以转为具体某个登陆类型的协议实例，协议参考WnsLoginProtocol及其子协议
 */
- (id)loginManager;

/*! @brief
 * 第三方应用层可选调用接口。如果第三方应用后台需要通过WNS服务发送针对指定用户的数据，
 * 则第三方应用终端，在用户登录成功后，需要绑定第三方用户ID到WNS服务。
 * 对新uid进行绑定前, 需要使用unbind对旧bid进行解绑
 *
 * @param uid 第三方应用的用户唯一标识
 * @param completion 回调Block
 */
- (void)bind:(NSString *)uid completion:(void(^)(NSError *error))completion __attribute__ ((deprecated("Use '-loginManager bind' instead.")));


/*! @brief 注销绑定。应用的用户注销时请调用该接口.
 *
 * @param uid 第三方应用的用户唯一标识
 * @param completion 回调Block
 */
- (void)unbind:(NSString *)uid completion:(void(^)(NSError *error))completion __attribute__ ((deprecated("Use '-loginManager unbind' instead.")));

/*! @brief 获取当前用户的wid
 *
 */
- (int64_t)wid __attribute__ ((deprecated("Use '-loginManager wid' instead.")));

#pragma mark - PUSH

/*! @brief 是否注册过push (仅保存在内存，非持久化)
 *
 * @return 已注册过返回YES，否则返回NO
 */
//- (BOOL)isRegisterPush;

/*! @brief 设置Wns Push的数据接收block。
 *
 * @param completion 回调Block，参数cmd标识服务推送数据命令字，参数data标识服务器推送数据，参数error标识错误信息
 */
- (void)setPushDataReceiveBlock:(void(^)(NSString *cmd, NSData *data, NSError *error))completion;

/*! @brief 向服务器注册苹果的推送服务所使用的devicetoken
 *
 * @param deviceToken 用户设备Tokon。
 * @param completion 回调Block, error为nil时表示注册成功
 */
- (void)registerRemoteNotification:(NSString *)deviceToken completion:(void(^)(NSError *error))completion;

#pragma mark - 调试

/*! @brief 设置自动测试模式,这种模式下,sdk自身会定时发送测试数据包到后台,您可以从监控报表查看相关统计数据
 *
 * @param isEnable 是否打开自动测试模式
 *
 */
- (void)setAutoTestMode:(BOOL)isEnable;

/*! @brief 调试接口：设置调试服务器地址。
 *
 * @param ip 为nil或@"wns.qq.com"时切换回非调试模式
 * @param port 允许为0，即默认80/443/8080/14000轮询
 *
 * @note 会触发重建链接
 */
- (void)setDebugIP:(NSString *)ip port:(unsigned short)port;

/*! @brief 获取wns的关键的日志信息,用于开发中查问题
 *
 */
- (NSString *)keyLog;

/*! @brief 删除wns链接配置信息
 *
 */
+ (void)removeConfigFile;

/*! @brief 清空账号数据
 *
 */
+ (void)clearAllLoginResource;

#pragma mark - log

/*! @brief 设置log级别，数值越大越详细
 *  @param level
 */
- (void)setLogLevel:(WnsSDKLogLevel)level;

/*! @brief 设置每天日志大小
 *
 */
- (void)setMaxDayFileSizeM:(int)size;

/*! @brief 记日志
 *
 *  @param module 模块区分，日志里展示为[M:module]
 *  @param extDict 日志里展示为[key:value]...
 */
- (void)log:(int)level file:(const char *)file func:(const char *)func line:(int)line module:(NSString*)module EFDict:(NSDictionary *)extDict msg:(NSString *)fmt, ... NS_FORMAT_FUNCTION(7, 8);

/*! @brief 调试接口：上报WNS内部LOG。
 *
 * @param beginTime/endTime (timeIntervalSince1970) 以天为单位取创建时间小于结束时间且修改时间大于开始时间的log；都为0则默认取最新一天的log(小于500k附加前一天log)
 *
 * @note 查询log地址：http://app.qcloud.com/
 */
- (void)reportDebugLog:(NSString *)title content:(NSString *)content beginTime:(NSTimeInterval)beginTime endTime:(NSTimeInterval)endTime;

/*! @brief 获取WnsSDK LOG当天的log文件，会阻塞线程执行。
 *
 */
- (NSString *)showLogFile;

/*! @brief 按天合并WnsSDK LOG文件，会阻塞线程执行。
 *
 */
- (void)mergeLogFileByDay;

/*! @brief 获取WnsSDK LOG所有的log文件，会阻塞线程执行。
 *
 */
- (NSArray *)mergedLogArray;

/*! @brief 强制日志刷新写回
 * @note 建议在检测到程序即将退出时调用一下
 */
- (void)flushLog;

#pragma mark wns网络连接

+ (WnsSDKNetworkType)getNetworkType;

+ (WnsSDKReachable)getNetworkReachable;

- (WnsSDKApnType)getCurrentApn;

/*! @brief 调试接口：取得运营商信息。
 * 支持WiFi连接下取接入运营商
 *
 */
- (WnsSDKCarrierType)getWnsCarrierType;

/*! @brief 调试接口:WiFi连接下取接入运营商
 *
 */
- (WnsSDKCarrierType)getWifiCarrierType;

/*! @brief 调试接口:取得后台返回的运营商信息
 *
 */
- (WnsSDKCarrierType)getWWANCarrierTypeWithClientInfo;

/*! @brief 获取客户端网络信息
 *  key参考头文件说明:kWnsClientInfoNotify
 *
 */
- (NSDictionary *)getClientInfo;

- (void)clientInfoChanged:(NSNotification *)n;

@end
