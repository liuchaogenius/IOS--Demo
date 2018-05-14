//
//  QQWalletStorageManager.h
//  QQMSFContact
//
//  Created by Eric on 15/1/20.
//
//  钱包有些数据需要存到硬盘上，该类将这些存储、读取的功能封装到一起

#import <Foundation/Foundation.h>

@interface QQWalletStorageManager : NSObject

+ (instancetype)sharedInstance;

// 保持推荐服务到缓存
- (BOOL)saveToCache:(NSData *)data fileName:(NSString *)cacheFileName;
- (void)deleteCacheFileName:(NSString *)cacheFileName;
// 取推荐服务缓存
- (NSData *)getCacheData:(NSString *)cacheFileName;
// 判断缓存文件是否存在
- (BOOL)isCacheFileExist:(NSString *)cacheFileName;



// key-value存取的用这个
// 统一的存取方法
- (void)cacheData:(id) object withKey:(NSString *)key;
- (id)getCacheDataForKey:(NSString *)key;
- (void)removeCacheDataForKey:(NSString *)key;

// 缓存文件路径
+ (NSString *)getQQWalletCacheDirectory;
// 重要文件路径（Document）
+ (NSString *)getQQWalletDocumentDirectory;
- (NSString *)commonValueCacheFilePath;


@end

