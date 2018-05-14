//
//  NSObject+FSObject.h
//  FashionApp
//
//  Created by 1 on 2018/4/26.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (FSObject)

- (BOOL)memoryStoreObject:(id)value key:(NSString *)key;

- (id)memoryForkey:(NSString *)key;

- (BOOL)memoryRemoveForkey:(NSString *)key;

@end
