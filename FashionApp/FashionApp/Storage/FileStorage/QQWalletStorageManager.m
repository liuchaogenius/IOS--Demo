//
//  QQWalletStorageManager.m
//  QQMSFContact
//
//  Created by Eric on 15/1/20.
//
//
#import "QQWalletStorageManager.h"
#import "NSString+MD5.h"
#import <UIKit/UIKit.h>

#define QQWalletCommonValueCacheFile @"WalletCommonValueCahceFile"

@interface QQWalletStorageManager ()
{
    NSRecursiveLock *_cacheLock; // 缓存递归锁
    NSMutableDictionary *_cacheDictionaryM; // 通用缓存的字典
    NSTimer *_timer; // 缓存定时器
    BOOL _isNeedUpdateCache; // 是否需要进行缓存更新
    NSUncaughtExceptionHandler *_previousUncaughtExceptionHandler; // 上一个异常处理（避免覆盖）
}

@end

static dispatch_once_t _once;
static QQWalletStorageManager *_defaultInstance;



@implementation QQWalletStorageManager

#pragma mark Lifecycle

+ (instancetype)sharedInstance {
    dispatch_once(&_once, ^{
        _defaultInstance = [QQWalletStorageManager new];
    });
    return _defaultInstance;
}

// 程序崩溃处理
static void uncaughtExceptionHandler(NSException *exception)
{
    // 崩溃前进行一次缓存保存(避免数据丢失)
    [[QQWalletStorageManager sharedInstance] saveCacheDataToFile];
    
//    QLog_Event(Module_VAC_Wallet, "【QQ钱包】QQWalletStorageManager uncaughtExceptionHandler ");

    // 调用前一个异常处理
    NSUncaughtExceptionHandler *previousUncaughtExceptionHandler = [QQWalletStorageManager sharedInstance]->_previousUncaughtExceptionHandler;
    if (previousUncaughtExceptionHandler != NULL) {
        previousUncaughtExceptionHandler(exception);
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    if (self = [super init]) {
        _cacheLock = [[NSRecursiveLock alloc] init];
        _isNeedUpdateCache = YES;
        _cacheDictionaryM = [NSMutableDictionary dictionaryWithContentsOfFile:[self commonValueCacheFilePath]] ?: [NSMutableDictionary dictionary];
        // 程序退出时做一次保存，避免数据丢失
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCacheDataToFile) name:UIApplicationWillTerminateNotification object:nil];
        //进后台也保存一次
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        
        // 程序Crash异常处理
        // 保存前一个异常处理<避免覆盖>
        _previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    }
    return self;
}

#pragma mark - Public
// 添加定时器
- (void)addTimer
{
    if (!_timer) {
        // 默认3秒进行缓存更新
        _timer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(saveCacheDataToFile) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
}
// 释放定时器
- (void)invalidateTimer
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
        // 释放前进行一次缓存保存(避免数据丢失)
        if (!_isNeedUpdateCache || [self saveCacheDataToFile]) {
            [_cacheLock lock];
            // 释放内存缓存
            [_cacheDictionaryM removeAllObjects];
            _cacheDictionaryM = nil;
            [_cacheLock unlock];
        }
    }
}

NSString * getDirPathByType(NSSearchPathDirectory type) {
#warning 需要获取用户uin
    NSString *uinStr = @"10000";//[CZ_GetAccountService() getUinStr];
    if (!uinStr) {
//        QLog_Event(Module_VAC_Wallet, "【QQ钱包】创建文件夹失败：uin为空");
        return nil;
    }
    NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(type, NSUserDomainMask, YES)[0]
                          stringByAppendingPathComponent:uinStr] stringByAppendingPathComponent:@"wallet"];
    // 创建目录
    NSError *error = nil;
    BOOL createDir = [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!createDir) {
//        QLog_Event(Module_VAC_Wallet, "【QQ钱包】创建文件夹失败：%s", [[error localizedDescription] UTF8String]);
        return nil;
    }
