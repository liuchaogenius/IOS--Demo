//
//  CrashReporter.h
//  Version: 2.4.4.1
//
//  Copyright (c) 2017 Bugly. All rights reserved.
//

#import <Foundation/Foundation.h>

// 声明回调函数
#pragma mark - define the callback handler function
typedef int (*RqdCrashHandlerCallback)(void);

typedef const char * (*RqdSigkillReportCallback)(void);

typedef const char * (*RqdBlockReportCallback)(void);

#pragma mark -

#pragma mark - Interface
@interface CrashReporter : NSObject

+ (CrashReporter *)sharedInstance;

#pragma mark - Configuration 初始化之前设置
/**
 * 设置崩溃监听回调函数
 *
 * 替换旧版本 exp_call_back_func = &my_crash_handler 的设置
 *
 */
- (void)setUserCrashHandlerCallback:(RqdCrashHandlerCallback) userCrashHandlerCallback;

/**
 *  是否开启sdk日志打印, 默认为NO, 不打印
 *
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *  @param enabled
 */
- (void)enableLog:(BOOL)enabled;

/**
 *    @brief 是否开启页面跟踪功能，默认关闭
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *    @param enable
 */
- (void)enableViewControllerTracking:(BOOL) enable;

/**
 *    @brief 是否开启控制台日志采集上报功能，默认开启
 *
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *    @param enable 
 */
- (void)enableConsoleLogReport:(BOOL) enable;

/**
 *  是否开启主线程卡顿监控上报功能，默认关闭
 *
 *  如需修改设置, 请在初始化方法之前调用设置
 *
 *  @param 是否开启卡顿上报
 */
- (void)enableBlockMonitor:(BOOL) enable;

/**
 *    @brief  设置卡顿场景判断的Runloop超时阀值，Runloop超时 > 阀值判定为卡顿场景
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *    @param aRunloopTimeout 卡顿阀值，单位毫秒(ms)，默认值 3000 ms，可以在 500 ms <= X < 15000 ms 之间设置
 */
- (void)setBlockMonitorJudgementLoopTimeout:(NSTimeInterval) aRunloopTimeout;

/**
 *    @brief  设置是否 开启/关闭 非正常闪退异常捕获，默认关闭
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *    @param  enable 开启/关闭 
 */
- (void)enableUnexpectedTerminatingDetection:(BOOL)enable;

/**
 * 添加非正常退出事件的回调函数，添加附件信息上报。
 *
 */
- (void)setSigkillReportCallback:(RqdSigkillReportCallback)callback;

/**
 * 添加卡顿监控的回调函数，添加附加信息上报。 请勿执行耗时操作
 */
- (void)setBlockReportCallback:(RqdBlockReportCallback)callback;

/**
 *    @brief  设置渠道标识, 默认为空值
 *
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *    @param channel 渠道标记
 */
- (void)setChannel:(NSString *)channel;

/**
 *    @brief  设置应用的版本，在初始化之前调用。
 *    SDK默认读取Info.plist文件中的版本信息,并组装成CFBundleShortVersionString(CFBundleVersion)格式
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *    @param bundleVer 自定义的版本信息
 */
- (void)setBundleVer:(NSString *)bundleVer;

/**
 *    @brief  设置设备标识, SDK默认使用CFUDID标识设备
 *    注意: 平台依据deviceId统计用户数, 如果设置修改, 请保证其唯一性
 *
 *    如需修改设置, 请在初始化方法之前调用设置
 *    @param deviceId
 */
- (void)setDeviceId:(NSString *)deviceId;

#pragma mark -

#pragma mark -

/**
 *    @brief  初始化SDK接口并启动崩溃捕获上报功能
 *
 *    @param appKey 应用标识, 在平台注册时分配的应用标识
 *
 *    @return
 */
- (BOOL)installWithAppkey:(NSString *)appKey;

/**
 *    @brief  初始化SDK接口并启动崩溃捕获上报功能, 如果你的App包含Application Extension或App Watch扩展，可以采用此方法初始化
 *
 *    @param appKey 应用标识, 在平台注册时分配的应用标识
 *    @param identifier AppGroup标识, 开启App-Groups功能时, 定义的Identifier
 *
 *    @return
 */
- (BOOL)installWithAppkey:(NSString *)appKey applicationGroupIdentifier:(NSString *)identifier;

/**
 *  @brief 处理 WatchKit Extension 上报的异常信息
 *
 *    @param userInfo 异常信息
 *    @param reply    回复信息
 */
- (void)handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply;

/**
 *    @brief  设置用户标识, SDK默认值为Unknown
 *    建议在初始化之前使用App本地缓存的用户标识设置, 在用户登录态验证通过或切换时调用进行修改
 *    @param userid
 */
- (void)setUserId:(NSString *)userid;

/**
 *    @brief  设置场景标签, 如支付、后台等
 *
 *    @param tag 自定义的场景标签Id, 可以在服务平台页面进行配置
 */
- (void)setSceneTag:(NSUInteger) tag;

/**
 *    @brief 获取当前标签的值
 *
 *    @return
 */
- (NSUInteger)currentSceneTag;

/**
 *    @brief  添加场景关键数据
 *
 *    @param value 内容, 最大长度限定为512字符
 *    @param key 自定义key(只允许字母和数字), 支持在服务平台页面进行检索
 */
- (void)setSceneValue:(NSString *) value forKey:(NSString *) key;

