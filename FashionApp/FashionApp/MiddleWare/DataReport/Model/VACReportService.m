//
//  VACReportService.m
//  QQMSFContact
//
//  Created by Eric on 15/9/1.
//
//

#import "VACReportService.h"
#import "JCEObjectConverter.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "UniPacket.h"
#import "VACReportReq.h"
#import "VACReportRsp.h"
#import "VACDataReport.h"


#define CMD_NAME @"QQWalletPayReportSvc.vacdReportProxy"
#define SUCC                    0   //成功
#define SEQEXIST               -1   //记录已存在
#define DUPLICATEERROR         -2   //去重发生异常
#define TEMERROR               -3   //ckv读取异常
#define TIMER_INTERVAL         600
#define TIME_OUT               900

@implementation VACReportService

static dispatch_once_t once;
static VACReportService *defaultInstance;
static NSString * const kFuncName = @"vacdReportProxy";
static NSString * const kServantName = @"MQQ.VACDReportServer.VACDReportObj";

+ (instancetype)sharedInstance{
    dispatch_once(&once, ^{
        defaultInstance = [VACReportService new];
        defaultInstance->_checkTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:defaultInstance selector:@selector(checkTimerHandler) userInfo:nil repeats:YES];
        [defaultInstance performSelector:@selector(checkTimerHandler) withObject:nil afterDelay:30];
    });
    return defaultInstance;
}

#pragma mark - Public
// 批量上报
- (void)sendReportInfos:(NSArray *)infos{
    VACReportReq *req = [VACReportReq new];
    req.jce_reports = infos;
//    UniPacket *pack = [UniPacket packet];
//    pack.sServantName = kServantName;
//    pack.sFuncName = kFuncName;
//    [pack putObjectAttr:@"req" value:req];
    
    NSDictionary *requestDict = convertJceObjectToDic(req);
    NSDictionary *packDic =[self packetReqParamSerName:kServantName
                                              funcName:kFuncName
                                            reqJceName:@"VACReportReq"
                                        resposeJceName:@"VACReportRsp"
                                               busDict:requestDict];
    [self sendRequestDict:packDic completion:^(NSDictionary *result, NSError *error){
        if (error.code == noErr) {
            VACReportRsp *rspObject = (VACReportRsp *)convertDicToJceObject(result, [VACReportRsp class]);
            // 上报成功的从本地删除, 速度较慢，放到子线程处理
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                for (VACReportHeader *aHeader in rspObject.jce_headers){
                    if (aHeader.jce_result == SUCC || aHeader.jce_result == SEQEXIST) {
                        [VACReportInfo deleteFromDisk:aHeader.jce_seqno];
                    }else{
                        DDLogError(@"上报后台返回失败: %d",aHeader.jce_result);
                    }
                }
                DDLogInfo(@"数据上报成功！");
            });
        }else{
            DDLogError(@"数据上报失败");
        }
    }];
}

#pragma mark - IEngineDispatchDelegate

- (void)checkTimerHandler{
    DDLogInfo(@"VACReportService timer fire");
    NSMutableArray *infosToUpload = [NSMutableArray array];
    NSArray *infos = [VACReportInfo loadFromDisk];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    for (VACReportInfo *info in infos) {
        // 超时了15分钟
        if (now - info.jce_body.jce_startTime/1000 > TIME_OUT) {
            DDLogInfo(@"info time out, ready to upload");
            
            // 增加超时的步骤
            // 取当前最后上报的步骤，如果最后上报的步骤不是“超时”并且也不是“切后台”， 那么就要为它增加一个超时的步骤。
            VACReportItem *i = [info.jce_body.jce_reportItems lastObject];
            if (i.jce_result != VACD_TIMEOUT &&
                i.jce_result != VACD_BACKGROUND &&
                i.jce_result != VACD_KILL) {
                VACDataReport *report = [[VACDataReport alloc] initWithReportInfo:info];
                [report commitStep:@"timeout" param:nil result:VACD_TIMEOUT failReason:@"timeout"];
            }else{
                [infosToUpload addObject:info];
            }
        }
    }
    if (infosToUpload.count > 0) {
        DDLogInfo(@"upload infos");
        [self sendReportInfos:infosToUpload];
    }
}

@end
