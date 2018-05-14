//
//  FSRouteObject+FSMiddleWare.m
//  FashionApp
//
//  Created by 1 on 2018/4/13.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSRouteObject+FSMiddleWare.h"

@implementation FSRouteObject (FSMiddleWare)
- (void)initWNS
{
    NSDictionary *dict = @{kFSINITWNS:@"1"};
    [self performSynActionTargetName:@"FSMiddleWareInterface" param:dict];
}

- (void)initDDLogger
{
    NSDictionary *dict = @{kFSINITDDLOGGER:@"1"};
    [self performSynActionTargetName:@"FSMiddleWareInterface" param:dict];
}

@end
