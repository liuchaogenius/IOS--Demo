//
//  NSObject+FSObject.m
//  FashionApp
//
//  Created by 1 on 2018/4/26.
//  Copyright © 2018年 1. All rights reserved.
//

#import "NSObject+FSObject.h"

@implementation NSObject (FSObject)

- (BOOL)memoryStoreObject:(id)value key:(NSString *)key
{
    if(value)
    {
        SEL selKey = NSSelectorFromString(key);
        objc_setAssociatedObject([FSServiceRoute shareInstance], selKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    return NO;
}

- (id)memoryForkey:(NSString *)key
{
    if(key)
    {
        SEL selKey = NSSelectorFromString(key);
        return objc_getAssociatedObject([FSServiceRoute shareInstance], selKey);
    }
    return nil;
}

- (BOOL)memoryRemoveForkey:(NSString *)key
{
    if(key)
    {
        SEL selKey = NSSelectorFromString(key);
        objc_setAssociatedObject([FSServiceRoute shareInstance], selKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    return NO;
}

@end
