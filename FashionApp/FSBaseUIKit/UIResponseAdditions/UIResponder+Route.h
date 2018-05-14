//
//  UIResponder+Route.h
//  FashionApp
//
//  Created by 1 on 2018/5/11.
//  Copyright © 2018年 1. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (Route)
- (void)routerEventWithName:(NSString *)eventName userInfo:(NSDictionary *)userInfo;
@end
