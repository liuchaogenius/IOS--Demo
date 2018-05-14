//
//  TBSDKThreadSafeMutableDictionary.h
//  TBSDKNetworkSDK
//
//  Created by striveliu on 6/30/14.
//  Copyright (c) 2014 Alibaba-Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThreadSafeMutableDictionary : NSMutableDictionary
- (id)initWithCapacity:(NSUInteger)capacity;

@end
