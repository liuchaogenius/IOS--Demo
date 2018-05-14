//
//  FSMsgService.m
//  FashionApp
//
//  Created by 1 on 2018/5/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSMsgService.h"
#import "ThreadSafeMutableDictionary.h"

ThreadSafeMutableDictionary *g_subcriptionDict;
ThreadSafeMutableDictionary *g_msgCallbackDict;

typedef void(^MsgPushBlock)(NSDictionary *msgDict);

@interface FSMsgService()

@property (nonatomic, strong) NSString *busiCmd;
@property (nonatomic, strong) NSDictionary *busiDict;
@end

@implementation FSMsgService

+ (void)startSubcriptionMsgSer
{
    [FSServiceRoute syncCallService:@"FSNetWorkService" func:@"subcriptionMsgObj:" withParam:@{@"reciveAppInnerPushMsg:":[FSMsgService class]}];
    if(!g_msgCallbackDict)
    {
        g_msgCallbackDict = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
    if(!g_subcriptionDict)
    {
        g_subcriptionDict = [[ThreadSafeMutableDictionary alloc] initWithCapacity:0];
    }
}

#pragma mark subcripition interface
+ (void)subcripitonBusiMsgForCmd:(NSDictionary *)subDict recvPushMsg:(void(^)(NSDictionary *busdiMsg))msgBlock
{
    NSArray *allKeys = [subDict allKeys];
    for(int i=0;i<allKeys.count;i++)
    {
        NSString *key = [allKeys objectAtIndex:i];
        NSHashTable *tempTable = [g_subcriptionDict objectForKey:key];
        if(!tempTable)
        {
            tempTable = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:1];
        }
        [tempTable addObject:[subDict objectForKey:key]];
        [g_subcriptionDict setValue:tempTable forKey:key];
        NSString *cbKey =  [NSString stringWithFormat:@"%@%@",NSStringFromClass([[subDict objectForKey:key] class]),key];
        [g_msgCallbackDict setValue:[msgBlock copy] forKey:cbKey];
    }
}

+ (void)reciveAppInnerPushMsg:(id)msgDict
{
    DebugLog(@"test");
    FSMsgService *msgs = [[FSMsgService alloc] init];
    [msgs handAppInnerPushMsg:msgDict];
}

#pragma mark handle push msg
- (void)handAppInnerPushMsg:(id)msgDict
{
    self.busiCmd = [msgDict objectForKey:@"cmd"];
    self.busiDict = [msgDict objectForKey:@"msgData"];
    DebugLog(@"msgCmd = %@,msgContent=%@",[msgDict objectForKey:@"cmd"],msgDict);
    NSHashTable *tempTable = [g_subcriptionDict objectForKey:self.busiCmd];
    NSArray *allobjects = [tempTable allObjects];
    if(self.busiCmd && allobjects.count>0)
    {
        for(int i=0;i<allobjects.count;i++)
        {
            NSString *cbKey =  [NSString stringWithFormat:@"%@%@",NSStringFromClass([[allobjects objectAtIndex:i] class]),self.busiCmd];
            MsgPushBlock callBlock = [g_msgCallbackDict objectForKey:cbKey];
            if(callBlock)
            {
                callBlock(self.busiDict);
            }
        }
    }
    [self removeInvalidCallback:allobjects cmd:self.busiCmd];
}

- (void)removeInvalidCallback:(NSArray *)allObject cmd:(NSString *)cmd
{
    if(allObject.count == 0)
    {
        [g_msgCallbackDict removeAllObjects];
    }
    else
    {
        NSArray *callKeys = [g_msgCallbackDict allKeys];
        [callKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *callkey = obj;
            __block BOOL isMatch = NO;
            [allObject enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *cbKey =  [NSString stringWithFormat:@"%@%@",NSStringFromClass([obj class]),cmd];
                if([callkey compare:cbKey] == 0)
                {
                    *stop = YES;
                    isMatch = YES;
                }
            }];
            if(!isMatch)
            {
                [g_msgCallbackDict removeObjectForKey:callkey];
            }
        }];
    }
}

@end
