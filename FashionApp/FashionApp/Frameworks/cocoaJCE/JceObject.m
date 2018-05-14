
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "JceObject"
#pragma clang diagnostic pop

//
//  JceObject.m
//
//  Created by godwin.guo on 11-9-29. Modified by renjunyi on 11-12-1.
//  Copyright (c) 2011年 Tencent. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "JceObject.h"
#import <objc/runtime.h>
#import "JCEPropertyInfo.h"
#import "JceInputStreamV2.h"
#import "JceOutputStreamV2.h"

@implementation JceObject

+ (id)object
{
    return [self new];
}

+ (id)fromData:(NSData *)data
{
    if ([data length] != 0) 
        return [[[self alloc] init] fromData:data];
    return nil;
}

- (id)fromData:(NSData *)data
{
    if ([data length] != 0)
    {
        @try {
            JceInputStreamV2 *stream = [JceInputStreamV2 streamWithData:data];
            [self __unpack:stream];
            return self;
        }
        @catch (NSException *exception) {
//            NSLog(@"%@", exception);
        }
    }
    return nil;
}

- (NSData *)toData
{
    NSData* data = nil;
    JceOutputStreamV2 *stream = [JceOutputStreamV2 new];
    @try {
        [self __pack:stream];
        data = [stream data];
    }
    @catch (NSException *exception) {
//        NSLog(@"%@", exception);
    }
    @finally {
        stream = nil;
    }
    return data;
}

+ (NSString *)jceType
{
    return nil;
}

- (NSString *)jceType
{
    return [[self class] jceType];
}

- (void)__pack:(JceOutputStreamV2 *)stream
{
    ASSERT_TRHOW_WS_EXCEPTION(NO);
}

- (void)__unpack:(JceInputStreamV2 *)stream
{
    ASSERT_TRHOW_WS_EXCEPTION(NO);
}

static NSString *genTab(int indentNum)
{
    NSMutableString* indent =  [NSMutableString string];
    for(int i=0; i < indentNum; i++) {
        [indent appendString:@"    "];
    }
    return indent;
}

- (NSString *)description
{
    static int indent=0;

    NSMutableString *description = [NSMutableString new];
    [description appendString:@"\r"];
    [description appendString:genTab(indent)];
    [description appendString:@"{\r"];

    indent++;

    [self.class.propertyInfos enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        if (info.isJCE) { // 因为有一些 property 是通过 associateObject 加进去的，实用 KVC 会导致异常
            [description appendString:genTab(indent)];
            [description appendFormat:@"%@: %@\r", NSStringFromSelector(info.getter), [self valueForKey:info.name]];
        }
    }];

    indent--;
    [description appendString:genTab(indent)];
    [description appendString:@"}\r"];

    return description;
}

#pragma mark - NSCoding

- (Class)classForKeyedArchiver
{
    // 防止 unarchive 的时候没有找到动态生成的子类
    if ([NSStringFromClass(self.class) hasPrefix:JCEDynamicSubclassPrefix]) {
        return [self superclass];
    }

    return self.class;
}

- (Class)classForCoder
{
    // 防止 unarchive 的时候没有找到动态生成的子类
    if ([NSStringFromClass(self.class) hasPrefix:JCEDynamicSubclassPrefix]) {
        return [self superclass];
    }

    return self.class;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeObject:[self toData] forKey:@"jceData"];
    
    // 处理子类 properties
    [[self.class propertyInfos] enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        if (info.readonly && !info.ivar) {
            return;
        }
        
        if (!info.ivar && !info.dynamic) {
            return;
        }
        
        if (info.isJCE) return;
        
        NSString *key = info.name;
        
        id object = nil;
        
        @try {
            object = [self valueForKey:key];
        }
        @catch (NSException *exception) {
            object = nil;
        }
        
        if (!object) return;
        
        BOOL weak = info.weak;
        
        NSAssert([object conformsToProtocol:@protocol(NSCoding)] || [object conformsToProtocol:@protocol(NSSecureCoding)],
                 @"Class <%@> must conforms to NSCoding or NSSecureCoding", [object class]);
        
        @try {
            if (weak) [aCoder encodeConditionalObject:object forKey:key];
            else      [aCoder encodeObject:object forKey:key];
        }
        @catch (NSException *ex) {
            @throw ex;
        }
    }];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        [self fromData:[aDecoder decodeObjectForKey:@"jceData"]];
        
        // 处理子类 properties
        [[self.class propertyInfos] enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
            if (info.readonly && !info.ivar) {
                return;
            }
            
            if (!info.ivar && !info.dynamic) {
                return;
            }
            
            if (info.isJCE) return;
            
            NSString *key = info.name;
            
            id object = nil;
            @try {
                object = [aDecoder decodeObjectForKey:key];
            }
            @catch (NSException *exception) {
                object = nil;
            }
            
            if (!object) {
                return;
            }
            
            if (info.weak && info.dynamic) {
                // 对于动态的属性，`setValue:forKey:` 不会调用动态生成的 setter 方法，这样会导致属性为 weak 时没有赋值
                SEL setter = QZSelectorWithCapitalizedKeyPattern("set", key, ":");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:setter withObject:object];
#pragma clang diagnostic pop
            } else {
                [self setValue:object forKey:key];
            }
        }];
    }
    
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    id object = [self.class allocWithZone:zone];

    [[self.class propertyInfos] enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        if (info.readonly && !info.ivar) {
            return;
        }
        
        if (!info.ivar && !info.dynamic) {
            return;
        }

        NSString *key = info.name;
        id value = nil;
        
        @try {
            value = [self valueForKey:key];
        }
        @catch (NSException *exception) {
            value = nil;
        }
        
        if (!value) {
            return;
        }

        if ([value conformsToProtocol:@protocol(NSMutableCopying)]) {
            value = [value mutableCopy];
        } else if ([value conformsToProtocol:@protocol(NSCopying)]) {
            value = [value copy];
        }

        [object setValue:value forKey:key];
    }];
    
    return object;
}

//- (id)valueForUndefinedKey:(NSString *)key {
//    return nil;
//}
//
//- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
//    return;
//}

@end
