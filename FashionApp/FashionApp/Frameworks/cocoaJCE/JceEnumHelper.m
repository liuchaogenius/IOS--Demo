
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "JceEnumHelper"
#pragma clang diagnostic pop


//
//  JceEnumHelper.m
//  WirelessUnifiedProtocol
//
//  Created by 壬俊 易 on 12-6-13.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "JceEnumHelper.h"

inline BOOL isJceEnumStringEqual(NSString *s1, NSString *s2)
{
    if (s1 != s2) {
        NSInteger i = s1.length;
        if (i == s2.length) {
            for (i--; i >= 0; i--)
                if ([s1 characterAtIndex:i] != [s2 characterAtIndex:i])
                    return NO;
            return YES;
        }
        return NO;
    }
    return YES;
}

@implementation JceEnumHelper

+ (NSString *)etos:(JceEnum)e
{
    return nil;
}

+ (JceEnum)stoe:(NSString *)s
{
    return JceEnumUndefined;
}

//+ (NSString *)eto_s:(JceEnum)e
//{
//    NSString *className = NSStringFromClass(self);
//    NSString* s = [self etos:e];
//    // 此处为了兼容之前的代码，原则上s不能为@""，当对应枚举值不存在时返回nil
//    if ([s isEqual:@""]) return nil;
//    return [s substringFromIndex:(className.length - 5)];
//}
//
//+ (JceEnum)_stoe:(NSString *)s
//{
//    NSString *className = NSStringFromClass(self);
//    NSString *_s = CZ_NSString_stringWithFormat_c("%@_%@", [className substringToIndex:className.length - 6], s);
//    return [self stoe:_s];
//}

@end
