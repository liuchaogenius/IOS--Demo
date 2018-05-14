//
//  JceObjectV2.h
//
//  Created by 壬俊 易 on 12-3-13.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "JceObject.h"

/**
 * 辅助配置项，用于通过代码自动生成工具生成的代码
 * 如果此特性开启，则使用默认的getter和setter方法，假设Jce中定义的结构成员名为prop1，则可以通
 * 过self.prop1来访问getter和setter方法，如果此特性关闭，则需要使用self.jce_prop1来访问
 * getter和setter方法。
 */
#ifndef JCEV2_DEFAULT_GETTER_AND_SETTER
#define JCEV2_DEFAULT_GETTER_AND_SETTER                 0
#endif /*JCEV2_DEFAULT_GETTER_AND_SETTER*/

/**
 * 辅助配置项，用于通过代码自动生成工具生成的代码
 * 如果定义此宏，将使枚举类型对应的实现ETOS和STOE的支持类生效，默认是关闭的
 */
#ifndef JCEV2_ENUM_ETOS_AND_STOE_SUPPORTED
#define JCEV2_ENUM_ETOS_AND_STOE_SUPPORTED              0
#endif /*JCEV2_DEFAULT_GETTER_AND_SETTER*/

#ifndef JCE_USE_DYNAMIC_PROPERTY
#define JCE_USE_DYNAMIC_PROPERTY 1
#endif

#ifndef JCE_SKIP_PROPERTIES
#define JCE_SKIP_PROPERTIES 1
#endif

#ifndef JCE_USE_DYNAMIC_INITIALIZATION
#define JCE_USE_DYNAMIC_INITIALIZATION 1
#endif

#ifndef JCE_USE_DYNAMIC_JCE_TYPE
#define JCE_USE_DYNAMIC_JCE_TYPE 1
#endif

/**
 * JceObjectV2 充分利用Object-C的动态特定，提供更智能(自动化)的JCE打包解包方案
 * 
 * 如果一个类要支持Jce编解码，只需要继承JceObjectV2类，并且使用JV2_PROP_**宏来定义其属性，该
 * 属性的get方法和set方法分别为：jce_name, setJce_name:
 *
 * 对于NSArray和NSDictionary(即JCE中的Vector和Map)，需要用到附加信息ext编码。附加信息编码
 * 字符串的第一个字母为'V'或者‘M’或者'O'，分别代表Vector、Map和支持的对象类型。如果是Vector，
 * 后面字符串是该Vector容器中对象类型的附加信息编码；如果是MAP，后面字符串的前两个字符的数值等于
 * Key的类型信息编码字符串长度(00, 99]，然后再是Key的类型信息编码和Value的类型信息编码。
 *
 * Vector<string>                    ->> VONSString 
 * MAP<string, string>               ->> M09ONSStringONSString
 * MAP<string, Vector<string>>       ->> M09ONSStringVONSString
 * MAP<MttJceObject1, MttJceObject2> ->> M14OMttJceObject1OMttJceObject2
 * Vector<byte>                      ->> 映射到NSData类型，不需要附加信息编码
 * Vector<int>                       ->> 因NSArray中必须是对象，按NSArray<NSNumber>处理
 * Map<int, Vector<byte>>            ->> M09ONSNumberONSData
 *
 * 框架所支持的非容器对象类型包括：NSData，NSNumber，NSString，JceObject及其派生对象
 * 不支持包含下划线的属性名，不支持类名中包含下划线的JceObject派生类，不支持ext长度超过99
 *
 */
#define JCEV2_PROPERTY_NAME_PREFIX          jce_
#define JCEV2_PROPERTY_NAME_PREFIX_U        Jce_
#define JCEV2_PROPERTY_LVNAME_PREFIX        jcev2_p_
#define JCEV2_PROPERTY_LVNAME_PREFIX_STR    @"jcev2_p_"

#define JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER__(prefixL, prefixU, name) getter = prefixL##name, setter = set##prefixU##name:
#define JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER_(prefixL, prefixU, name) JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER__(prefixL, prefixU, name)
#define JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER(name) JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER_(JCEV2_PROPERTY_NAME_PREFIX, JCEV2_PROPERTY_NAME_PREFIX_U, name)
#define JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER_V2(gname, sname) getter = gname, setter = sname

#define JCEV2_PROPERTY_NAME_SP                                  @"__b0x9i_"
#define JCEV2_PROPERTY_NAME_NM__(prefix, flag, tag, name)       prefix##tag##_##flag##_##name
#define JCEV2_PROPERTY_NAME_EX__(prefix, flag, tag, name, ext)  prefix##tag##_##flag##_##name##__b0x9i_##ext
#define JCEV2_PROPERTY_NAME_NM_(prefix, flag, tag, name)        JCEV2_PROPERTY_NAME_NM__(prefix, flag, tag, name)
#define JCEV2_PROPERTY_NAME_EX_(prefix, flag, tag, name, ext)   JCEV2_PROPERTY_NAME_EX__(prefix, flag, tag, name, ext)
#define JCEV2_PROPERTY_NAME_NM(flag, tag, name)                 JCEV2_PROPERTY_NAME_NM_(JCEV2_PROPERTY_LVNAME_PREFIX, flag, tag, name)
#define JCEV2_PROPERTY_NAME_EX(flag, tag, name, ext)            JCEV2_PROPERTY_NAME_EX_(JCEV2_PROPERTY_LVNAME_PREFIX, flag, tag, name, ext)

#define JV2_PROP_GS(name)                   JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER(name)
#if JCEV2_DEFAULT_GETTER_AND_SETTER
    #define JV2_PROP_GS_V2(gname, sname)    JCEV2_PROPERTY_ATTR_GETTER_AND_SETTER_V2(gname, sname)
    #define JV2_PROP_(name)                 self.name
    #define JV2_PROP(name)                  JV2_PROP_(name)
    #define JCEV2_PROPERTY_NAME_PREFIX_STR  @""
#else /*JCEV2_DEFAULT_GETTER_AND_SETTER*/
    #define JV2_PROP_GS_V2(gname, sname)    JV2_PROP_GS(gname)
    #define JV2_PROP(name)                  self.jce_##name
    #define JCEV2_PROPERTY_NAME_PREFIX_STR  @"jce_"
#endif /*JCEV2_DEFAULT_GETTER_AND_SETTER*/

#define JV2_PROP_NM(flag, tag, name)        JCEV2_PROPERTY_NAME_NM(flag, tag, name)
#define JV2_PROP_EX(flag, tag, name, ext)   JCEV2_PROPERTY_NAME_EX(flag, tag, name, ext)
#define JV2_PROP_NFX_STR                    JCEV2_PROPERTY_NAME_PREFIX_STR
#define JV2_PROP_LFX_STR                    JCEV2_PROPERTY_LVNAME_PREFIX_STR

@interface JceObjectV2 : JceObject

@end
