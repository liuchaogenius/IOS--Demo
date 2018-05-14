//
//  FSDDLogger.m
//  FashionApp
//
//  Created by 1 on 2018/4/12.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSDDLogger.h"
#import "NSDateDeal.h"

@implementation FSDDLogger

+ (void)initDDLoggerSystem
{
//    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:ddLogLevel];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60*60*24;
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7; //做多保存7个文件
    fileLogger.maximumFileSize = 1024*50;//每个文件最大50k
    fileLogger.logFileManager.logFilesDiskQuota = 400*1024;//所有文件不超过400k；
    fileLogger.logFormatter = [[FSDDLogger alloc] init];
    [DDLog addLogger:fileLogger withLevel:ddLogLevel];

}

#warning  这里选择对写入文件的log采用加密
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage NS_SWIFT_NAME(format(message:))
{
    if(logMessage)
    {
        NSString *path = logMessage.file;//[NSString stringWithCString: encoding:NSASCIIStringEncoding];
        NSString *fileName = [path lastPathComponent];
    //    NSString *functionName = [NSString stringWithCString:logMessage.function encoding:NSASCIIStringEncoding];
    //    logMessage.timestamp;
        NSString *data = [NSDateDeal formateTimerInterval:[logMessage.timestamp timeIntervalSince1970] formate:@"yyyy-MM-dd HH:mm:ss.SSS"];
        return [NSString stringWithFormat:@"%@-%@-%@-%@-%@(%ld): %@",data,logMessage.threadName,logMessage.threadID, fileName, logMessage.function, (long)logMessage.line, logMessage.message];
    }
    return nil;
}

@end
