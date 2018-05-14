//
//  RequestF.mm
//
//  Created by renjunyi on 11-12-1.
//  Copyright (c) 2011年 Tencent. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "JceRequestPacket.h"
#import "JceStream.h"
#import "JCEPair.h"
#import "JceOutputStreamV2.h"
#import "JceInputStreamV2.h"

#pragma mark -

@implementation JceRequestPacket

@synthesize iVersion = _iVersion;
@synthesize cPacketType = _cPacketType;
@synthesize iMessageType = _iMessageType;
@synthesize iRequestId = _iRequestId;
@synthesize sServantName = _sServantName;
@synthesize sFuncName = _sFuncName;
@synthesize sBuffer = _sBuffer;
@synthesize iTimeout = _iTimeout;
@synthesize context = _context;
@synthesize status = _status;

//@dynamic iVersion;
//@dynamic cPacketType;
//@dynamic iMessageType;
//@dynamic iRequestId;
//@dynamic sServantName;
//@dynamic sFuncName;
//@dynamic sBuffer;
//@dynamic iTimeout;
//@dynamic context;
//@dynamic status;



- (id)init
{
	if (self = [super init])
	{
		self.iVersion = @((short)2);
		self.cPacketType = @((short)0);
		self.iMessageType = @0;
		self.iRequestId = @((int)[NSDate timeIntervalSinceReferenceDate]);
		self.sServantName = @"";
		self.sFuncName = @"";
		self.sBuffer = [NSData data];
		self.iTimeout = @0;
		self.context = @{};
		self.status = @{};
	}
	return self;
}


- (void)__pack:(JceOutputStreamV2 *)stream
{
	@autoreleasepool {
        [stream writeNumber:self.iVersion tag:1 required:YES];
        [stream writeNumber:self.cPacketType tag:2 required:YES];
        [stream writeNumber:self.iMessageType tag:3 required:YES];
        [stream writeNumber:self.iRequestId tag:4 required:YES];
        [stream writeString:self.sServantName tag:5 required:YES];
        [stream writeString:self.sFuncName tag:6 required:YES];
        [stream writeData:self.sBuffer tag:7 required:YES];
        [stream writeNumber:self.iTimeout tag:8 required:YES];
        [stream writeDictionary:_context tag:9 required:YES ext:nil];
        [stream writeDictionary:_status tag:10 required:YES ext:nil];
    }
}

- (void)__unpack:(JceInputStreamV2 *)stream
{
	@autoreleasepool {
        self.iVersion = [stream readNumber:1 required:YES];
        self.cPacketType = [stream readNumber:2 required:YES];
        self.iMessageType = [stream readNumber:3 required:YES];
        self.iRequestId = [stream readNumber:4 required:YES];
        self.sServantName = [stream readString:5 required:YES];
        self.sFuncName = [stream readString:6 required:YES];
        self.sBuffer = [stream readData:7 required:YES];
        self.iTimeout = [stream readNumber:8 required:YES];
        self.context = [stream readDictionary:9 required:YES description:[JCEPair pairWithValue:[NSString class] forKey:[NSString class]]];
        self.status = [stream readDictionary:10 required:YES description:[JCEPair pairWithValue:[NSString class] forKey:[NSString class]]];
    }
}

@end
