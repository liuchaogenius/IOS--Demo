//
//  QQWalletConfigManager.m
//  QQ
//
//  Created by menghuisu on 2017/8/30.
//

#import "QQWalletConfigManager.h"
#import "JCEObjectConverter.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#define QQWalletService_WalletConfigRequest_ServantName @"Style.UserConfigServer.UserConfigObj"
#define QQWalletService_WalletConfigRequest_FuncName @"getConfig"

#import "NSString+MD5.h"
#import "QQWalletStorageManager.h"
#import "QQWalletRspWalletConfig.h"
#import "QQWalletReqWalletConfig.h"

typedef enum : int {
    QWConfigRefreshTypeDefault          = 0,      //默认都刷新
    QWConfigRefreshTypeLogin            = 1<<0,   //登录立刻刷新
    QWConfigRefreshTypeReconnect        = 1<<1,   //断网重连立刻刷新
    QWConfigRefreshTypeForeground       = 1<<2,   //前后台切换立刻刷新
    QWConfigRefreshTypeLoginWait        = 1<<8,   //登录时检测更新时间间隔,如果超过时间间隔,则刷新
    QWConfigRefreshTypeReconnectWait    = 1<<9,   //断网重连时检测更新时间间隔,如果超过时间间隔
    QWConfigRefreshTypeForegroundWait   = 1<<10,  //前后台切换时检测更新时间间隔,如果超过时间间隔,则刷新
} QWConfigRefreshType;

typedef enum : int {
    QWConfigActionAllUpdate          = 0,   //全量更新
    QWConfigActionUnchanged          = 1,   //没有变化
    QWConfigActionIncrementalUpdate  = 2,   //增量更新
    QWConfigActionBatchUpdate        = 3,   //分批更新
} QWConfigAction;

#define kQQWalletConfigFileName @"kQQWalletConfigFile"
#define kQQWalletConfigRefreshTime 86400  //默认的请求频率时间为1天(单位:秒)
#define kQQWalletConfigReqInterval 5  //请求时间间隔(单位:秒,防止短时间内多次发起拉取请求)
#define kQQWalletBatchReqLimitCount 100  //分批更新请求次数限制

@interface QQWalletConfigManager () {
    NSString *_uin;  //用户uin(用于区分登录还是断网重连,与currentUin不同)
    NSMutableDictionary *_completionBlockCache;  //请求回调缓存(key:请求的sequence value:回调block)
    NSMutableDictionary *_observerDic;  //注册的观察者,拉取到对应配置时通知观察者(key:配置key value:NSArray观察者列表)
    
    //针对全量拉取配置的缓存
    int _refreshType;  //更新策略 bit0: 登录立刻刷新, bit1: 断网重连立刻刷新， bit2: 前后台切换立刻刷新；
                       //        bit8：登录时检测更新时间间隔，如果超过时间间隔，则刷新；bit9：断网重连时检测更新时间间隔，如果超过时间间隔，则刷新；bit10：前后台切换时检测更新时间间隔，如果超过时间间隔，则刷新；
                       //判断条件：if(bit0 == 1 || bit1 == 1 || bit2 == 1 || （(nowtime - lasttime) >= refreshTime && ( bit8 == 1 || bit9 == 1 || bit10 ==1))) { 执行刷新 }
    long _seriesNo;    //系列号,后台生成,用来区分不同的配置版本
    int _refreshTime;   //请求频率时间(单位:秒)
    int _action;  //配置更新操作
    NSTimeInterval _lastReqTime;   //上次请求的时间(单位:秒)
    NSString *_commonMsg;          //公共的配置参数,json格式(暂时没用到)
    NSMutableDictionary *_mConfig;  //所有业务配置(module-value  module:业务的configKey value:业务的配置)
    NSMutableDictionary *_configMapCache;  //JSON类型配置解析好的map缓存(这样业务就无需每次读取配置解析JSON字符串)
    NSTimeInterval _currentReqTime;  //当前已发出请求的时间戳(单位:秒 用于避免短时间内重复发请求)
    NSMutableDictionary *_configVersionDic;  //各个配置的本地版本号(使用服务器时间戳作为本地版本号,配置发生变化时更新本地版本号)
    
    //针对各业务拉取配置的缓存
    NSMutableDictionary *_lastReqTimeDic;  //各业务上次请求的时间
    NSMutableDictionary *_refreshTimeDic;  //各业务请求频率时间
    
    BOOL _isInstanceInit;  //单例是否初始化好了
    int _reqWhen;  //请求时机
    int _batchReqCount;  //分批更新请求次数(终端加个保护,以免后台出错导致终端无限循环请求拉配置)
}
@end

@implementation QQWalletConfigManager

static dispatch_once_t onceToken;
static QQWalletConfigManager *sharedManager;
static NSString *currentUin;  //当前用户Uin

+ (instancetype)sharedManager {
    @synchronized(self) {
        [sharedManager checkCurrentUinIfChanged];
        
        dispatch_once(&onceToken, ^{
            sharedManager = [[QQWalletConfigManager alloc] init];
        });
    }
    
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initManager];
    }
    
    return self;
}

