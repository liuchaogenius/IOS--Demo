
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "JceObjectV2"
#pragma clang diagnostic pop

//
//  JceObjectV2.m
//
//  Created by 壬俊 易 on 12-3-13.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "JceObjectV2.h"
#import "JCEPair.h"
#import "JCEPropertyInfo.h"
#import "JceInputStreamV2.h"
#import "JceOutputStreamV2.h"


#pragma mark - JceObjectV2

@interface JceObjectV2 ()

- (JceObjectV2 *)jceRefObject;

@end

@implementation JceObjectV2


- (JceObjectV2 *)jceRefObject
{
#define KAssociatedObjectKeyJceRefObject @"AssociatedObjectKeyJceRefObject"
    // INFO:renjunyi 建议改用dispatch_once语法，而不用synchronized，只支持4.0以上的系统
    @synchronized (KAssociatedObjectKeyJceRefObject) {
        if (objc_getAssociatedObject([self class], KAssociatedObjectKeyJceRefObject) == nil) {
            JceObjectV2 *refObject = [[self class] new];
            objc_setAssociatedObject([self class], KAssociatedObjectKeyJceRefObject, refObject, OBJC_ASSOCIATION_RETAIN);
        }
    }
    return objc_getAssociatedObject([self class], KAssociatedObjectKeyJceRefObject);
}

- (void)__pack:(JceOutputStreamV2 *)stream
{
	@autoreleasepool {
        NSOrderedSet *infos = [self.class propertyInfos];

        ASSERT_TRHOW_WS_EXCEPTION(infos != nil);

        [infos enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
            if (!info.isJCE) { // 非 JCE 属性不处理
                return;
            }

            id value    = [self valueForKey:info.name];
            id refValue = [self jceRefObject];

            if (info.required == YES || (value != nil && [value isEqual:refValue] == NO)) {
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
                    case 'q': { // long long
                        [stream writeInt:[value longLongValue] tag:info.tag];
                    } break;

                    case 'f': { // float
                        [stream writeFloat:[value floatValue] tag:info.tag];
                    } break;

                    case 'd': { // double
                        [stream writeDouble:[value doubleValue] tag:info.tag];
                    } break;

                    case '@': { // objects
                        [stream writeAnything:value tag:info.tag required:info.required ext:info.ext];
                    } break;

                    default: {
                        ASSERT_TRHOW_WS_EXCEPTION(0);
                    } break;
                }
            }
        }];
    }
}

- (void)__unpack:(JceInputStreamV2 *)stream
{
	@autoreleasepool {
        NSOrderedSet *infos = [self.class propertyInfos];

        ASSERT_TRHOW_WS_EXCEPTION(infos != nil);

        [infos enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
            if (!info.isJCE) { // 非 JCE 属性不处理
                return;
            }
            
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
                    NSNumber *value = [stream readNumber:info.tag required:info.required];
                    if (value != nil) [self setValue:value forKey:info.name];
                } break;

                case '@': { // objects
                    Class cls = NSClassFromString([info.type substringWithRange:NSMakeRange(2, [info.type length] - 3)]);
#ifdef DEBUG
                    /*
                     * 如果你挂到这里说明 JCE 解包过程中运行时找不到对应的类，此时请用 lldb 查看 `po propInfo.type` 的值，
                     * 并检查对应类的 .m 文件是否加入到工程里面进行编译；
                     *
                     * 注意此处故意使用 `assert`，如果使用 `NSAssert` 之类的断言会抛出异常并且被上层代码捕获，很难察觉！
                     */
                    assert(cls); // 防止运行时找不到对应的类
#endif
                    id value = [stream readAnything:info.tag required:info.required description:(info.ext != nil ? info.ext : cls)];
                    if (value != nil) {
                        ASSERT_TRHOW_WS_EXCEPTION([[value class] isSubclassOfClass:cls]);
                        [self setValue:value forKey:info.name];
                    }
                } break;

                default: {
                    ASSERT_TRHOW_WS_EXCEPTION(0);
                } break;
            }
        }];
	}
}


@end
