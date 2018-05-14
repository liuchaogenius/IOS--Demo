//
//  JCEBaseObject.h
//  QQMSFContact
//
//  Created by Derek on 4/1/15.
//
//

#import <Foundation/Foundation.h>

OBJC_EXTERN NSString *JCEDynamicSubclassPrefix;


@interface JCEBaseObject : NSObject

+ (NSOrderedSet *)propertyInfos;

+ (instancetype)fromJCEObject:(JCEBaseObject *)obj;

@end