- (void)dealloc {
    [self saveConfigToCache];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initManager {
    DDLogInfo(@"【QQ钱包】配置系统:实例初始化");
//    currentUin = CZ_GetSelfUin();  //TODO...
    _observerDic = [[NSMutableDictionary alloc] init];
    [self resetManager];
    [self readConfigFromCache];
    _isInstanceInit = YES;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountLogoutAction) name:QQAccountLogoutNotification object:nil];  //账号退出通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillEnterForegroundAction) name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivedActionCommand) name:kQQWalletOperationNotification object:nil];  //后台push消息通知  //TODO...
}

//重置
- (void)resetManager {
    DDLogInfo(@"【QQ钱包】配置系统:实例重置");
    
    _uin = nil;
    _completionBlockCache = [[NSMutableDictionary alloc] init];
    _refreshType = 0;
    _seriesNo = 0;
    _lastReqTime = 0;
    _refreshTime = 0;
    _action = 0;
    _commonMsg = nil;
    _currentReqTime = 0;
    _mConfig = [[NSMutableDictionary alloc] init];
    _configMapCache = [[NSMutableDictionary alloc] init];
    _configVersionDic = [[NSMutableDictionary alloc] init];
    _lastReqTimeDic = [[NSMutableDictionary alloc] init];
    _refreshTimeDic = [[NSMutableDictionary alloc] init];
    _reqWhen = 0;
    _batchReqCount = 0;
}

//检查用户是否切换了账号
- (void)checkCurrentUinIfChanged{
    //TODO...
//    NSString *selfUin = CZ_GetSelfUin();
//    //在切换账号的时候，要重新初始化
//    if (selfUin && ![currentUin isEqualToString:selfUin]) {
//        currentUin = selfUin;
//
//        //账号变化了重新加载当前账号配置数据
//        [self resetManager];
//        [self readConfigFromCache];
//    }
}

#pragma mark - Public 对外提供的拉取配置服务接口
//监听者根据业务配置key注册监听更新通知
-(void)registerObserver:(id<QQWalletConfigManagerDelegate>)observer forKey:(NSString *)key {
    @synchronized(self) {
        if (observer && [key length]>0) {
            NSHashTable *observerSet = _observerDic[key];  //弱引用集合
            if (!observerSet) {
                observerSet = [[NSHashTable alloc] init];
                _observerDic[key] = observerSet;
            }
            
            [observerSet addObject:observer];
            
            NSString *className = NSStringFromClass([(id)observer class]);
            DDLogInfo(@"【QQ钱包】配置系统:%s注册配置key=%s", [className UTF8String], [key UTF8String]);
        }
    }
}

//监听者根据业务配置key注销监听更新通知
-(void)unregisterObserver:(id<QQWalletConfigManagerDelegate>)observer forKey:(NSString *)key {
    @synchronized(self) {
        if (observer && [key length]>0) {
            NSHashTable *observerSet = _observerDic[key];
            if (observerSet) {
                [observerSet removeObject:observer];
                
                NSString *className = NSStringFromClass([(id)observer class]);
                DDLogInfo(@"【QQ钱包】配置系统:%s注销配置key=%s", [className UTF8String], [key UTF8String]);
            }
        }
    }
}

//登陆或断网重连时发起请求接口
- (void)requestConfigWhenLoginOrReconnect {
    //TODO...
//    NSString *selfUin = CZ_GetSelfUin();
//    if (_uin==nil || !CZ_StringEqualToString(_uin, selfUin)) {  //登录或切换账号
        [self handleChangeAccountAction];
//    } else {  //断网重连
//        [self handleNetworkReconnectAction];
//    }
}

//根据业务配置key获取配置字符串
- (NSString *)getConfig:(NSString *)key {
    @synchronized(self) {
        if ([key length]>0) {
            NSString *config = _mConfig[key];
            if ([config length] > 0) {  //不存在配置
                DDLogInfo(@"【QQ钱包】配置系统:配置key=%s不存在", [key UTF8String]);
                DDLogInfo(@"【QQ钱包】配置系统:当前所有配置信息 %s", [[_mConfig description] UTF8String]);
            } else {
                DDLogInfo(@"【QQ钱包】配置系统:读取配置信息 %s=%s", [key UTF8String], [config UTF8String]);
            }
            
            return config;
        }
        
        return nil;
    }
}

