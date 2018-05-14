//
//  VACDataReport.h
//  QQMSFContact
//
//  Created by Eric on 15/8/31.
//
//

#import <Foundation/Foundation.h>
#import "VACReportInfo.h"
#import "VACReportItem.h"

#define QQWALLET_MODULE @"qqwallet"
#define QQWALLETSTAT_MODULE @"QWalletStat"

// 错误码
//668801	parseurl(解析支付参数错误)
//668802	loadPluginStart（开始启动钱包插件）
//668803	loadPluginEnd（钱包插件启动完成）
//668804	callSDK（调用财付通SDK）
//668805	payauth（支付鉴权）
//668806	payauthresult（支付鉴权结果）
//668807	SDKcallback(SDK回调)
#define VACD_TIMEOUT    668808	//  本地超时的错误码
#define VACD_BACKGROUND 668809  //  切换到后台
#define VACD_FOREGROUND 668810  //  切换回前台
#define VACD_KILL       668811  //  进程被杀
#define VACD_PARSEURL   668801  //  参数不合法

#define VACD_USERCANCEL -11001	//  iOS用户取消
#define VACD_USERCANCEL_CARDTYPE(x) (668900 + x)	//  iOS用户取消细分 无错误情况下上报用户绑卡信息 取值:1 没激活 2 激活但没绑卡 3 有绑卡 4 简化注册无绑卡

#define VACD_STEP_SDK_CALLBACK @"SDKCallback"  //SDK回调


// 钱包资源曝光、点击上报action
#define WALLET_SHOW_ACTION_APP      @"appShowReport"        //九宫格曝光
#define WALLET_CLICK_ACTION_APP     @"appReport"            //九宫格点击
#define WALLET_SHOW_ACTION_BANNER   @"bannerShowReport"     //banner曝光
#define WALLET_CLICK_ACTION_BANNER  @"bannerReport"         //banner点击
#define WALLET_SHOW_ACTION_SCREEN   @"screenShowReport"     //全屏弹层曝光
#define WALLET_CLICK_ACTION_SCREEN  @"screenReport"         //全屏弹层点击
#define WALLET_SHOW_ACTION_PULL     @"pullShowReport"       //下拉弹层曝光
#define WALLET_CLICK_ACTION_PULL    @"pullReport"           //下拉弹层点击
#define WALLET_SHOW_ACTION_POP      @"popShowReport"        //普通弹窗曝光
#define WALLET_CLICK_ACTION_POP     @"popReport"            //普通弹窗点击
#define WALLET_SHOW_ACTION_VIDEO    @"videoShowReport"      //视频弹窗曝光
#define WALLET_CLICK_ACTION_VIDEO   @"videoReport"          //视频弹窗点击
#define WALLET_SHOW_ACTION_BELT     @"littleBeltShowReport" //小白条曝光
#define WALLET_CLICK_ACTION_BELT    @"littleBeltReport"     //小白条点击

// 红包相关上报action
#define REDPACK_VOICE_ACTION_MATCH @"voiceRedPackMatch"   // 语音口令红包匹配结果上报action
#define DOWNLOAD_CONFIG_RESOURCE @"downloadReport"          // 配置系统资源下载上报

// 红点系统上报action
#define WALLET_REDPOINT_SHOW  @"QWalletRedShow"   //红点曝光上报
#define WALLET_REDPOINT_CLICK @"QWalletRedClick"  //红点点击上报

/**
支付来源
"pay-h5"：H5支付支付接口
"pay-pcpush"：pc穿越支付接口
"pay-open-h5"：H5开放支付接口
"pay-open-app"：app开放支付接口
"pay-native"：原生支付接口
"pay-public":  公众号开放支付接口
"pay-app": 公众号app支付开放接口
*/

@interface VACDataReport : NSObject{
    @public
    BOOL isCommited;
    @protected
    uint64_t timeStamp;
    VACReportInfo *info;
}

/**
 * 初始化方法
 * @param module 模块名称，各个模块自定义
 * @param action 操作名称，各个模块的对应操作名称
 */
- (instancetype)initWithModule:(NSString *)module action:(NSString *)action;

/**
 * 初始化方法
 * @param info  用已有的info对象来初始化（不常用）
 */
- (instancetype)initWithReportInfo:(VACReportInfo *)info;

/**
 * 添加上报item
 * @param s 步骤名
 * @param r 错误码，成功为0
 * @param f 失败的原因
 */
- (void)addStep:(NSString *)s param:(id)p result:(int32_t)r failReason:(NSString *)f;

/**
 * 上报最后一个item，并提交到后台
 * @param s 步骤名
 * @param r 错误码，成功为0
 * @param f 失败的原因
 */
- (void)commitStep:(NSString *)s param:(id)p result:(int32_t)r failReason:(NSString *)f;

/**
 * 关键字,所有步骤对应的关键字，如：钱包的tokenId 等
 * @param key 关键字
 */
- (void)setUniqueSKey:(NSString *)key;

/**
 * 一次性上报，无需上报item，提交到后台
 * @param module 模块名称，各个模块自定义
 * @param action 操作名称，各个模块的对应操作名称
 * @param key 关键字
 */
+ (void)commitWithModule:(NSString *)module action:(NSString *)action sKey:(NSString *)key;

/**
 * 单步上报，带有一个item，提交到后台
 * @param module 模块名称，各个模块自定义
 * @param action 操作名称，各个模块的对应操作名称
 * @param key 关键字
 * @param s 步骤名
 * @param r 错误码，成功为0
 * @param f 失败的原因
 */
+ (void)oneStepReportWithModule:(NSString *)module action:(NSString *)action sKey:(NSString *)key step:(NSString *)s param:(id)p result:(int32_t)r failReason:(NSString *)f;

@end
