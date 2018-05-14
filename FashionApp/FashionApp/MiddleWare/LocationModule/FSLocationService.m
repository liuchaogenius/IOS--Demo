//
//  FSLocationService.m
//  FashionApp
//
//  Created by 1 on 2018/5/10.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSLocationService.h"
#import <CoreLocation/CoreLocation.h>

@interface FSLocationService()<CLLocationManagerDelegate>
{
    CLLocation *_newLocation;
}
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, copy) void(^locationBlock)(NSDictionary *dict, NSError *err);
@end

@implementation FSLocationService

+ (void)startLocationAndAddressService:(void(^)(NSDictionary *dict))completeBlock
{
    [FSLocationService startLocationIsAddress:YES complete:completeBlock];
}

+ (void)startLocationService:(void(^)(NSDictionary *dict))completeBlock
{
    [FSLocationService startLocationIsAddress:NO complete:completeBlock];
}

+ (void)startLocationIsAddress:(BOOL)isAddress complete:(void(^)(NSDictionary *dict))completeBlock
{
    FSLocationService *service = [[FSLocationService alloc] init];
    [service startLocation:^(NSDictionary *dict, NSError *err) {
        __block NSMutableDictionary *mutdict = [NSMutableDictionary dictionaryWithCapacity:0];
        if(service && dict)
        {
            [mutdict setValue:err forKey:@"err"];
            [mutdict addEntriesFromDictionary:dict];
            if(isAddress)
            {
                [service locationToPosition:^(NSDictionary *positionDict) {
                    [mutdict addEntriesFromDictionary:positionDict];
                    completeBlock(mutdict);
                }];
            }
            else
            {
                completeBlock(mutdict);
            }
        }
        else
        {
            [mutdict setValue:err forKey:@"err"];
            completeBlock(dict);
        }
        
    }];
}

- (instancetype)init
{
    if(self = [super init])
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
    }
    return self;
}

- (void)startLocation:(void(^)(NSDictionary *dict, NSError *err))block
{
    self.locationBlock = block;
    [self.locationManager requestAlwaysAuthorization];
    if ([CLLocationManager locationServicesEnabled]) {
        // 启动位置更新
        // 开启位置更新需要与服务器进行轮询所以会比较耗电，在不需要时用stopUpdatingLocation方法关闭;
        if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }
        else if([self.locationManager   respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        [self.locationManager startUpdatingLocation];
        DDLogDebug(@"开启成功");
        WeakSelf(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(weakself.locationBlock)
            {
                [weakself.locationManager stopUpdatingHeading];
                weakself.locationBlock(nil,kNSError(-1, @"定位超时"));
            }
            weakself.locationBlock = nil;
        });
    }
    else
    {
        DDLogDebug(@"请开启定位功能！");
        if(self.locationBlock)
        {
            self.locationBlock(nil,kNSError(-1, @"请到“设置->隐私->定位”开启定位功能"));
        }
    }
}

#pragma mark location delegate
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    // 1.获取用户位置的对象
    _newLocation = [locations lastObject];
    DDLogDebug(@"经纬度%.2f,%.2f",_newLocation.coordinate.latitude,_newLocation.coordinate.longitude);
    [manager stopUpdatingLocation];
    if(self.locationBlock)
    {
        self.locationBlock(@{@"lat":[NSNumber numberWithDouble:_newLocation.coordinate.latitude],@"log":[NSNumber numberWithDouble:_newLocation.coordinate.longitude]},nil);
    }
    self.locationBlock = nil;
}

// 定位失误时触发
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DDLogDebug(@"error:%@",error);
    if(self.locationBlock)
    {
        self.locationBlock(nil,kNSError(-1, @"当前环境影响定位"));
    }
    self.locationBlock = nil;
}
#pragma mark tool
- (void)locationToPosition:(void(^)(NSDictionary *positionDict))positionBlock
{
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:_newLocation completionHandler:^(NSArray *placemarks, NSError *error){
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        DDLogDebug(@"%@", placemark.name);// 详细位置
        DDLogDebug(@"%@", placemark.country);// 国家
        DDLogDebug(@"%@", placemark.locality);// 市
        DDLogDebug(@"%@", placemark.subLocality);// 区
        DDLogDebug(@"%@", placemark.thoroughfare);// 街道
        DDLogDebug(@"%@", placemark.subThoroughfare);// 子街道
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
        [dict setValue:placemark.country forKey:@"country"];
        [dict setValue:placemark.locality forKey:@"locality"];
        [dict setValue:placemark.subLocality forKey:@"subLocality"];
        [dict setValue:placemark.thoroughfare forKey:@"thoroughfare"];
        [dict setValue:placemark.subThoroughfare forKey:@"subThoroughfare"];
        [dict setValue:[NSString stringWithFormat:@"%@%@%@%@",placemark.locality?:@"",placemark.subLocality?:@"",placemark.thoroughfare?:@"",placemark.subThoroughfare?:@""] forKey:@"addressName"];
        positionBlock([dict copy]);
    }];
}

- (void)dealloc
{
    DebugLog(@"location_release");
}

@end