//根据业务配置key获取解析后的配置对象(JSON类型配置使用该接口,无需自己做JSON字符串解析)
- (id)getConfigObject:(NSString *)key forClass:(Class)className {
    @synchronized(self) {
        if ([key length]>0) {
            id configObject = _configMapCache[key];
            DDLogInfo(@"【QQ钱包】配置系统:读取配置信息 %s", [key UTF8String]);
            if ([configObject isKindOfClass:className]) {
                return [_configMapCache[key] mutableCopy];
            } else {
                //缓存中没有做一次JSON解析
                NSString *config = _mConfig[key];
                NSError *error = nil;
                NSData *configData = [config dataUsingEncoding:NSUTF8StringEncoding];
                if (configData) {
                    configObject = [NSJSONSerialization JSONObjectWithData:configData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error];
                    if (!error && [configObject isKindOfClass:className]) {
                        _configMapCache[key] = configObject;
                        return [configObject mutableCopy];
                    } else {
                        DDLogInfo(@"【QQ钱包】配置系统:配置key=%s不存在", [key UTF8String]);
                        DDLogInfo(@"【QQ钱包】配置系统:当前所有配置信息 %s", [[_mConfig description] UTF8String]);
                    }
                }
            }
        }
        
        return nil;
    }
}

//根据业务配置key获取解析后的配置对象和版本号(JSON类型配置使用该接口,无需自己做JSON字符串解析)
- (id)getConfigObject:(NSString *)key forClass:(Class)className version:(double *)version {
    id configObject = [self getConfigObject:key forClass:className];
    NSNumber *configVersion = _configVersionDic[key];
    *version = [configVersion doubleValue];  //获取配置版本号
    
    return configObject;
}

//根据业务配置key和配置层级的path获取配置层级结构中某个字段值(path格式: A.B.C)
- (id)getConfigObject:(NSString *)key path:(NSString *)path {
    id configObject = nil;
    if ([key length]>0) {
        configObject = [self getConfigObject:key forClass:[NSDictionary class]];
        if (configObject && [path length]>0) {
            NSArray *subKeys = [path componentsSeparatedByString:@"."];
            for (NSString *subKey in subKeys) {
                if ([configObject isKindOfClass:[NSDictionary class]]) {
                    configObject = configObject[subKey];
                }
            }
        }
    }
    
    return configObject;
}

//业务主动请求拉取配置
- (void)requestConfigForBusiness:(long)reqType params:(NSDictionary *)params completion:(QQWalletConfigCompletion)completion {
    //TODO...
//    DDLogInfo(@"【QQ钱包】配置系统:业务请求拉取配置, reqType: %ld", reqType);
//    if (reqType == QQWalletConfigReqTypeAll) {
//        return;
//    }
//
//    if (CZ_IsEmptyStringOrNil(currentUin)) {
//        DDLogInfo(@"【QQ钱包】配置系统:currentUin为空");
//        return;
//    }
//
//    if ([self isTimeToReqValid:reqType]) {
//        [self requestConfigWithReqType:reqType params:params completion:completion];
//    } else {
//        DDLogInfo(@"【QQ钱包】配置系统:无需拉取业务配置, reqType: %ld", reqType);
//
//        //用本地全量配置缓存执行回调
//        if (completion) {
//            completion(_mConfig);
//        }
//    }
}

//业务存储参数信息到配置系统Session中
- (void)setConfigUserSessionParams:(NSDictionary *)params {
    //TODO...
//    DDLogInfo(@"【QQ钱包】设置钱包配置Sesion:param=%s", CZ_getDescription(params));
//    [[QQWalletServiceCenter defaultCenter] requestWalletConfigWithReqType:0 isSetSession:YES params:params completion:^(UniPacket* packet, NSError *error){
//        if (packet && !error) {  //success
//            QQWalletRspWalletConfig *rsp = [packet getObjectAttr:QQWalletService_ResponseObjectAttrKey forClass:[QQWalletRspWalletConfig class]];
//            if (rsp) {
//                DDLogInfo(@"【QQ钱包】SSO请求设置钱包配置Sesion:请求成功");
//                DDLogInfo(@"【QQ钱包】rsp data:%s", CZ_getDescription(rsp));
//                if (rsp.jce_result==0) {  //设置成功
//                    DDLogInfo(@"【QQ钱包】SSO请求设置钱包配置Sesion:设置成功");
//                } else {
//                    DDLogInfo(@"【QQ钱包】SSO请求设置钱包配置Sesion:设置失败 result=%d", rsp.jce_result);
//                }
//            } else {
//                DDLogInfo(@"【QQ钱包】SSO请求设置钱包配置Sesion:解析数据错误");
//                DDLogInfo(@"【QQ钱包】packet data:%s", CZ_getDescription(packet));
//            }
//        } else {  //failed
//            DDLogInfo(@"【QQ钱包】SSO请求设置钱包配置Sesion:请求发生错误");
//        }
//    }];
}

//获取当前客户端配置的版本号
- (long)getCurrentSeriesNo {
    //版本升级逻辑（若手Q版本升级,则将版本号设置为0）(这里不用版本号了，用appid来判断覆盖安装升级，保证灰度用户正常)
    NSString *walletVersionKey = @"QQWalletConfig_QQVersion";
    NSString *currentVersion = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleVersion"];
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:walletVersionKey];
    if (!lastVersion || [currentVersion isEqualToString:lastVersion]) {  //版本发生了变化(如用户升级)
        DDLogInfo(@"【QQ钱包】配置系统:手Q版本升级(%s -> %s)", lastVersion==nil?[@"null" UTF8String]:[lastVersion UTF8String], [currentVersion UTF8String]);
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:walletVersionKey];
        _seriesNo = 0;
    }
    
    return _seriesNo;
}

