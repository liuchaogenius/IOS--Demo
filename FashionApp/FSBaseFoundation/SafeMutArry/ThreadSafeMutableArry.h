//
//  TBThreadSafeMutableArry.h
//  TBLocationFramework
//
//  Created by  striveliu on 7/4/14.
//  Copyright (c) 2014 taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread.h>
@interface ThreadSafeMutableArry : NSArray
{
    pthread_rwlock_t s_pthread_rwlock_t;
    NSMutableArray *_mutableArry;
}
@property (nonatomic, readonly)NSUInteger count;
- (void)addObject:(id)anObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeAllObjects;
- (void)removeLastObject;
- (id)objectAtIndex:(NSUInteger)index;
- (void)removeObject:(id)anObject;
@end
