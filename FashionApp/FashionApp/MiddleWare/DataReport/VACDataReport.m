//
//  VACDataReport.m
//  QQMSFContact
//
//  Created by Eric on 15/8/31.
//
//

#import "VACDataReport.h"
#import "VACReportItem.h"
#import "VACReportHeader.h"
#import "VACReportBody.h"
#import "VACReportInfo.h"
#import "VACReportService.h"


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@implementation VACDataReport

- (instancetype)initWithModule:(NSString *)module action:(NSString *)action{
    if (self = [super init]) {
        info = [[VACReportInfo alloc] initWithModule:module action:action];
        timeStamp = info.jce_body.jce_startTime;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillTerminateNotification) name:UIApplicationWillTerminateNotification object:nil];
        
    }
    return self;
}

- (instancetype)initWithReportInfo:(VACReportInfo *)info0{
    if (self = [super init]) {
        info = info0;
        timeStamp = info.jce_body.jce_startTime;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleDidBecomeActiveNotification{
    [self addStep:@"enterForeground" param:nil result:VACD_FOREGROUND failReason:@""];
}

- (void)handleDidEnterBackgroundNotification{
    [self addStep:@"enterBackground" param:nil result:VACD_BACKGROUND failReason:@""];
}

- (void)handleWillTerminateNotification{
    [self commitStep:@"Kill" param:nil result:VACD_KILL failReason:@""];
}

#pragma mark - Public

// * @Discussion 这里在add item的同时，会根据前一个item的时间点，来计算本次add的item的耗时，所以每次在创建item的时候，可以不用填costTime
- (void)addStep:(NSString *)s param:(id)p result:(int32_t)r failReason:(NSString *)f{
    VACReportItem *i = [VACReportItem new];
    i.jce_step = s;
    i.jce_params = [p description];
    i.jce_result = r;
    i.jce_failReason = f;
    
    // 根据时间戳计算cost time
    uint64_t now = [[NSDate date] timeIntervalSince1970] * 1000;
    i.jce_costTime = now - timeStamp;
    timeStamp = now;
    
    //更新一下总耗时
    info.jce_body.jce_totalTime = now - info.jce_body.jce_startTime;
    
    // 最终的result code就直接取最后一步的result
    info.jce_header.jce_result = r;
    
    info.jce_body.jce_reportItems = [info.jce_body.jce_reportItems arrayByAddingObject:i];
    QLog_InfoP(Module_VAC_Wallet, "report add step: %s , param: %s , result: %d , failReason: %s", s.UTF8String, CZ_getDescription(p), r, f.UTF8String);
    [info saveToDisk];
}

- (void)commitStep:(NSString *)s param:(id)p result:(int32_t)r failReason:(NSString *)f{
    [self addStep:s param:p result:r failReason:f];
   
    [self handleUserCancelLogic:(id)p];//用户取消的上报细分

    QLog_InfoP(Module_VAC_Wallet, "report commit, final info");
    [info saveToDisk];
    // 上报到后台
    if (info) {
        [[VACReportService sharedInstance] sendReportInfos:@[info]];
        isCommited = YES;
    }
}


//用户取消的上报细分
- (void)handleUserCancelLogic:(id)lastStepParam
{
    NSArray *reportItems = info.jce_body.jce_reportItems;
    VACReportItem *lastItem  = reportItems.lastObject;
    if (lastItem.jce_result == VACD_USERCANCEL && [lastItem.jce_step isEqualToString:VACD_STEP_SDK_CALLBACK]) { //用户取消
        JceInt32 lastResult = lastItem.jce_result;
        for (NSInteger i = reportItems.count -1 ; i >= 0; i --) {
            VACReportItem *item = reportItems[i];
            if (item.jce_result != 0 && item.jce_result != VACD_USERCANCEL) {//最后一步是取消替换成前面的错误码
                if (item.jce_result != VACD_FOREGROUND) {//进前台的取消过滤
                    lastResult = item.jce_result;
                }
                QLog_InfoP(Module_VAC_Wallet, "report cancel logic %d",lastResult);
                break;
            }
        }
        if (lastResult == VACD_USERCANCEL) { //result码未被替换，上报附加的用户状态信息
            NSDictionary *params = lastStepParam;
            NSInteger cardType = 0;
            if ([params isKindOfClass:[NSDictionary class]]) {
                NSDictionary *data = [params objectForKey:@"data"];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    cardType = [[data objectForKey:@"userCardType"]integerValue];
                    lastResult = (JceInt32)VACD_USERCANCEL_CARDTYPE(cardType);//标记最后一次错误码 带上cardType信息   cardType取值:1 没激活 2 激活但没绑卡 3 有绑卡 4 简化注册无绑卡
                }
            }
            QLog_InfoP(Module_VAC_Wallet, "report cancel logic cardType %ld params %d",(long)cardType,lastResult);
        }
        // 最终的result code就直接取最后一步的result
        info.jce_header.jce_result = lastResult;
    }
}


/**
 * 关键字,所有步骤对应的关键字，如：钱包的tokenId 等
 * @param key 关键字
 */
- (void)setUniqueSKey:(NSString *)key{
    info.jce_body.jce_sKey = key;
    [info saveToDisk];
}

+ (void)commitWithModule:(NSString *)module action:(NSString *)action sKey:(NSString *)key {
    VACDataReport *report = [[VACDataReport alloc] initWithModule:module action:action];
    [report setUniqueSKey:key];
    
    QLog_InfoP(Module_VAC_Wallet, "report commit once, final info: %s", CZ_getDescription(report->info));
    [report->info saveToDisk];
    //上报到后台
    if (report->info) {
        [[VACReportService sharedInstance] sendReportInfos:@[report->info]];
    }
}

+ (void)oneStepReportWithModule:(NSString *)module action:(NSString *)action sKey:(NSString *)key step:(NSString *)s param:(id)p result:(int32_t)r failReason:(NSString *)f {
    VACDataReport *report = [[VACDataReport alloc] initWithModule:module action:action];
    [report setUniqueSKey:key];
    [report commitStep:s param:p result:r failReason:f];
}

@end