//获取当前客户端配置的最新时间(最后全量拉取到配置的时间)
- (NSTimeInterval)currentConfigTime {
    return _lastReqTime;
}

#pragma mark - Private
//判断多个业务请求中，是否其中有一个满足更新时间条件
- (BOOL)isTimeToReqValid:(long)reqType {
//    NSTimeInterval currentTime = CZ_getCurrentLocalTime() + CZ_GetServerTimeDiff();  //服务器时间
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    long flag = 1;
    while (reqType != 0) {
        if (reqType & 1) {
            NSString *reqKey = [NSString stringWithFormat:@"%ld", flag];
            NSNumber *lastReqTimeNum = _lastReqTimeDic[reqKey];
            NSTimeInterval lastReqTime = lastReqTimeNum ? [lastReqTimeNum doubleValue] : 0;  //上次请求时间
            NSNumber *refreshTimeNum = _refreshTimeDic[reqKey];
            int refreshTime = refreshTimeNum ? [refreshTimeNum intValue] : 0;  //更新频率
            if (currentTime>lastReqTime+refreshTime) {
                return YES;  //只要有一项业务满足更新时间条件就去请求
            }
        }
        
        reqType = reqType>>1;
        flag = flag<<1;
    }
    
    return NO;
}

#pragma mark - 拉取配置请求
//拉取全量配置
- (void)requestAllConfig:(int)reqWhen {
    if ([currentUin length]>0) {
        DDLogInfo(@"【QQ钱包】配置系统:currentUin为空");
        return;
    }
//    NSTimeInterval currentTime = CZ_getCurrentLocalTime() + CZ_GetServerTimeDiff();  //服务器时间
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if(currentTime-_currentReqTime<kQQWalletConfigReqInterval) {  //离上次发出的请求时间小于5秒的话,就不再发请求了,避免重复请求
        DDLogInfo(@"【QQ钱包】配置系统:短时间内又发请求,舍弃本次拉取");
        return;
    }
    _currentReqTime = currentTime;
    _reqWhen = reqWhen;
    
    NSDictionary *params = @{@"req_when":[NSString stringWithFormat:@"%d",reqWhen]};  //req_when:请求时机（带给后台做区分请求、数据统计分析等）
    [self requestConfigWithReqType:QQWalletConfigReqTypeAll params:params completion:nil];
    DDLogInfo(@"【QQ钱包】配置系统:全量拉取配置 reqWhen=%d", reqWhen);
}

//有效期内拉取全量配置
- (void)requestAllConfigWait:(int)reqWhen {
#ifndef MSFT_FUNCTION  //若不是正式包,则忽略请求频率控制,直接去拉取
//    NSTimeInterval currentTime = CZ_getCurrentLocalTime() + CZ_GetServerTimeDiff();  //服务器时间
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime>_lastReqTime+_refreshTime || _action==QWConfigActionBatchUpdate) {  //分批更新则忽略更新频率控制时间立即去请求
#endif
        DDLogInfo(@"【QQ钱包】配置系统:已过有效期,需拉取配置");
        [self requestAllConfig:reqWhen];
#ifndef MSFT_FUNCTION
    } else {
        DDLogInfo(@"【QQ钱包】配置系统:有效期内,无需拉取配置");
    }
#endif
}

- (void)requestConfigWithReqType:(long)reqType params:(NSDictionary *)params completion:(QQWalletConfigCompletion)completion {
    __weak QQWalletConfigManager *weakSelf = self;
    __block long seq = 0;

    QQWalletReqWalletConfig *req = [[self class] createWalletConfigRequestObjectWithReqType:reqType params:params];
    NSDictionary *busDict = convertJceObjectToDic(req);
    NSMutableDictionary *reqDic = [self packetReqParamSerName:QQWalletService_WalletConfigRequest_ServantName
                                                     funcName:QQWalletService_WalletConfigRequest_FuncName
                                                   reqJceName:@"QQWalletReqWalletConfig"
                                               resposeJceName:@"QQWalletRspWalletConfig"
                                                      busDict:busDict];
    seq = [self sendRequestDict:reqDic completion:^(NSDictionary *result, NSError *error){
        QQWalletConfigManager *strongSelf = weakSelf;
        if (result && error.code == noErr) {  //success
            QQWalletRspWalletConfig *rsp = (QQWalletRspWalletConfig *)convertDicToJceObject(result, [QQWalletRspWalletConfig class]);
            if (rsp) {
                DDLogInfo(@"【QQ钱包】SSO请求钱包配置信息:请求成功");
                DDLogInfo(@"【QQ钱包】rsp data:%@", [rsp description]);

                //解析数据,刷新页面
                [strongSelf parseConfig:rsp seq:seq];
            } else {
                DDLogInfo(@"【QQ钱包】SSO请求钱包配置信息:解析数据错误");
                DDLogInfo(@"【QQ钱包】packet data:%@", [result description]);

                [self removeCompletionBlockBySID:seq];
            }
        } else {  //failed
            DDLogInfo(@"【QQ钱包】SSO请求钱包配置信息:请求发生错误");
            [self removeCompletionBlockBySID:seq];
        }
    }];
    
    if (completion && seq>0) {
        //缓存回调block
        [self setCompletionBlock:completion forSID:seq];
    }
}

