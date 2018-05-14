
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "JceStream"
#pragma clang diagnostic pop

//
//  JceStream.m
//
//  Created by 壬俊 易 on 12-1-13.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "JceStream.h"

@implementation JceStream

@class JceInputStream;
@class JceOutputStream;

@synthesize streamBuffer = _streamBuffer;
@synthesize streamSize = _streamSize;
@synthesize cursor = _cursor;

//CZ_DYNAMIC_PROPERTYS_FLAG_VAR build fail
//@dynamic  streamBuffer;
//@dynamic streamSize;
//@dynamic	cursor;


- (NSData *)data
{
    return nil;
}

- (NSString *)description
{
    NSData *originData = [self data];
    ASSERT_TRHOW_WS_EXCEPTION(_cursor <= originData.length);
    
    UInt8 *buff = (UInt8 *)malloc(sizeof(UInt8) * originData.length);
    [originData getBytes:buff length:originData.length];
    NSString *description = [NSString stringWithFormat:@"%@ ^cursor %@",
                             [NSData dataWithBytes:buff length:_cursor],
                             [NSData dataWithBytes:(buff + _cursor) length:(originData.length - _cursor)]];
    free(buff);
    return description;
}

@end
