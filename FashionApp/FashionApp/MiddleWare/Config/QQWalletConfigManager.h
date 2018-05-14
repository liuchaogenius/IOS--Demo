//
//  QQWalletConfigManager.h
//  QQ
//
//  Created by menghuisu on 2017/8/30.
//

#import <Foundation/Foundation.h>
#import "QQWalletConfigManagerDefine.h"
#import "FSBaseNetworkService.h"

/**
 *  钱包配置系统协议
#include "LBSInfo.jce"
module Wallet
{
    // FuncName: WalletConfig
    // 请求参数名：ReqWalletConfig
    // 返回参数名：RspWalletConfig
    struct ReqWalletConfig
    {
        0 require long     reqType;         // 请求类型，按照bit 定义, 值为0表示全量拉取 bit1: 获取句有料配置信息 bit2及以后：暂未使用
        1 optional long    uin;             // 用户uin
        2 optional string  platform;        // 客户端平台和版本，如：Android|6.0.0|VIVO X7, iOS|10.0.1|iPhone 7
        3 optional string  version;         // 手Q客户端版本号，如：7.2.0.2505
        4 optional int     iNetType;        // 网络类型： UNKNOWN=0, WIFI=1, 2G=2,  3G=3, 4G=4
        5 optional LBS::LBSInfo lbsInfo;    // 用户的lbs位置信息
        6 optional long    seriesNo;        // 系列号（配置的版本系列号），值为后台返回的seriesNo，初始值 为0，用来区分客户端配置缓存和后台配置是否一致
        7 optional string  commonMsg;       // 公共的配置参数，json格式，用于扩展
        8 optional map<string, string> mParameter;  // 其它请求参数，用于扩展
    };

    struct RspWalletConfig
    {
        0 require int     result;           // 返回码，0表示正常，其它表示异常
        1 require long    reqType;          // 请求类型，按照bit 定义, 值为0表示全量拉取 bit1: 获取句有料配置信息 bit2及以后：暂未使用
        2 require long    seriesNo;         // 系列号，后台生成，用来区分不同的配置版本
        3 optional int    refreshType;      // 终端更新类型（控制终端配置拉取时机）：
                                            // bit0： 登录立刻拉取配置； bit1： 断网重连立刻拉取配置； bit2： 前后台切换立刻拉取配置；
                                            // bit8：登录时检测更新时间间隔，如果超过时间间隔，则拉取配置； bit9： 断网重连时检测更新时间间隔，如果超过时间间隔，则拉取配置； bit10： 前后台切换时检测更新时间间隔，如果超过时间间隔，则拉取配置；
                                            // 终端判断条件： if(bit0 == 1 || bit1 == 1 || bit2 == 1 || ((nowtime - lasttime) >= refreshTime && (bit8 == 1 || bit9 == 1 || bit10 ==1))) {执行拉取配置操作}
        4 optional int    refreshTime;      // 更新时间间隔，单位：秒
        5 optional int    action;           // 更新机制  0：全量更新，配置信息产生了更改； 1：配置信息没有更改； 2：增量更新，只返回发生更改的配置 配置信息包括commonMsg和mConfig
        6 optional string commonMsg;        // 公共的配置参数，json格式，用于扩展
        7 optional map<string, string> mConfig;  // 私有配置信息，格式为 "module"-"value"。 module: 每个模块名称，如："gold_msg" 代表句有料配置、"voice_pwd" 代表语音口令红包配置等，由各个业务模块自己定义； value：表示这个模块对应的配置，通常使用json格式。
    };
};
 */

typedef void(^QQWalletConfigCompletion)(NSDictionary *configMap);

/**
 *  监听配置更新需要实现的Delegate
 *
 */
@protocol QQWalletConfigManagerDelegate
@optional
- (void)didRefreshConfig:(NSString *)config forKey:(NSString *)key version:(double)version;
@end

@interface QQWalletConfigManager : FSBaseNetworkService

+ (instancetype)sharedManager;

/**
 *  监听者根据业务配置key注册监听更新通知
 *
 *  @param observer 注册的监听者
 *  @param key 业务配置key
 */
-(void)registerObserver:(id<QQWalletConfigManagerDelegate>)observer forKey:(NSString *)key;

/**
 *  监听者根据业务配置key注销监听更新通知
 *
 *  @param observer 注册的监听者
 *  @param key 业务配置key
 */
-(void)unregisterObserver:(id<QQWalletConfigManagerDelegate>)observer forKey:(NSString *)key;

/**
 *  登陆或断网重连时发起请求接口
 *
 */
- (void)requestConfigWhenLoginOrReconnect;

/**
 *  根据业务配置key获取配置字符串
 *
 *  @param key 业务配置key
 *  @return 业务配置字符串
 */
- (NSString *)getConfig:(NSString *)key;

/**
 *  根据业务配置key获取解析后的配置对象
 *  (JSON类型配置使用该接口,无需自己做JSON字符串解析)
 *
 *  @param key 业务配置key
 *  @param className 解析后配置的对象类型(NSDictionary或NSArray)
 *  @return 解析后的配置对象
 */
- (id)getConfigObject:(NSString *)key forClass:(Class)className;

/**
 *  根据业务配置key获取解析后的配置对象和版本号
 *  (JSON类型配置使用该接口,无需自己做JSON字符串解析)
 *
 *  @param key 业务配置key
 *  @param className 解析后配置的对象类型(NSDictionary或NSArray)
 *  @param version 配置版本号,内部赋值返回
 *  @return 解析后的配置对象
 */
- (id)getConfigObject:(NSString *)key forClass:(Class)className version:(double *)version;

/**
 *  根据业务配置key和配置层级的path获取配置层级结构中某个字段值
 *
 *  @param key 业务配置key
 *  @param path 该字段值在配置层级的path(格式: A.B.C)
 *  @return 配置中某个字段的值
 */
- (id)getConfigObject:(NSString *)key path:(NSString *)path;

/**
 *  业务主动请求拉取配置
 *
 *  @param reqType 请求type，对应具体业务，多个业务通过各业务请求类型按位或
 *  @param params 请求参数,扩展用
 *  @param completion 拉取到配置后的回调
 */
- (void)requestConfigForBusiness:(long)reqType params:(NSDictionary *)params completion:(QQWalletConfigCompletion)completion;

/**
 *  业务存储参数信息到配置系统Session中
 *
 *  @param params 设置的参数信息
 */
- (void)setConfigUserSessionParams:(NSDictionary *)params;

/**
 *  获取当前客户端配置的版本号
 *
 *  @return 版本号
 */
- (long)getCurrentSeriesNo;

/**
 *  获取当前客户端配置的最新时间(最后全量拉取到配置的时间)
 *
 *  @return 时间(服务器时间)
 */
- (NSTimeInterval)currentConfigTime;


@end
