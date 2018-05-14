//
//  UIResponder+Route.m
//  FashionApp
//
//  Created by 1 on 2018/5/11.
//  Copyright © 2018年 1. All rights reserved.
//

#import "UIResponder+Route.h"

@implementation UIResponder (Route)

- (void)routerEventWithName:(NSString *)eventName userInfo:(NSDictionary *)userInfo
{
    [[self nextResponder] routerEventWithName:eventName userInfo:userInfo];
}

@end
