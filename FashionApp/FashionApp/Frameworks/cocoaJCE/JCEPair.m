
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "JCEPair"
#pragma clang diagnostic pop

//
//  JCEPair.m
//  QQMSFContact
//
//  Created by Derek on 4/2/15.
//
//

#import "JCEPair.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


@implementation JCEPair

+ (JCEPair *)pairWithValue:(id)value forKey:(id)key
{
    JCEPair *pair = [JCEPair new];
    pair.value = value;
    pair.key = key;
    return pair;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@, %@>", NSStringFromClass([self.key class]), NSStringFromClass([self.value class])];
}

+ (id)parseExtString:(NSString *)str
{
    unichar flag = [str characterAtIndex:0];

    switch (flag) {
        case 'V': {
            id value = nil;
            value = [JCEPair parseExtString:[str substringFromIndex:1]];
            return [JCEPair pairWithValue:value forKey:nil];
        } break;

        case 'M': {
            id key = nil, value = nil;
            unichar l = 0;
            l = [str substringWithRange:NSMakeRange(1, 2)].intValue;
            key = [JCEPair parseExtString:[str substringWithRange:NSMakeRange(3, l)]];
            value = [JCEPair parseExtString:[str substringFromIndex:(3 + l)]];
            return [JCEPair pairWithValue:value forKey:key];
        } break;

        case 'O': {
            id class = NSClassFromString([str substringFromIndex:1]);
#ifdef DEBUG
            if (class == nil)
            {
                /*
                 挂在这里说明这个类文件可能没有添加，导致解包失败  add by pretionliu
                 */
                assert(class);
            }
#endif
            return NSClassFromString([str substringFromIndex:1]);
        } break;

        default: {
            NSAssert(0, nil);
            return nil;
        }
    }
}

+ (JCEPair *)pairFromExtString:(NSString *)str
{
    NSAssert([str length] < 128, nil);

    id pair = [self parseExtString:str];

    NSAssert([pair isKindOfClass:[JCEPair class]], nil);

    return pair;
}

@end
