
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "UniAttribute"
#pragma clang diagnostic pop

//
//  UniAttribute.m
//  WirelessUnifiedProtocol
//
//  Created by renjunyi on 12-4-17.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UniAttribute.h"
#import "JCEPair.h"
#import "JceInputStreamV2.h"
#import "JceOutputStreamV2.h"

@implementation UniAttribute

@synthesize JV2_PROP_EX(r, 0, uniAttributes, M09ONSStringM09ONSStringONSData); 

- (id)init
{
	if (self = [super init]) {
        self.jce_uniAttributes = [NSMutableDictionary dictionary];
	}
	return self;
}

+ (UniAttribute *)fromAttributeData:(NSData *)data
{
    UniAttribute *attribute = [UniAttribute new];
    JceInputStreamV2 *attrStream = [JceInputStreamV2 streamWithData:data];
    JCEPair *description = [JCEPair pairWithValue:[JCEPair pairWithValue:[NSData class] forKey:[NSString class]]
                                           forKey:[NSString class]];
    [attribute.jce_uniAttributes setDictionary:[attrStream readDictionary:0 required:YES description:description]];
    return attribute;
}

- (NSData *)attributeData
{
    JceOutputStreamV2 *stream = [JceOutputStreamV2 stream];
    [stream writeDictionary:self.JV2_PROP(uniAttributes) tag:0 required:YES ext:nil];
    return [stream data];
}

- (NSData *)attrValueWithName:(NSString *)name andType:(NSString *)type
{
    NSDictionary *attribute = (self.jce_uniAttributes)[name];
    if (attribute) {
        ASSERT_TRHOW_WS_EXCEPTION([attribute count] == 1);
        ASSERT_TRHOW_WS_EXCEPTION((type == nil || (attribute[type] == [[attribute allValues] lastObject])));
        return [[attribute allValues] lastObject];
    }
    return nil;
}

- (void)setAttrValue:(NSData *)value withName:(NSString *)name andType:(NSString *)type
{
    ASSERT_TRHOW_WS_EXCEPTION(name != nil && type != nil);
    NSDictionary *attribute = @{type: value};
    [self.jce_uniAttributes setValue:attribute forKey:name];
}

@end

#pragma mark - categories

@implementation JceObject (uniAttribute)

+ (JceObject *)objectWithName:(NSString *)name andType:(NSString *)type inAttributes:(UniAttribute *)attrs
{
    @try{
        NSData *data = [attrs attrValueWithName:name andType:type];
        JceInputStreamV2 *stream = [JceInputStreamV2 streamWithData:data];
        return [stream readObject:0 required:YES description:self];
    }
    @catch (NSException *exception) {
//        NSLog(@"objectWithName error, %@", exception);
        return nil;
    }
}

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name andType:(NSString *)type
{
    @try{
        JceOutputStreamV2 *stream = [JceOutputStreamV2 stream];
        [stream writeObject:self tag:0 required:YES];
        [attrs setAttrValue:[stream data] withName:name andType:type];
    }
    @catch (NSException *exception) {
//        NSLog(@"setInAttributes error, %@", exception);
    }

}

@end

@implementation JceObjectV2 (uniAttribute)

+ (JceObjectV2 *)objectWithName:(NSString *)name inAttributes:(UniAttribute *)attrs
{
    return (JceObjectV2 *)[self objectWithName:name andType:[self jceType] inAttributes:attrs];
}

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name
{
    [self setInAttributes:attrs withName:name andType:[self jceType]];
}

@end

@implementation NSData (uniAttribute)

+ (NSData *)dataWithName:(NSString *)name inAttributes:(UniAttribute *)attrs
{
    NSData *data = [attrs attrValueWithName:name andType:@"list<char>"];
    JceInputStreamV2 *stream = [JceInputStreamV2 streamWithData:data];
    return [stream readData:0 required:YES];
}

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name
{
    JceOutputStreamV2 *stream = [JceOutputStreamV2 streamWithCapability:(int)self.length];
    [stream writeData:self tag:0 required:YES];
    [attrs setAttrValue:[stream data] withName:name andType:@"list<char>"];
}

@end

@implementation NSString (uniAttribute)

+ (NSString *)stringWithName:(NSString *)name inAttributes:(UniAttribute *)attrs
{
    NSData *data = [attrs attrValueWithName:name andType:@"string"];
    JceInputStreamV2 *stream = [JceInputStreamV2 streamWithData:data];
    return [stream readString:0 required:YES];
}

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name
{
    JceOutputStreamV2 *stream = [JceOutputStreamV2 streamWithCapability:(int)[self lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    [stream writeString:self tag:0 required:YES];
    [attrs setAttrValue:[stream data] withName:name andType:@"string"];
}

@end

@implementation NSArray (uniAttribute)

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name andType:(NSString *)type
{
    JceOutputStreamV2 *stream = [JceOutputStreamV2 stream];
    [stream writeArray:self tag:0 required:YES ext:nil];
    [attrs setAttrValue:[stream data] withName:name andType:type];
}

@end

@implementation NSNumber (uniAttribute)

+ (int)intValueWithName:(NSString *)name inAttributes:(UniAttribute *)attrs
{
    NSData *data = [attrs attrValueWithName:name andType:@"int32"];
    if (data == nil) return 0; // ASSERT_TRHOW_WS_EXCEPTION(data != nil);
    JceInputStreamV2 *stream = [JceInputStreamV2 streamWithData:data];
    return (int)[stream readInt:0];
}

+ (void)setLonglong:(long long)value InAttributes:(UniAttribute *)attrs withName:(NSString *)name
{
    JceOutputStreamV2 *stream = [JceOutputStreamV2 streamWithCapability:16];
    [stream writeInt:value tag:0];
    [attrs setAttrValue:[stream data] withName:name andType:@"int64"];    
}

+ (void)setInt32:(int32_t)value InAttributes:(UniAttribute *)attrs withName:(NSString *)name
{
    JceOutputStreamV2 *stream = [JceOutputStreamV2 streamWithCapability:16];
    [stream writeInt:value tag:0];
    [attrs setAttrValue:[stream data] withName:name andType:@"int32"];
}

- (void)setInAttributes:(UniAttribute *)attrs withName:(NSString *)name
{
    JceOutputStreamV2 *stream = [JceOutputStreamV2 streamWithCapability:16];
    [stream writeNumber:self tag:0 required:YES];
    [attrs setAttrValue:[stream data] withName:name andType:@([self objCType])];
}

@end