#if DEBUG
//    QLog_InfoP(Module_VAC_Wallet, "【QQ钱包】walletCacheDirectory = %s", [dirPath UTF8String]);
#endif
    
    return dirPath;
}
// 缓存文件路径 （Cache）
+ (NSString *)getQQWalletCacheDirectory{
    return getDirPathByType(NSCachesDirectory);
}
// 重要文件路径（Document）
+ (NSString *)getQQWalletDocumentDirectory{
    return getDirPathByType(NSDocumentDirectory);
}
#pragma mark - 统一的存取方法
//___________________________________________________________________________
// 将通用Cache写入文件
- (BOOL)saveCacheDataToFile
{
    static NSInteger timerInvocateCount = 0;
    static NSInteger saveCacheDateToFileCount = 0;
    __block BOOL saveCacheSuccess = NO;
    
    // 判断是否需要更新
    if (!_isNeedUpdateCache) { // 不需要更新
        if (_timer && timerInvocateCount * _timer.timeInterval > 60) { // 超时时间为60秒
            [self invalidateTimer];
            timerInvocateCount = 0;
        } else {
            timerInvocateCount++;
        }
        return saveCacheSuccess;
    }
    
    timerInvocateCount = 0;
    saveCacheDateToFileCount ++;
    
    NSString *filePath = [self commonValueCacheFilePath];
    
    [_cacheLock lock]; // 需要加锁，防止多线程写文件问题
    
    NSMutableDictionary *recDic = [_cacheDictionaryM mutableCopy];
    if (!recDic || ![recDic isKindOfClass:[NSMutableDictionary class]]) {
        recDic = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 10.0) {
            NSError *error = nil;
            NSData *data = nil;
            
            @try {
                data = [NSPropertyListSerialization dataWithPropertyList:recDic format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
            }
            @catch (NSException * e) {
                //QLog_Event(MODULE_IMPB_AR, "【QQ钱包】 通用Cache写入文件NSException: %s", [[e reason] UTF8String]);
            }

            if (!error && [data writeToFile:filePath atomically:YES]) {
                self->_isNeedUpdateCache = NO;
                saveCacheSuccess = YES;
                //QLog_InfoP(Module_VAC_Wallet, "【QQ钱包】 通用Cache写入文件成功：%s", [filePath UTF8String]);
            } else {
                self->_isNeedUpdateCache = YES;
                saveCacheSuccess = NO;
                //QLog_Event(Module_VAC_Wallet, "【QQ钱包】 通用Cache写入文件失败：%s", [[error localizedDescription] UTF8String]);
            }
        } else {
            if ([recDic writeToFile:filePath atomically:YES]) {
                self->_isNeedUpdateCache = NO;
                saveCacheSuccess = YES;
                //QLog_InfoP(Module_VAC_Wallet, "【QQ钱包】 通用Cache写入文件成功：%s", [filePath UTF8String]);
            } else {
                self->_isNeedUpdateCache = YES;
                saveCacheSuccess = NO;
                //QLog_Event(Module_VAC_Wallet, "【QQ钱包】 通用Cache写入文件失败：%s", [filePath UTF8String]);
            }
        }
    });
    
    [_cacheLock unlock];
    
    //QLog_Debug(Module_VAC_Wallet, "【QQ钱包】 通用Cache实际文件缓存次数 : %zd", saveCacheDateToFileCount);
    return saveCacheSuccess;
}
// 统一的存取方法(CacheDirectory)
- (void)cacheData:(id)value withKey:(NSString *)key;
{
    [_cacheLock lock];
    static int cacheDataInvocateCount = 0;
    if (key && value) {
        cacheDataInvocateCount++;
        _isNeedUpdateCache = YES; // 内容改变才需要更新缓存
        [self addTimer]; // 添加计时器<必须先添加计时器再赋值>
        if (!_cacheDictionaryM) {
            _cacheDictionaryM = [NSMutableDictionary dictionaryWithContentsOfFile:[self commonValueCacheFilePath]] ?: [[NSMutableDictionary alloc] initWithCapacity:1];
        }
        _cacheDictionaryM[key] = value;
    }
//    QLog_Debug(Module_VAC_Wallet, "【QQ钱包】 通用Cache请求缓存次数 : %zd", cacheDataInvocateCount);
    [_cacheLock unlock];
}

- (void)removeCacheDataForKey:(NSString *)key
{
    [_cacheLock lock];
    static int cacheDataInvocateCount = 0;
    if (key ) {
        cacheDataInvocateCount++;
        _isNeedUpdateCache = YES; // 内容改变才需要更新缓存
        [self addTimer]; // 添加计时器<必须先添加计时器再赋值>
        if (!_cacheDictionaryM) {
            _cacheDictionaryM = [NSMutableDictionary dictionaryWithContentsOfFile:[self commonValueCacheFilePath]] ?: [[NSMutableDictionary alloc] initWithCapacity:1];
        }
        [_cacheDictionaryM removeObjectForKey:key];;
    }
//    QLog_Debug(Module_VAC_Wallet, "【QQ钱包】remove 通用Cache请求缓存次数 : %zd", cacheDataInvocateCount);
    [_cacheLock unlock];
}

