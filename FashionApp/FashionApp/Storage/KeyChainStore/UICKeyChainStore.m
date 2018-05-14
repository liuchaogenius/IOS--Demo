//
//  UICKeyChainStore.m
//  UICKeyChainStore
//
//  Created by Kishikawa Katsumi on 11/11/20.
//  Copyright (c) 2011 Kishikawa Katsumi. All rights reserved.
//

#import "UICKeyChainStore.h"
//#import "DesUtil.h"
//#import "RunTimeConfig.h"
#define DEFAULT_SERVICE   [NSString stringWithFormat:@"%@.fashionStyle",[[NSBundle mainBundle] bundleIdentifier]]
#define ENCRPT_KEY        [NSString stringWithFormat:@"qYMF@%@D!Z",@"werwjv60dh"]
@implementation UICKeyChainStore

+ (BOOL)setString:(NSString *)value forKey:(NSString *)key {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    return [self setData:data forKey:key service:DEFAULT_SERVICE accessGroup:nil];
}

+ (NSString *)stringForKey:(NSString *)key {
    NSData *data = [self dataForKey:key service:DEFAULT_SERVICE  accessGroup:nil];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

+ (BOOL)setData:(NSData *)data forKey:(NSString *)key {
     return [self setData:data forKey:key service:DEFAULT_SERVICE accessGroup:nil];
}
+ (NSData *)dataForKey:(NSString *)key{
     return  [self dataForKey:key service:DEFAULT_SERVICE  accessGroup:nil];
}

+ (NSData *)dataForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        NSAssert(key, @"key not nil");
		return nil;
	}
	if (!service) {
        service = DEFAULT_SERVICE ;
	}
    
	NSMutableDictionary* query = [NSMutableDictionary dictionary];
	[query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	[query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	[query setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[query setObject:service forKey:(id)kSecAttrService];
    [query setObject:key forKey:(id)kSecAttrGeneric];
    [query setObject:key forKey:(id)kSecAttrAccount];
#if !TARGET_IPHONE_SIMULATOR
    if (accessGroup) {
        [query setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
    }
#endif
    
	CFTypeRef dataRef = NULL;
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &dataRef);
	if (status != errSecSuccess) {
        DDLogInfo(@"SecItemCopyMatching status=%d", (int)status);
        return nil;
	}
    NSData *data = (__bridge_transfer NSData*)dataRef;
    if(data.length <= 0)
    {
        DDLogInfo(@"data length is 0");
    }
//    NSData* encrptData = data;
    NSString * encrptString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSString * decryptValue = [DesUtil decryptString:encrptString withRawKey:ENCRPT_KEY];
    NSData *decryptData = [encrptString dataUsingEncoding:NSUTF8StringEncoding];
    return decryptData;
    
}


+ (BOOL)setData:(NSData *)data forKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        DDLogInfo(@"key must not be nil");
		return NO;
	}
	if (!service) {
        service = DEFAULT_SERVICE ;
	}
    
    NSString * value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSString * encrptString = [DesUtil encryptString:value withRawKey:ENCRPT_KEY];
    NSData *encrptData = [value dataUsingEncoding:NSUTF8StringEncoding];
    if(encrptData.length <= 0)
    {
        DDLogInfo(@"encrptData length is 0");
    }
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	[query setObject:service forKey:(id)kSecAttrService];
    [query setObject:key forKey:(id)kSecAttrGeneric];
    [query setObject:key forKey:(id)kSecAttrAccount];
#if !TARGET_IPHONE_SIMULATOR
    if (accessGroup) {
        [query setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
    }
#endif
    
    OSStatus status = errSecSuccess;
	status = SecItemCopyMatching((CFDictionaryRef)query, NULL);
	if (status == errSecSuccess) {
        if (encrptData) {
            NSMutableDictionary *attributesToUpdate = [NSMutableDictionary dictionary];
            [attributesToUpdate setObject:encrptData forKey:(id)kSecValueData];
            
            status = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)attributesToUpdate);
            if (status != errSecSuccess) {
                DDLogInfo(@"SecItemUpdate status=%d", status);
                return NO;
            }
        } else {
            [self removeItemForKey:key service:service accessGroup:accessGroup];
            return YES;
        }
	} else if (status == errSecItemNotFound) {
		NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
		[attributes setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
        [attributes setObject:service forKey:(id)kSecAttrService];
        [attributes setObject:key forKey:(id)kSecAttrGeneric];
        [attributes setObject:key forKey:(id)kSecAttrAccount];
        if (encrptData)
        {
            [attributes setObject:encrptData forKey:(id)kSecValueData];
        }
#if !TARGET_IPHONE_SIMULATOR
        if (accessGroup) {
            [attributes setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
        }
#endif
		
		status = SecItemAdd((CFDictionaryRef)attributes, NULL);
		if (status != errSecSuccess) {
			DDLogInfo(@"SecItemAdd status=%d", status);
            return NO;
		}		
	} else {
		DDLogInfo(@"SecItemCopyMatching status=%d", status);
        return NO;
	}
    return YES;
}

+ (void)removeItemForKey:(NSString *)key
{
    [UICKeyChainStore removeItemForKey:key service:DEFAULT_SERVICE accessGroup:nil];
}


+ (void)removeItemForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    if (!key) {
        NSAssert(NO, @"key must not be nil.");
        return;
    }
    if (!service) {
        service = DEFAULT_SERVICE;
    }
    
    NSMutableDictionary *itemToDelete = [NSMutableDictionary dictionary];
    [itemToDelete setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [itemToDelete setObject:service forKey:(id)kSecAttrService];
    [itemToDelete setObject:key forKey:(id)kSecAttrGeneric];
    [itemToDelete setObject:key forKey:(id)kSecAttrAccount];
#if !TARGET_IPHONE_SIMULATOR
    if (accessGroup) {
        [itemToDelete setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
    }
#endif
    
    OSStatus status = SecItemDelete((CFDictionaryRef)itemToDelete);
    if (status != errSecSuccess && status != errSecItemNotFound) {
        DebugLog(@"%s|SecItemDelete: error(%ld)", __func__, (long)status);
    }
}


@end
