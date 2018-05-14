//
//  JCEObjectConverter.m
//  PayCenterSSO
//
//  Created by sfelixzhu(朱仕达) on 2017/4/17.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "JCEObjectConverter.h"
#import "JCEPropertyInfo.h"
#import "JCEPair.h"
#import "UniPacket.h"
NSArray* jcePropertiesForObject(JceObject *object){
    NSOrderedSet *orderedSet = [[object class] propertyInfos];
    NSIndexSet *indexSet = [orderedSet indexesOfObjectsPassingTest:^BOOL (JCEPropertyInfo *obj, NSUInteger idx, BOOL *stop) {
        return obj.isJCE;
    }];
    return [orderedSet objectsAtIndexes:indexSet];
}

id descriptionForProperty(JCEPropertyInfo *info){
    if (info.type.length < 4) return nil;
    Class cls = NSClassFromString([info.type substringWithRange:NSMakeRange(2, [info.type length] - 3)]);
#ifdef DEBUG
    assert(cls); // 防止运行时找不到对应的类
#endif
    return info.ext?:cls;
}

NSArray* jceArrayConverter(id originArray,Class jceClass,BOOL convertToJce){
    if (![originArray isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *aNewArray = [NSMutableArray array];
    Class checkObjectClass = convertToJce?[NSDictionary class]:[JceObject class];
    [originArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([jceClass isSubclassOfClass:[JceObject class]] && [obj isKindOfClass:checkObjectClass]) {
            id jceObject;
            if (convertToJce) {
                jceObject = convertDicToJceObject(obj, jceClass);
            }else{
                jceObject = convertJceObjectToDic(obj);
            }
            if (jceObject) {
                [aNewArray addObject:jceObject];
            }
        }else if ([obj isKindOfClass:jceClass]){
            [aNewArray addObject:obj];
        }
    }];
    return [[aNewArray copy] autorelease];
}

NSDictionary *jceDictionaryConverter(id originDic,JCEPair *jceClass,BOOL convertToJce){
    if (![originDic isKindOfClass:[NSDictionary class]]) return @{};
    NSMutableDictionary *aNewDictionary = [NSMutableDictionary dictionary];
    Class checkObjectClass = convertToJce?[NSDictionary class]:[JceObject class];
    [originDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isKindOfClass:jceClass.key]) {
            return ;
        }
        if ([jceClass.value isSubclassOfClass:[JceObject class]] && [obj isKindOfClass:checkObjectClass]) {
            id jceObject;
            if (convertToJce) {
                jceObject = convertDicToJceObject(obj, jceClass.value);
            }else{
                jceObject = convertJceObjectToDic(obj);
            }
            if (jceObject) {
                [aNewDictionary setValue:jceObject forKey:key];
            }
        }else if ([obj isKindOfClass:jceClass.value]){
            [aNewDictionary setValue:obj forKey:key];
        }
    }];
    return [[aNewDictionary copy] autorelease];
}

NSDictionary* convertJceObjectToDic(JceObject *object){
    if ([object isKindOfClass:[NSDictionary class]]) return (NSDictionary *)object;
    if (!object) return nil;
    NSArray *properties = jcePropertiesForObject(object);
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
    [properties enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        //jce的属性以 jce_ 开头，但不要求外面的字典的key包含 jce_ ,所以这里做个转换
        NSString *key = [NSStringFromSelector(info.getter) substringFromIndex:4];
        id value = [object valueForKey:info.name];
        if (!value) return;
        if ([info.type characterAtIndex:0] == '@') {
            id description = descriptionForProperty(info);
            if ([description isKindOfClass:[JCEPair class]]) {
                JCEPair *pair = (JCEPair *)description;
                if (pair.key == nil) {
                    value = jceArrayConverter(value, pair.value, NO);
                }else{
                    value = jceDictionaryConverter(value, pair, NO);
                }
            }else if ([description isSubclassOfClass:[JceObject class]]){
                value = convertJceObjectToDic(value);
            }
        }
        //由于字典中的基础数据类型已经是NSNumber，所以可以直接用setValue不需要特殊处理了
        [resultDic setValue:value forKey:key];
    }];
    return [[resultDic copy] autorelease];
}

JceObjectV2* convertDicToJceObject(NSDictionary *originDic,Class jceClass){
    if ([originDic isKindOfClass:jceClass]) return (JceObjectV2 *)originDic;
    if (![originDic isKindOfClass:[NSDictionary class]]) return nil;
    id jceObject = [jceClass new];
    NSArray *properties = jcePropertiesForObject(jceObject);
    [properties enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        NSString *key = [NSStringFromSelector(info.getter) substringFromIndex:4];
        id value = originDic[key];
        if (!value) return;
        switch ([info.type characterAtIndex:0]) {
            case 'B':   // bool
            case 'c':   // char
            case 'C':   // unsigned char
            case 's':   // short
            case 'S':   // unsigned short
            case 'i':   // int
            case 'I':   // unsigned int
            case 'l':   // long
            case 'L':   // unsigned long
            case 'q':   // long long
            case 'f':   // float
            case 'd': { // double
                if ([value isKindOfClass:[NSNumber class]]) {
                    [jceObject setValue:value forKey:info.name];
                }
            } break;
            case '@':{
                id description = descriptionForProperty(info);
                if ([description isKindOfClass:[JCEPair class]]) {
                    JCEPair *pair = (JCEPair *)description;
                    if (pair.key == nil) {
                        value = jceArrayConverter(value, pair.value, YES);
                    }else{
                        value = jceDictionaryConverter(value, pair, YES);
                    }
                    [jceObject performSelector:info.setter withObject:value];
                }else if ([description isSubclassOfClass:[JceObject class]]){
                    value = convertDicToJceObject(value, description);
                    [jceObject performSelector:info.setter withObject:value];
                }else if ([value isKindOfClass:description]){ //考虑到字典可能会有类型错误，要求类型匹配才能赋值
                    [jceObject performSelector:info.setter withObject:value];
                }
                break;
            }
            default:
                break;
        }
    }];
    return [jceObject autorelease];
}


NSData *creatCommonPacketWithServantName(NSString *servantName, NSString *funcName, NSString *attrName, JceObjectV2 *attrValue)
{
    UniPacket *packet = [UniPacket packet];
    packet.sServantName = servantName;
    packet.sFuncName = funcName;
    [packet putObjectAttr:attrName value:attrValue];
    return [packet toData];
}

NSDictionary* parseWUPData(NSData *data,NSString *attrName,NSString *jceClass)
{
    UniPacket *pacek = [UniPacket fromData:data];
    JceObjectV2 *jceObjc = [pacek getObjectAttr:attrName forClass:NSClassFromString(jceClass)];
    NSDictionary *dict = convertJceObjectToDic(jceObjc);
    return dict;
}
