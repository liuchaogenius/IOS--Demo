//
//  RequestF.h
//
//  Created by renjunyi on 11-12-1.
//  Copyright (c) 2011年 Tencent. All rights reserved.
//

#import "JceObject.h"

#pragma mark -
#pragma mark STRUCT

#pragma mark -

@interface JceRequestPacket : JceObject
{
//    NSNumber     *_iVersion;           // short
//    NSNumber     *_cPacketType;        // char
//    NSNumber     *_iMessageType;       // int
//    NSNumber     *_iRequestId;         // int
//    NSString     *_sServantName;
//    NSString     *_sFuncName;
//    NSData       *_sBuffer;
//    NSNumber     *_iTimeout;           // int
//    NSDictionary *_context;
//    NSDictionary *_status;
//    
//    CZ_DYNAMIC_PROPERTYS_FLAG_VAR
}

@property (nonatomic, strong) NSNumber     *iVersion;           // short
@property (nonatomic, strong) NSNumber     *cPacketType;        // char
@property (nonatomic, strong) NSNumber     *iMessageType;       // int
@property (nonatomic, strong) NSNumber     *iRequestId;         // int
@property (nonatomic, strong) NSString     *sServantName;
@property (nonatomic, strong) NSString     *sFuncName;
@property (nonatomic, strong) NSData       *sBuffer;
@property (nonatomic, strong) NSNumber     *iTimeout;           // int
@property (nonatomic, strong) NSDictionary *context;
@property (nonatomic, strong) NSDictionary *status;

@end