+ (QQWalletReqWalletConfig *)createWalletConfigRequestObjectWithReqType:(long)reqType params:(NSDictionary *)params {
    QQWalletReqWalletConfig *req = [QQWalletReqWalletConfig new];
    req.jce_reqType = reqType;
    req.jce_uin = 0;
//    req.jce_platform = [NSString stringWithFormat:@"iOS|%@|%@", [[UIDevice currentDevice] systemVersion], [UIDevice currentDevice].platformString];
    req.jce_version = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleVersion"];
//    req.jce_iNetType = [QQWalletServiceCenterHelper getCurrentNetworkTyp];
    req.jce_lbsInfo = [self createQQWalletLbsLBSInfo];
    req.jce_commonMsg = @"";  //目前没用到(用于扩展)
    req.jce_mParameter = params;
    
    
    req.jce_seriesNo = [[QQWalletConfigManager sharedManager] getCurrentSeriesNo];
    DDLogInfo(@"【QQ钱包】配置系统:拉取请求 req data=%@", [req description]);
    return req;
}

+ (QQWalletLbsLBSInfo *)createQQWalletLbsLBSInfo {
    //    if ([[QQWalletPreLoader sharedInstance]forbidLBSInfo]) { //预加载请求先禁用使用CLLocationManager
    //        return nil;
    //    }
    
    QQWalletLbsGps *gps = [QQWalletLbsGps new];
    
    //通过LBS Engine获取缓存地理位置
//    NSDictionary *dic = [[QQLBSServerEngine instance] getLBSInfoForCacheTime:QQWalletService_LBSInfoCacheTime withClass:[self class]];
//    if (dic) {
//        gps.jce_iLat = [dic[@"lat"] intValue];
//        gps.jce_iLon = [dic[@"lon"] intValue];
//        gps.jce_iAlt = 0;
//    }
    
    QQWalletLbsLBSInfo *lbsInfo = [QQWalletLbsLBSInfo new];
    lbsInfo.jce_stGps = gps;
    
    return lbsInfo;
}