/**
 *    @brief 获取指定Key对应的值
 *
 *    @param key
 *
 *    @return
 */
- (NSString *)sceneValueForKey:(NSString *) key;

/**
 *    @brief 获取所有的自定义键值对数据
 *
 *    @return
 */
- (NSDictionary *)allSceneValues;

/**
 *    @brief 删除指定的数据
 *
 *    @param key
 */
- (void)removeSceneValueForKey:(NSString *) key;

/**
 *    @brief 清空自定义键值对数据
 */
- (void)removeAllSceneValues;

/**
 *    @brief  上报已捕获的异常信息
 *
 *    @param anException 异常对象
 *    @param aReason    异常发生的原因
 *    @param dict        异常发生时的附加数据
 */
- (void)reportException:(NSException *) anException reason:(NSString *) aReason extraInfo:(NSDictionary *) dict;

/**
 *    @brief  上报错误
 *
 *    @param anError  错误对象
 *    @param aReason 错误发生的原因
 *    @param dict     错误发生时的附加数据
 */
- (void)reportError:(NSError *) anError reason:(NSString *) aReason extraInfo:(NSDictionary *) dict;

/**
 *    @brief  上报自定义异常信息
 *
 *    @param category     类别，C# ＝ 4，JS ＝ 5，Lua = 6
 *    @param aName       异常名称
 *    @param aReason     异常发生的原因
 *    @param aStackTrace 异常堆栈，换行使用\n连接
 *    @param dict         异常发生时附加数据
 *    @param terminate    是否中止应用
 */
- (void)reportException:(NSUInteger) category name:(NSString *) aName reason:(NSString *) aReason callStack:(NSString *) aStackTrace extraInfo:(NSDictionary *) dict terminateApp:(BOOL) terminate;

/**
 *    @brief  上报一个ObjC的异常信息
 *
 *    @param anException 上报的OC异常, sdk会处理其name、reason属性, 以及callStackSymbols
 *    @param aMessage    附带的信息
 *
 *    @deprecated This method is deprecated starting in version 1.3.0
 *    @note Please use @code reportException:reason:extraInfo: @endcode instead.
 */
- (void)reportException:(NSException *)anException message:(NSString *) aMessage __deprecated_msg("1.3.0");

#pragma mark -

#pragma mark - Interface More ...
/**
 *  @brief 查看SDK的版本
 *
 *  @return SDK的版本信息
 */
- (NSString *)sdkVersion;

/**
 *    @brief  当卡顿功能开启时，可调用此接口在运行时启用卡顿监控线程
 */
- (void)startBlockMonitor;

/**
 *    @brief  当卡顿功能开启时，可调用此接口在运行时停止卡顿监控线程
 */
- (void)stopBlockMonitor;

/**
 *    @brief  检查本地的卡顿数据记录并上报
 */
- (BOOL)checkBlockDataExistAndReport;

/**
 *    @brief  获取SDK记录保存的设备标识
 *
 *    @return
 */
- (NSString *)deviceIdentifier;
#pragma mark -

#pragma mark - Test case for make the crash
/**
 *    @brief  触发一个ObjC的异常
 */
- (void)testThrowNSException;

/**
 *    @brief  触发一个错误信号
 */
- (void)testSignalError;
#pragma mark -

/**
 *    @brief 自定义应用Bundle Identifier
 *    如需修改设置, 请在初始化方法之前调用设置
 *
 *    @param bundleId 应用Bundle Identifier
 */
- (void)setBundleId:(NSString *)bundleId;

/**
 *    @brief 清理向系统注册的UncaughtException处理函数和Signal处理函数
 *    注意: 如果你不知道此接口方法的作用，请勿乱用
 */
- (void)cleanUncaughtExceptionAndSignalHandler;

/**
 *    @brief  崩溃发生时, 添加附件内容。 在回调方法中调用
 *
 *    @param attachment 附件内容, 字符最大长度为10 * 1024
 */
- (void)setAttachLog:(NSString *)attachment;

/**
 *    @brief 崩溃发生时, 添加场景关键数据。 在回调方法中调用
 *
 *    @param value 内容, 最大长度限定为512字符
 *    @param key 自定义key
 */
- (void)setUserData:(NSString *)key value:(NSString *)value;

/**
 *    @brief  获取当前捕获到Obj-C异常
 *
 *    @return 返回捕获的Obj-C异常，当只有信号错误时，返回nil
 */
- (NSException *)getCurrentException;

/**
 *    @brief  获取Crash线程地址堆栈
 *
 *    @return 返回Crash线程的地址堆栈
 */
- (NSString *)getCrashStack;

/**
 *    @brief  获取崩溃错误类型
 *
 *    @return 返回错误类型，Obj-C异常名称或错误信号类型
 */
- (NSString *)getCrashType;

/**
 *    @brief 获取捕获的崩溃日志文件内容
 *
 *    @return
 */
- (NSString *)getCrashLog;

/**
 *  是否开启ATS，默认值YES.
 *  如果你确定不需要此功能，你可以在初始化sdk之前调用此接口禁用功能.
 *
 *  @param enable
 */
- (void)enableAppTransportSecurity:(BOOL)enable __deprecated_msg("不允许关闭ATS支持");

/**
 * 设置是否开启进程内堆栈还原功能, 默认开启
 * 注意：当Xcode的编译设置Strip Style为ALL Symbols时，该进程内堆栈还原结果可能有偏差
 *
 */
- (void)setEnableSymbolicateInProcess:(BOOL)enable;

@end
