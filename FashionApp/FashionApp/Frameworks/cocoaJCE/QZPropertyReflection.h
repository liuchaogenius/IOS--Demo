//
//  QZPropertyReflection.h
//
//  Created by Derek on 3/14/15.
//  Copyright (c) 2015 Derek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 *  Objective-C property 的内存管理规则
 */
typedef NS_ENUM(NSInteger, QZPropertyMemoryManagementPolicy) {
    QZPropertyMemoryManagementPolicyAssign = 0,
    QZPropertyMemoryManagementPolicyRetain,
    QZPropertyMemoryManagementPolicyCopy
};

/**
 * Objective-C property 的元信息
 */
typedef struct {
    /**
     *  是否声明为 readonly
     */
    BOOL readonly;
    
    /**
     *  是否声明为 nonatomic
     */
    BOOL nonatomic;
    
    /**
     *  是否声明为 weak
     */
    BOOL weak;
    
    /**
     * 是否声明为 @dynamic
     */
    BOOL dynamic;
    
    /**
     *  是否支持垃圾回收
     */
    BOOL canBeCollected;
    
    /**
     *  property 的内存管理规则，当声明为 readonly 时该值为 QZPropertyMemoryManagementPolicyAssign
     */
    QZPropertyMemoryManagementPolicy memoryManagementPolicy;
    
    /**
     *  getter 方法的名称
     */
    SEL getter;
    
    /**
     *  setter 方法的名字
     */
    SEL setter;
    
    /**
     *  property 对应的 ivar 名称，可能为 NULL
     */
    const char *ivar;
    
    /**
     *  property 所声明的类，如果 property 类型声明为 id 或运行时找不到该类则返回 nil
     */
    Class objectClass;
    
    /**
     *  property 对应的运行时 @encode 类型信息
     */
    char type[]; // 必须放在结构体的最后
    
} QZPropertyAttributes;


OBJC_EXTERN QZPropertyAttributes * QZCopyPropertyAttributes(objc_property_t property);

OBJC_EXTERN SEL QZSelectorWithCapitalizedKeyPattern(const char *prefix, NSString *key, const char *suffix);