#pragma mark - 配置回包解析处理
//解析处理回包数据
- (void)parseConfig:(QQWalletRspWalletConfig *)configRsp seq:(long)seq {
    if (!configRsp || configRsp.jce_result != 0) {
        DDLogInfo(@"【QQ钱包】SSO请求钱包配置信息:异常result(%d)", configRsp.jce_result);
        [self removeCompletionBlockBySID:seq];
        return;
    }
    
    if (configRsp.jce_reqType == QQWalletConfigReqTypeAll) {  //全量拉取
        _action = configRsp.jce_action;
        DDLogInfo(@"【QQ钱包】配置系统:全量拉取解析 action=%d", _action);
        if (_action==QWConfigActionAllUpdate) {  //配置发生了变化(全量更新)
            DDLogInfo(@"【QQ钱包】配置系统:配置有变化(全量更新)");
            
            //合并去重(保留全量更新前后的所有key,保证新配置里删除、新增的key都能通知到)
            NSSet *keySet = [[NSSet alloc] initWithArray:_mConfig.allKeys];
            keySet = [keySet setByAddingObjectsFromArray:configRsp.jce_mConfig.allKeys];
            
            _refreshType = configRsp.jce_refreshType;
            _seriesNo = configRsp.jce_seriesNo;
            _commonMsg = configRsp.jce_commonMsg;
            _mConfig = [configRsp.jce_mConfig mutableCopy];  //全量覆盖配置
            _batchReqCount = 0;
            
            //通知观察者更新配置
            [self clearConfigMapCache];  //拉到变化了的全量配置时,通知配置更新前清一下map缓存(后台可能删掉了某些配置)
            for(NSString *key in keySet.allObjects) {
//                [self updateConfigMapCacheForKey:key config:_mConfig[key]];  //这里不update map缓存了,直接在上面清掉
                [self updateConfigVersionForKey:key];
                NSNumber *version = _configVersionDic[key];
                [self notifyUpdateConfig:_mConfig[key] forKey:key version:[version doubleValue]];
            }
        } else if (_action==QWConfigActionUnchanged) {  //配置未变化
            DDLogInfo(@"【QQ钱包】配置系统:配置没有更改");
            [self updateLastReqTime:configRsp];
            [self saveConfigToCache];  //保存到缓存
            _batchReqCount = 0;
            
            return;
        } else if (_action==QWConfigActionIncrementalUpdate) {  //配置发生了变化(增量更新)
            DDLogInfo(@"【QQ钱包】配置系统:配置有变化(增量更新)");
            _refreshType = configRsp.jce_refreshType;
            _seriesNo = configRsp.jce_seriesNo;
            _commonMsg = configRsp.jce_commonMsg;
            _batchReqCount = 0;
            
            //部分覆盖更新配置,并通知观察者更新配置
            for(NSString *key in configRsp.jce_mConfig.allKeys) {
                _mConfig[key] = configRsp.jce_mConfig[key];
                [self updateConfigMapCacheForKey:key config:_mConfig[key]];
                [self updateConfigVersionForKey:key];
                NSNumber *version = _configVersionDic[key];
                [self notifyUpdateConfig:_mConfig[key] forKey:key version:[version doubleValue]];
            }
        } else if (_action==QWConfigActionBatchUpdate) {  //配置发生了变化(分批更新)
            DDLogInfo(@"【QQ钱包】配置系统:配置有变化(分批更新)");
            _refreshType = configRsp.jce_refreshType;
            _commonMsg = configRsp.jce_commonMsg;
            
            //部分覆盖更新配置,并通知观察者更新配置
            for(NSString *key in configRsp.jce_mConfig.allKeys) {
                _mConfig[key] = configRsp.jce_mConfig[key];
                [self updateConfigMapCacheForKey:key config:_mConfig[key]];
                [self updateConfigVersionForKey:key];
                NSNumber *version = _configVersionDic[key];
                [self notifyUpdateConfig:_mConfig[key] forKey:key version:[version doubleValue]];
            }
            
            if (_seriesNo!=configRsp.jce_seriesNo && _batchReqCount<kQQWalletBatchReqLimitCount) {  //版本号不一样且不超过分批更新请求限制的次数,才去请求下一批配置
                _batchReqCount++;
                //延迟一定时间后再去请求拉取下一批配置
                NSString *recordUin = [currentUin copy];
                __weak typeof(self) weakSelf = self;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kQQWalletConfigReqInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (weakSelf) {
                        QQWalletConfigManager *strongSelf = weakSelf;
                        if(![[QQWalletConfigManager sharedManager]->_uin isEqualToString:recordUin] || ![currentUin isEqualToString:recordUin]) {  //若延迟时间内切换了账号,则不去拉取下一批配置了
                            DDLogInfo(@"【QQ钱包】拉取下一批配置前切换了账号 currentUin=%s, uin=%s", [currentUin UTF8String], [recordUin UTF8String]);
                        }
                        DDLogInfo(@"【QQ钱包】配置系统:拉取下一批配置 seriesNo=%ld", strongSelf->_seriesNo);
                        [strongSelf requestAllConfig:strongSelf->_reqWhen];
                    }
                });
            }
            
            _seriesNo = configRsp.jce_seriesNo;
        } else {  //其它值不处理
            DDLogInfo(@"【QQ钱包】配置系统:未识别的action=%d", configRsp.jce_action);
            [self updateLastReqTime:configRsp];  //更新上次拉取时间
            [self saveConfigToCache];  //保存到缓存
            _batchReqCount = 0;
            
            return;
        }
        
        [self removeCompletionBlockBySID:seq];
    } else {  //部分拉取
        DDLogInfo(@"【QQ钱包】配置系统:部分拉取解析(reqType=%ld)", (long)configRsp.jce_reqType);
        //更新配置&通知观察者更新配置
        for(NSString *key in configRsp.jce_mConfig.allKeys) {
            _mConfig[key] = configRsp.jce_mConfig[key];
            [self updateConfigMapCacheForKey:key config:_mConfig[key]];
            [self updateConfigVersionForKey:key];
            NSNumber *version = _configVersionDic[key];
            [self notifyUpdateConfig:_mConfig[key] forKey:key version:[version doubleValue]];
        }
        
        //执行部分业务拉取的回调
        QQWalletConfigCompletion completion = [self getCompletionBlockBySID:seq];
        if (completion) {
            completion(configRsp.jce_mConfig);
        }
    }
    
    //全量拉取和部分拉取都需要处理的逻辑
    [self updateRefreshTime:configRsp];  //更新频率时间
    [self updateLastReqTime:configRsp];  //更新上次拉取时间
    [self saveConfigToCache];  //保存到缓存
    
    [self removeCompletionBlockBySID:seq];
}

//更新上次请求时间
- (void)updateLastReqTime:(QQWalletRspWalletConfig *)configRsp {
    long reqType = configRsp.jce_reqType;
//    NSTimeInterval currentTime = CZ_getCurrentLocalTime() + CZ_GetServerTimeDiff();  //服务器时间
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSNumber *lastReqTimeNum = [NSNumber numberWithDouble:currentTime];
    if (reqType == QQWalletConfigReqTypeAll) {  //全量拉取
        _lastReqTime = currentTime;
        for (NSString *key in _lastReqTimeDic.allKeys) {
            _lastReqTimeDic[key] = lastReqTimeNum;
        }
    } else {  //部分拉取
        long flag = 1;
        while (reqType != 0) {
            if (reqType & 1) {
                NSString *key = [NSString stringWithFormat:@"%ld", flag];
                _lastReqTimeDic[key] = lastReqTimeNum;
            }
            
            reqType = reqType>>1;
            flag = flag<<1;
        }
    }
}

