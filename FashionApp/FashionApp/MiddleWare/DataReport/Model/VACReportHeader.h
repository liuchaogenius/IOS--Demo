// **********************************************************************
// This file was generated by a TAF parser!
// TAF version 3.0.0 by WSRD Tencent.
// Generated from `/Users/eric/Documents/Projects/iPhoneQQ_6.0.0_VAC_wallet/Classes/ui/QQWallet/DataReport/JCE/VACDReport.jce'
// **********************************************************************

#import "JceObjectV2.h"

@interface VACReportHeader : JceObjectV2

// 客户端平台和平台版本，如：Android_4.4.4, IOS_8.4.1
@property (nonatomic, retain, JV2_PROP_GS_V2(platform,setPlatform:)) NSString* JV2_PROP_NM(o,0,platform);
// 客户端版本号，如：5.8.0.2505
@property (nonatomic, retain, JV2_PROP_GS_V2(version,setVersion:)) NSString* JV2_PROP_NM(o,1,version);
// 用户uin
@property (nonatomic, assign, JV2_PROP_GS_V2(uin,setUin:)) JceInt64 JV2_PROP_NM(r,2,uin);
// 系列号(目前用毫秒的时间戳)，跟uin 组成唯一关键字，用来客户端重试和服务端去重
@property (nonatomic, assign, JV2_PROP_GS_V2(seqno,setSeqno:)) JceInt64 JV2_PROP_NM(r,3,seqno);
// 模块名称，各个模块自定义。如： qqwallet， qqwifi 等
@property (nonatomic, retain, JV2_PROP_GS_V2(sModule,setSModule:)) NSString* JV2_PROP_NM(o,4,sModule);
// 操作名称，各个模块的对应操作名称。 如：pay
@property (nonatomic, retain, JV2_PROP_GS_V2(sAction,setSAction:)) NSString* JV2_PROP_NM(o,5,sAction);
// 网络类型, UNKNOWN=0, WIFI=1, 2G=2,  3G=3, 4G=4
@property (nonatomic, assign, JV2_PROP_GS_V2(iNetType,setINetType:)) JceInt32 JV2_PROP_NM(o,6,iNetType);
// 结果，0:成功，非零:失败
@property (nonatomic, assign, JV2_PROP_GS_V2(result,setResult:)) JceInt32 JV2_PROP_NM(o,7,result);
// IMEI
@property (nonatomic, retain, JV2_PROP_GS_V2(IMEI,setIMEI:)) NSString* JV2_PROP_NM(o,8,IMEI);
// GUID
@property (nonatomic, retain, JV2_PROP_GS_V2(GUID,setGUID:)) NSString* JV2_PROP_NM(o,9,GUID);

- (instancetype)initWithModule:(NSString *)module action:(NSString *)action;
    
    
@end