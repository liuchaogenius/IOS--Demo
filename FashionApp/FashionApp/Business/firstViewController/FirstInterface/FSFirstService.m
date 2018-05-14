//
//  FSFirstInterface.m
//  FashionApp
//
//  Created by 1 on 2018/4/9.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSFirstService.h"
#import "FSFirstViewController.h"

@implementation FSFirstService


- (UIViewController *)getModuleViewController
{
    FSFirstViewController *vc = [[FSFirstViewController alloc] init];
    return vc;
}

- (void)dealloc
{
    DDLogDebug(@"已经释放FSFirstService");
}
@end