//更新请求频率时间
- (void)updateRefreshTime:(QQWalletRspWalletConfig *)configRsp {
    long reqType = configRsp.jce_reqType;
    if (reqType == QQWalletConfigReqTypeAll) {  //全量拉取
        _refreshTime = configRsp.jce_refreshTime>kQQWalletConfigRefreshTime ? kQQWalletConfigRefreshTime : configRsp.jce_refreshTime;  //超过默认时间则使用默认时间
    } else {  //部分拉取
        NSNumber *refreshTimeNum = [NSNumber numberWithInt:configRsp.jce_refreshTime>kQQWalletConfigRefreshTime ? kQQWalletConfigRefreshTime : configRsp.jce_refreshTime];
        long flag = 1;
        while (reqType != 0) {
            if (reqType & 1) {
                NSString *key = [NSString stringWithFormat:@"%ld", flag];
                _refreshTimeDic[key] = refreshTimeNum;
            }
            
            reqType = reqType>>1;
            flag = flag<<1;
        }
    }
}

//通知注册的观察者更新了配置
- (void)notifyUpdateConfig:(NSString *)config forKey:(NSString *)key version:(double)version{
    @synchronized(self) {
        if ([key length]>0) {
            NSHashTable *observerSet = _observerDic[key];
            if (observerSet) {
                NSArray *allObservers = observerSet.allObjects;
                for (id observer in allObservers) {
                    if ([observer respondsToSelector:@selector(didRefreshConfig:forKey:version:)]) {
                        DDLogInfo(@"【QQ钱包】通知%s配置更新:key=%s", [NSStringFromClass([observer class]) UTF8String], [key UTF8String]);
                        //异步通知
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [observer didRefreshConfig:config forKey:key version:version];
                            });
                        });
                    }
                }
            }
        }
    }
}

//配置发生变化了,更新对应配置最近更新时间
- (void)updateConfigVersionForKey:(NSString *)key {
    @synchronized(self) {
        if ([key length]>0) {
//            NSTimeInterval currentTime = CZ_getCurrentLocalTime() + CZ_GetServerTimeDiff();  //服务器时间
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            _configVersionDic[key] = [NSNumber numberWithDouble:currentTime];
        }
    }
}

//更新JSON类型配置的map缓存
- (void)updateConfigMapCacheForKey:(NSString *)key config:(NSString *)config {
    @synchronized(self) {
        if ([key length]>0 && [config length]>0) {
            NSError *error = nil;
            NSData* configData = [config dataUsingEncoding:NSUTF8StringEncoding];
            id configObject = [NSJSONSerialization JSONObjectWithData:configData options:NSJSONReadingMutableContainers error:&error];
            if (!error && configObject) {
                _configMapCache[key] = configObject;
            } else {
                [_configMapCache removeObjectForKey:key];
            }
        }
    }
}

//清楚JSON类型配置的map缓存
- (void)clearConfigMapCache {
    @synchronized(self) {
        if (_configMapCache) {
            [_configMapCache removeAllObjects];
        }
    }
}

#pragma mark - block缓存管理
- (void)setCompletionBlock:(QQWalletConfigCompletion)completion forSID:(long)sid {
    @synchronized (self) {
        if (completion) {
            [_completionBlockCache setObject:completion forKey:[NSString stringWithFormat:@"%ld", sid]];
        }else{
            [_completionBlockCache removeObjectForKey:[NSString stringWithFormat:@"%ld", sid]];
        }
    }
}

- (QQWalletConfigCompletion)getCompletionBlockBySID:(long)sid {
    return _completionBlockCache[[NSString stringWithFormat:@"%ld", sid]];
}

- (void)removeCompletionBlockBySID:(long)sid {
    @synchronized (self) {
        [_completionBlockCache removeObjectForKey:[NSString stringWithFormat:@"%ld", sid]];
    }
}

#pragma mark - 拉取配置时机
//登录/切换账号
- (void)handleChangeAccountAction {
    //TODO...
//    NSString *selfUin = CZ_GetSelfUin();
//    if (selfUin==nil) {
//        DDLogInfo(@"【QQ钱包】配置系统:获取uin失败");
//        return;
//    }
//
//    DDLogInfo(@"【QQ钱包】配置系统:切换账号/登录");
//    _uin = selfUin;
//
    if (_refreshType==QWConfigRefreshTypeDefault || _refreshType&QWConfigRefreshTypeLogin) {
        [self requestAllConfig:QWConfigRefreshTypeLogin];
    } else if(_refreshType & QWConfigRefreshTypeLoginWait) {
        [self requestAllConfigWait:QWConfigRefreshTypeLoginWait];
    }
}

//账号退出登录通知
- (void)handleAccountLogoutAction {
    [self resetManager];  //退出登录时清空manager
}

