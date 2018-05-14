//
//  JCEPair.h
//  QQMSFContact
//
//  Created by Derek on 4/2/15.
//
//

#import <Foundation/Foundation.h>

@interface JCEPair : NSObject

@property (nonatomic, strong) id key;
@property (nonatomic, strong) id value;

+ (JCEPair *)pairFromExtString:(NSString *)string;
+ (JCEPair *)pairWithValue:(id)value forKey:(id)key;
+ (id)parseExtString:(NSString *)string;


@end