//
//  JceObject.h
//
//  Created by godwin.guo on 11-9-29. Modified by renjunyi on 11-12-1.
//  Copyright (c) 2011年 Tencent. All rights reserved.
//

#import "JCEBaseObject.h"

#pragma mark -

typedef BOOL                    JceBool;
typedef char                    JceInt8;
typedef unsigned char           JceUInt8;
typedef short                   JceInt16;
typedef unsigned short          JceUInt16;
typedef int                     JceInt32;
typedef unsigned int            JceUInt32;
typedef long long               JceInt64;
typedef unsigned long long      JceUInt64;
typedef float                   JceFloat;
typedef double                  JceDouble;

#define DefaultJceString        @""
#define DefaultJceData          [NSData data]
#define DefaultJceArray         [NSArray array]
#define DefaultJceDictionary    [NSDictionary dictionary]

#pragma mark - 

@class JceInputStreamV2, JceOutputStreamV2;

@interface JceObject : JCEBaseObject <NSCoding>

+ (id)object;

+ (id)fromData:(NSData *)data;
- (id)fromData:(NSData *)data;
- (NSData *)toData;

+ (NSString *)jceType;
- (NSString *)jceType;

- (void)__pack:(JceOutputStreamV2 *)stream;	// !!! INTERNAL USE ONLY
- (void)__unpack:(JceInputStreamV2 *)stream;	// !!! INTERNAL USE ONLY

@end