//断网重连
- (void)handleNetworkReconnectAction {
    DDLogInfo(@"【QQ钱包】配置系统:断网重连");
    if (_refreshType==QWConfigRefreshTypeDefault || _refreshType&QWConfigRefreshTypeReconnect) {
        [self requestAllConfig:QWConfigRefreshTypeReconnect];
    } else if(_refreshType & QWConfigRefreshTypeReconnectWait) {
        [self requestAllConfigWait:QWConfigRefreshTypeReconnectWait];
    }
}

//进入前台
- (void)handleWillEnterForegroundAction {
    DDLogInfo(@"【QQ钱包】配置系统:前后台切换");
    if (_refreshType==QWConfigRefreshTypeDefault || _refreshType&QWConfigRefreshTypeForeground) {
        [self requestAllConfig:QWConfigRefreshTypeForeground];
    } else if(_refreshType & QWConfigRefreshTypeForegroundWait) {
        [self requestAllConfigWait:QWConfigRefreshTypeForegroundWait];
    }
}

//后台push刷新拉取配置
- (void)didReceivedActionCommand:(NSNotification *)notify {
    //TODO...
//    NSDictionary *userInfo = notify.userInfo;
//    QQWalletModule module = [userInfo[@"module"] intValue];
//    QQWalletAction action = [QWActionsharedManager actionForModule:module];
//
//    if (module==QQWalletModuleConfig && QQWalletActionRefresh==action) {
//        [self requestAllConfig:QWConfigRefreshTypeDefault];
//        DDLogInfo(@"【QQ钱包】配置系统:收到后台push通知拉取配置");
//    }
}

#pragma mark - Storage
//从缓存文件中读配置
- (void)readConfigFromCache {
    NSData *configData = [[QQWalletStorageManager sharedInstance] getCacheData:[kQQWalletConfigFileName MD5]];
    if (configData) {
        NSMutableDictionary *configDic = [NSKeyedUnarchiver unarchiveObjectWithData:configData];
        
        NSNumber *refreshType = configDic[@"refreshType"];
        _refreshType = refreshType ? [refreshType intValue] : 0;
        NSNumber *seriesNo = configDic[@"seriesNo"];
        _seriesNo = seriesNo ? [seriesNo longValue] : 0;
        NSNumber *lastReqTime = configDic[@"lastReqTime"];
        _lastReqTime = lastReqTime ? [lastReqTime doubleValue] : 0;
        NSNumber *refreshTime = configDic[@"refreshTime"];
        _refreshTime = refreshTime ? [refreshTime doubleValue] : 0;
        _mConfig = configDic[@"config"]?:[[NSMutableDictionary alloc] init];
        _lastReqTimeDic = configDic[@"lastReqTimeDic"]?:[[NSMutableDictionary alloc] init];
        _refreshTimeDic = configDic[@"refreshTimeDic"]?:[[NSMutableDictionary alloc] init];
        NSNumber *action = configDic[@"action"];
        _action = action ? [action intValue] : 0;
        _configVersionDic = configDic[@"configVersionDic"]?:[[NSMutableDictionary alloc] init];
        
        DDLogInfo(@"【QQ钱包】配置系统:读取本地缓存(%s)", [currentUin UTF8String]);
        
        //数据加载到内存后，统一做一次通知(保证自己做缓存的业务能实时更新数据,否则切换账号时可能还是用前一个账号的配置数据)
        if (_isInstanceInit && [currentUin length]>0) {  //单例第一次初始化时无需通知
            for(NSString *key in _mConfig.allKeys) {
                NSNumber *version = _configVersionDic[key];
                [self notifyUpdateConfig:_mConfig[key] forKey:key version:[version doubleValue]];
            }
        }
    } else {
        DDLogInfo(@"【QQ钱包】配置系统:本地无配置缓存(%s)", [currentUin UTF8String]);
    }
}

//保存配置到缓存文件
- (void)saveConfigToCache {
    @synchronized(self) {
        NSMutableDictionary *configDic = [[NSMutableDictionary alloc] init];
        configDic[@"refreshType"] = [NSNumber numberWithInt:_refreshType];
        configDic[@"seriesNo"] = [NSNumber numberWithLong:_seriesNo];
        configDic[@"lastReqTime"] = [NSNumber numberWithDouble:_lastReqTime];
        configDic[@"refreshTime"] = [NSNumber numberWithDouble:_refreshTime];
        configDic[@"config"] = _mConfig;
        configDic[@"lastReqTimeDic"] = _lastReqTimeDic;
        configDic[@"refreshTimeDic"] = _refreshTimeDic;
        configDic[@"action"] = [NSNumber numberWithInt:_action];
        configDic[@"configVersionDic"] = _configVersionDic;
        
        NSData *configData = [NSKeyedArchiver archivedDataWithRootObject:configDic];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            DDLogInfo(@"【QQ钱包】配置系统:保存配置");
            [[QQWalletStorageManager sharedInstance] saveToCache:configData fileName:[kQQWalletConfigFileName MD5]];
        });
    }
}

@end
