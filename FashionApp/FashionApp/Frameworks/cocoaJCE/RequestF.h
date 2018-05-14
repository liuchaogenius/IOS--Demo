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

@interface RequestPacket : JceObject

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
