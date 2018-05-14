//
//  FSMiddleWareInterface.m
//  FashionApp
//
//  Created by 1 on 2018/4/13.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSMiddleWareService.h"
#import "FSDDLogger.h"
#import "FSNetWorkService.h"

#import <Rqd/CrashReporter.h>
@implementation FSMiddleWareService

#pragma mark  初始化log系统
- (void)initDDLoggerSystem
{
    [FSDDLogger initDDLoggerSystem];
}

#pragma mark 初始化crash log系统

- (void) setupCrashReporter {
#ifdef DEBUG
    // 开启SDK的调试信息打印，默认关闭。请务必在Release版本中关闭
    [[CrashReporter sharedInstance] enableLog:YES];
#endif
    
    // 更多配置
    // [self setupAdvancedCrashReporter];
    
    // 初始化使用的AppKey即为App的BundleId。
    // 请注意：必须确保此BundleId已经在rdm.oa.com上有关联的产品，否则上报的数据会被后台忽略
    // 如果应用在灯塔注册过并在灯塔查看崩溃数据，请使用灯塔注册分配的AppKey进行初始化
    [[CrashReporter sharedInstance] installWithAppkey:@"b4b8415596"];
    
    //------------------------------------------
    // 注意：
    // 1. 调试SDK崩溃上报时，请开启SDK日志打印开关，以便在控制台观察SDK到流程日志输出
    // 2. 调试SDK崩溃上报时，请务必在真机上验证，且断开Xcode编译器，否则崩溃会被Xcode拦截而导致SDK无法捕获上报
    // 3. 调试SDK崩溃上报时，请在Window－>Devices窗口查看控制台输出
    // 4. 调试完成后，请务必关闭SDK的日志打印
    //------------------------------------------
}

static int app_crash_handler_callback() {
    // 崩溃回调函数，演示回调函数中可调用的接口方法
    
    // 设置崩溃时
    [[CrashReporter sharedInstance] setUserData:@"" value:@""];
    
    // 获取sdk生成的crash.log
    NSString * crashLog = [[CrashReporter sharedInstance] getCrashLog];
    NSLog(@"CrashLog: %@", crashLog);
    
    // 为崩溃场景添加附件上报
    [[CrashReporter sharedInstance] setAttachLog:@""];
    
    return 0;
}

- (void)setupAdvancedCrashReporter {
    
    // 设置崩溃回调函数，当监听到崩溃时会同步调用，切勿执行耗时操作，以免阻塞崩溃处理流程
    [[CrashReporter sharedInstance] setUserCrashHandlerCallback:&app_crash_handler_callback];
    
    // 设置用户身份信息，默认值为Unknown
    [[CrashReporter sharedInstance] setUserId:@"Unknown"];
    
#ifdef APP_STORE
    // 设置渠道信息，默认值为空, 注意：如果设置渠道信息，上报后，平台显示的版本为Version_Channel的格式
    [[CrashReporter sharedInstance] setChannel:@"App_Store"];
#endif
    
    // 关闭控制台日志上报，默认开启
    [[CrashReporter sharedInstance] enableConsoleLogReport:NO];
    
    // 开启ViewController的记录功能，默认关闭
    [[CrashReporter sharedInstance] enableViewControllerTracking:YES];
    
    // 开启非正常退出事件上报功能，默认关闭
    [[CrashReporter sharedInstance] enableUnexpectedTerminatingDetection:YES];
    // 设置非正常退出事件上报的回调函数，在上报时添加附件信息
    [[CrashReporter sharedInstance] setSigkillReportCallback:NULL];
    
    // 开启崩溃卡顿捕获功能，默认关闭
    [[CrashReporter sharedInstance] enableBlockMonitor:YES];
    // 设置卡顿场景判断的Runloop超时阀值，Runloop超时 > 阀值判定为卡顿场景，默认值3000ms
    [[CrashReporter sharedInstance] setBlockMonitorJudgementLoopTimeout:2000];
    
#ifdef APP_REQUIRED_CHANGE_THIS_CONFIG
    // 修改App的版本信息，默认读取Info.plist文件中的版本信息,并组装成CFBundleShortVersionString(CFBundleVersion)格式，和数据归类有关
    [[CrashReporter sharedInstance] setBundleVer:nil];
    
    // 修改App的BundleId信息，默认读取Info.plist中的CFBundleIdentifier字段，和数据上报和归类统计有关
    [[CrashReporter sharedInstance] setBundleId:nil];
    
    // 设置设备的唯一标识，默认SDK自动生成唯一标识，和联网设备统计相关
    [[CrashReporter sharedInstance] setDeviceId:nil];
#endif
    
}

#pragma mark 文件存储


@end
