// **********************************************************************
// This file was generated by a TAF parser!
// TAF version 3.0.0 by WSRD Tencent.
// Generated from `/Users/menghuisu/Downloads/jce/WalletConfig.jce'
// **********************************************************************

#import "QQWalletReqWalletConfig.h"

@implementation QQWalletReqWalletConfig

#if JCE_USE_DYNAMIC_PROPERTY
@dynamic JV2_PROP_NM(r,0,reqType);
@dynamic JV2_PROP_NM(o,1,uin);
@dynamic JV2_PROP_NM(o,2,platform);
@dynamic JV2_PROP_NM(o,3,version);
@dynamic JV2_PROP_NM(o,4,iNetType);
@dynamic JV2_PROP_NM(o,5,lbsInfo);
@dynamic JV2_PROP_NM(o,6,seriesNo);
@dynamic JV2_PROP_NM(o,7,commonMsg);
@dynamic JV2_PROP_EX(o,8,mParameter,M09ONSStringONSString);
#endif

#ifndef JCE_USE_DYNAMIC_INITIALIZATION
- (id)init
{
    if (self = [super init]) {
        JV2_PROP(platform) = DefaultJceString;
        JV2_PROP(version) = DefaultJceString;
        JV2_PROP(commonMsg) = DefaultJceString;
    }
    return self;
}
#endif

+ (NSString*)jceType
{
    return @"Style.ReqWalletConfig";
}

@end