//
//  FSLocationService.h
//  FashionApp
//
//  Created by 1 on 2018/5/10.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSLocationService : NSObject

//调用该方法只返回经纬度信息   dict 里面有err字段，如果该值存在获取位置失败，如果不存在获取成功
+ (void)startLocationService:(void(^)(NSDictionary *dict))completeBlock;

//调用该方法获取到经纬度后，service会再去获取当前用户具体位置描述 有 国家、城市、区、街道等信息，获取位置描述设计网络请求(网络好则有，无网络情况下该字段会缺失)
//dict 里面有err字段，如果该值存在获取位置失败，如果不存在获取成功
+ (void)startLocationAndAddressService:(void(^)(NSDictionary *dict))completeBlock;
@end
