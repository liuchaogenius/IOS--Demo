// **********************************************************************
// This file was generated by a TAF parser!
// TAF version 3.0.0 by WSRD Tencent.
// Generated from `/Users/eric/Documents/Projects/iPhoneQQ_6.0.0_VAC_wallet/Classes/ui/QQWallet/DataReport/JCE/VACDReport.jce'
// **********************************************************************

#import "VACReportHeader.h"
//#import "UIDevice+hw.h"
//#import "MsfSDK.framework/Headers/MsfSDK.h"
//#import <WTLoginSDK/WloginSdk_v2.h>

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

uint32_t CurrentNetworkType(){
    return 0;
//    QNetworkType status = [QNetworkUtil netType];
//    switch (status) {
//        case QNetworkTypeWifi:
//            return 1;
//        case QNetworkType2G:
//            return 2;
//        case QNetworkType3G:
//            return 3;
//        case QNetworkType4G:
//            return 4;
//        default:
//            return 0;
//    }
}

@implementation VACReportHeader

#if JCE_USE_DYNAMIC_PROPERTY
@dynamic JV2_PROP_NM(o,0,platform);
@dynamic JV2_PROP_NM(o,1,version);
@dynamic JV2_PROP_NM(r,2,uin);
@dynamic JV2_PROP_NM(r,3,seqno);
@dynamic JV2_PROP_NM(o,4,sModule);
@dynamic JV2_PROP_NM(o,5,sAction);
@dynamic JV2_PROP_NM(o,6,iNetType);
@dynamic JV2_PROP_NM(o,7,result);
@dynamic JV2_PROP_NM(o,8,IMEI);
@dynamic JV2_PROP_NM(o,9,GUID);
#endif

- (id)init
{
    if (self = [super init]) {
        // platform 字段的格式： os|系统|机型
//        JV2_PROP(platform) = [NSString stringWithFormat:@"iOS|%@|%@", [[UIDevice currentDevice] systemVersion], [UIDevice currentDevice].platformString];
        JV2_PROP(version) = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleVersion"];
//        JV2_PROP(uin) = [CZ_GetAccountService() getUin];
        JV2_PROP(iNetType) = CurrentNetworkType();
        JV2_PROP(seqno) = [[NSDate date] timeIntervalSince1970] * 1000000;
//        JV2_PROP(IMEI) = [[MsfSDK sharedInstance] getIMEI];
//        JV2_PROP(GUID) = [CZ_GetAccountService() getWloginSdk].guidString;
    }
    return self;
}

- (instancetype)initWithModule:(NSString *)module action:(NSString *)action{
    if (self = [self init]) {
        self.jce_sModule = module;
        self.jce_sAction = action;
    }
    return self;
}

+ (NSString*)jceType
{
    return @"MQQ.ReportHeader";
}

@end