// **********************************************************************
// This file was generated by a TAF parser!
// TAF version 3.0.0 by WSRD Tencent.
// Generated from `/Users/a1/newApp/ResStruct.jce'
// **********************************************************************

#import "JceObjectV2.h"
#import "FSStyleCosCredential.h"

@interface FSStyleApplyUploadRsp : JceObjectV2

@property (nonatomic, assign, JV2_PROP_GS_V2(ret_code,setRet_code:)) JceInt32 JV2_PROP_NM(o,0,ret_code);
@property (nonatomic, retain, JV2_PROP_GS_V2(ret_msg,setRet_msg:)) NSString* JV2_PROP_NM(o,1,ret_msg);
@property (nonatomic, retain, JV2_PROP_GS_V2(upload_id,setUpload_id:)) NSString* JV2_PROP_NM(o,2,upload_id);
@property (nonatomic, retain, JV2_PROP_GS_V2(appid,setAppid:)) NSString* JV2_PROP_NM(o,3,appid);
@property (nonatomic, retain, JV2_PROP_GS_V2(cos_key,setCos_key:)) FSStyleCosCredential* JV2_PROP_NM(o,4,cos_key);
@property (nonatomic, retain, JV2_PROP_GS_V2(video_sign,setVideo_sign:)) NSString* JV2_PROP_NM(o,5,video_sign);

@end