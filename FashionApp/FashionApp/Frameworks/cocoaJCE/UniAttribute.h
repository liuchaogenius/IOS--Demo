//
//  UniAttribute.h
//  WirelessUnifiedProtocol
//
//  Created by renjunyi on 12-4-17.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "JceObjectV2.h"

@interface UniAttribute : JceObjectV2

@property (nonatomic, strong, JV2_PROP_GS(uniAttributes)) NSMutableDictionary* JV2_PROP_EX(r, 0, uniAttributes, M09ONSStringM09ONSStringONSData);

+ (UniAttribute *)fromAttributeData:(NSData *)data;

- (NSData *)attrValueWithName:(NSString *)name andType:(NSString *)type;
- (void)setAttrValue:(NSData *)data withName:(NSString *)name andType:(NSString *)type;

//add by raymonddeng ,引入UniPacket的时候需要用到以下方法
- (NSData *)attributeData;

@end

#pragma mark - categories

@interface JceObject (uniAttribute)

+ (JceObject *)objectWithName:(NSString *)name andType:(NSString *)type inAttributes:(UniAttribute *)attrs;
- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name andType:(NSString *)type;

@end

@interface JceObjectV2 (uniAttribute)

+ (JceObjectV2 *)objectWithName:(NSString *)name inAttributes:(UniAttribute *)attrs;
- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name;

@end

@interface NSData (uniAttribute)

+ (NSData *)dataWithName:(NSString *)name inAttributes:(UniAttribute *)attrs;
- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name;

@end

@interface NSString (uniAttribute)

+ (NSString *)stringWithName:(NSString *)name inAttributes:(UniAttribute *)attrs;
- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name;

@end

/**
 * 提供较初级的往UniAttribute中设置和获取NSArray对象的方法
 * 
 * 因为我们目前并不完全支持原生类型数组(主要是应用场景较少，byte[]对应到了NSData，char[]对应到
 * 了NSString)，所以不推荐定义使用原生类型数组的接口,要使用原生类型数组，比如int[]，要通过NSArray<NSNumber>来实现
 */
@interface NSArray (uniAttribute)

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name andType:(NSString *)type;

@end

@interface NSNumber (uniAttribute)

+ (int)intValueWithName:(NSString *)name inAttributes:(UniAttribute *)attrs;

+ (void)setLonglong:(long long)value InAttributes:(UniAttribute *)attrs withName:(NSString *)name;

+ (void)setInt32:(int32_t)value InAttributes:(UniAttribute *)attrs withName:(NSString *)name;

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name;

@end
