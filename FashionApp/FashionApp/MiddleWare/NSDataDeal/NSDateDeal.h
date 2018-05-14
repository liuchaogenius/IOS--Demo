//
//  NSDateDeal.h
//  moneyshield
//
//  Created by  striveliu on 15/6/24.
//  Copyright (c) 2015年 Alibaba.inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateDeal : NSObject
+ (int)dateInterval:(NSDate *)aStartDate endDate:(NSDate *)aEndDate;

+ (int)getDateInterval:(NSDate *)aStartDate endDate:(NSDate *)aEndDate;

+ (NSInteger)getCurrentYear;

+ (NSInteger)getCurrentMonth;

+ (NSInteger)getCurrentDay;

+ (NSInteger)getYear:(long long)aTimerInterval;

+ (NSInteger)getMonth:(long long)aTimerInterval;

+ (NSInteger)getDay:(long long)aTimerInterval;

//HH:mm yyyy-MM-dd
+ (NSString *)formateTimerInterval:(long long)aTimerInterval formate:(NSString *)aFormate;

+ (NSString*)showTime:(NSTimeInterval) msglastTime showDetail:(BOOL)showDetail;

+ (NSTimeInterval)getCurrentTimeInterval;
@end
