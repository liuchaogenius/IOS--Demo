//
//  FSDDLogger.h
//  FashionApp
//
//  Created by 1 on 2018/4/12.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

/*
如果你设置的日志级别为 LOG_LEVEL_ERROR那么你只会看到DDlogError语句的输出。
如果你将日志的级别设置为LOG_LEVEL_WARN那么你只会看到DDLogError和DDLogWarn语句。
如果您将日志级别设置为 LOG_LEVEL_INFO,您将看到error、Warn和信息报表。
如果您将日志级别设置为LOG_LEVEL_VERBOSE,您将看到所有DDLog语句。
如果您将日志级别设置为 LOG_LEVEL_OFF,你不会看到任何DDLog语句。
*/

#if DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif


@interface FSDDLogger : NSObject <DDLogFormatter>

+ (void)initDDLoggerSystem;

@end
