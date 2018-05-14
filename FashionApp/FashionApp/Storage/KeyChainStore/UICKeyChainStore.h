//
//  UICKeyChainStore.h
//  UICKeyChainStore
//
//  Created by Kishikawa Katsumi on 11/11/20.
//  Copyright (c) 2011 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UICKeyChainStore : NSObject

+ (NSString *)stringForKey:(NSString *)key;
+ (BOOL)setString:(NSString *)value forKey:(NSString *)key;

+ (NSData *)dataForKey:(NSString *)key;
+ (BOOL)setData:(NSData *)data forKey:(NSString *)key;

+ (void)removeItemForKey:(NSString *)key;
@end
