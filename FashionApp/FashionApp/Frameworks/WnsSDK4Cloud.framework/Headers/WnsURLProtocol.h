//
//  WnsURLProtocol.h
//  WnsSDK
//
//  Created by astorli on 5/27/15.
//
//

#import <Foundation/Foundation.h>
#import "WnsCommonDefine.h"

@class WnsSDK;
// 在请求的头部加入该标志,该请求即可使用WNS来发送
_WNS_CLS extern NSString * const ShouldUseWns;

// 当请求的方法是POST时, 如果使用NSURLSessionDataTask或者使用了改类的第三方库(比如AFNetworking)时,
// 自定义的NSURLProtocol获取到的NSURLRequest的HTTPBody为nil(系统bug, 对应的radar链接: rdar://15993891 )
// 所以, 在使用相关类发送前, 需要加上以下语句, 这样WnsURLProtocol才能获取到可用的HTTPBody
// if (request.HTTPBody)
// {
//     [NSURLProtocol setProperty:request.HTTPBody forKey:WnsHTTPBody inRequest:request];
// }
_WNS_CLS extern NSString * const WnsHTTPBody;

_WNS_CLS @interface WnsURLProtocol : NSURLProtocol

+ (void)bindSDKInstance:(WnsSDK *)instance;

@end