// 获取缓存路径
- (NSString *)commonValueCacheFilePath
{
    NSString *filePath = [[QQWalletStorageManager getQQWalletCacheDirectory] stringByAppendingPathComponent:[QQWalletCommonValueCacheFile MD5]];
    return filePath;
}
// 根据key获取缓存对象
- (id)getCacheDataForKey:(NSString *)key
{
    id value = nil;
    
    [_cacheLock lock];
    
    NSString *filePath = [self commonValueCacheFilePath];
    NSMutableDictionary *recDic = _cacheDictionaryM ?: [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    if (!recDic || ![recDic isKindOfClass:[NSMutableDictionary class]]) {
        recDic = [[NSMutableDictionary alloc] init];
    }
    if (recDic && key) {
        value = recDic[key];
    }
    [_cacheLock unlock];
    
    return value;
}

- (void)_clearMemoryCommonValueCache
{
    [_cacheLock lock];
    [_cacheDictionaryM removeAllObjects];
//    QLog_InfoP(Module_VAC_Wallet, "【QQ钱包】 通用Cache文件缓存清空内存缓存");
    [_cacheLock unlock];
}

#pragma mark - handler 

- (void)handleWillResignActiveNotification:(NSNotification *)no
{
    [self saveCacheDataToFile];
    [self invalidateTimer];
}

- (void)handleManualClearCacheEndNotification:(NSNotification *)no
{
    [self _clearMemoryCommonValueCache];
}

- (void)handleLogoutNotification:(NSNotification *)no
{
    [self invalidateTimer];
}

#pragma mark - 推荐服务的存取方法

- (BOOL)saveToCache:(NSData *)data fileName:(NSString *)cacheFileName
{
    NSError *error;
    BOOL success = [self saveToCache:data fileName:cacheFileName error:&error];
//    QLog_Event(Module_VAC_Wallet, "【QQ钱包】 通用Cache saveToCache %s 失败：%s",[cacheFileName UTF8String], [[error localizedDescription] UTF8String]);
    return success;
}
//___________________________________________________________________________
// 保持推荐服务到Document
- (BOOL)saveToCache:(NSData *)data fileName:(NSString *)cacheFileName error:(NSError **)error
{
    NSString *filePath = [[QQWalletStorageManager getQQWalletDocumentDirectory] stringByAppendingPathComponent:cacheFileName];
    if (data && filePath) {
        BOOL createFile = [[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil];
        if (!createFile) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.tencent.qqwallet" code:-1 userInfo:@{ @"Error message" : @"Create file failure" }];
            }
            //QLog_Event(Module_VAC_Wallet, "【钱包推荐服务】创建缓存文件失败");
            return NO;
        } else {
            //QLog_Event(Module_VAC_Wallet, "【QQ钱包】保存缓存文件成功: %s", [filePath UTF8String]);
            return YES;
        }
    }
    return NO;
}

- (void)deleteCacheFileName:(NSString *)cacheFileName
{
    NSError *error;
    [self deleteCacheFile:cacheFileName error: &error];
}
// 删除缓存文件
- (BOOL)deleteCacheFile:(NSString *)cacheFileName error:(NSError **)error
{
    NSString *filePath = [[QQWalletStorageManager getQQWalletDocumentDirectory] stringByAppendingPathComponent:cacheFileName];
    if ([[NSFileManager defaultManager] removeItemAtPath:filePath error:error]) {
        //QLog_Event(Module_VAC_Wallet, "【QQ钱包】删除缓存文件成功: %s",[filePath UTF8String]);
        return YES;
    } else {
        //QLog_Event(Module_VAC_Wallet, "【QQ钱包】删除缓存文件失败: %s",[filePath UTF8String]);
        return NO;
    }
}
// 取推荐服务缓存
- (NSData *)getCacheData:(NSString *)cacheFileName {
    NSString *filePath = [[QQWalletStorageManager getQQWalletDocumentDirectory] stringByAppendingPathComponent:cacheFileName];
    NSData *cacheData = [NSData dataWithContentsOfFile:filePath];
    //QLog_InfoP(Module_VAC_Wallet, "【QQ钱包】取推荐服务缓存 = %s",[filePath UTF8String]);
    return cacheData;
}
// 判断缓存文件是否存在
- (BOOL)isCacheFileExist:(NSString *)cacheFileName {
    NSString *filePath = [[QQWalletStorageManager getQQWalletDocumentDirectory] stringByAppendingPathComponent:cacheFileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

@end
